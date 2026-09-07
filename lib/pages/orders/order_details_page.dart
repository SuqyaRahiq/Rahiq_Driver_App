import 'dart:async';
import 'package:material_symbols_icons/symbols.dart';
import 'package:rahiq_driver/data/models/driver/driver_profile.dart';
import 'package:rahiq_driver/data/models/driver/product.dart';
import 'package:flutter/material.dart';
import 'package:rahiq_driver/data/api/api_client.dart';
import 'package:rahiq_driver/data/api/driver/driver_orders_api.dart';
import 'package:rahiq_driver/data/storage/auth_storage.dart';
import 'package:rahiq_driver/common_widgets/custom_snackbar.dart';
import 'package:rahiq_driver/utils/media_compressor.dart';
import 'package:rahiq_driver/pages/shared/proof_submission_page.dart';
import 'package:rahiq_driver/common_widgets/chiller_refill_badge.dart';
import 'package:rahiq_driver/utils/colors.dart';
import 'package:rahiq_driver/utils/cs_notes.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:dio/dio.dart';
import 'package:rahiq_driver/l10n/app_localizations.dart';
import 'package:rahiq_driver/utils/shimmer_loading.dart';
import 'package:shimmer/shimmer.dart';
import 'package:rahiq_driver/utils/water_loading.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rahiq_driver/pages/shared/custom_camera_screen.dart';
import 'package:rahiq_driver/pages/shared/image_preview_page.dart';

class OrderDetailsPage extends StatefulWidget {
  final String orderId;
  final String name;
  final String nameAr;
  final String? orderType;
  final bool isAutoOrder;
  final double? latitude;
  final double? longitude;

  const OrderDetailsPage({
    super.key,
    required this.orderId,
    required this.name,
    required this.nameAr,
    this.orderType,
    this.isAutoOrder = true,
    this.latitude,
    this.longitude,
  });

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  late DriverOrdersApi _api;
  bool _isLoading = true;
  String? _error;
  List<dynamic> _subOrders = [];
  bool _allOrdersCompleted = false;
  bool _isMultiSelectMode = false;
  final Set<String> _selectedSubOrders = {};
  DriverProfile? driver;

  int _currentPage = 1;
  bool _hasMore = true;
  bool _isFetchingMore = false;

  String? _dateSortDirection; // 'asc' or 'desc'
  String? _quantitySortDirection; // 'asc' or 'desc'
  bool _showOnlyWithNotes = false;
  bool _isDateMenuOpen = false;
  bool _isQuantityMenuOpen = false;

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';

  String? _batchMosqueFrontImage;
  String? _batchMosqueInsideImage;
  bool _isCompressingBatchFrontImage = false;
  bool _isCompressingBatchInsideImage = false;

  final ImagePicker _picker = ImagePicker();

  Future<String?> _pickImageWithConstraints(
    BuildContext context,
    ImageSource source, {
    String? customerName,
    String? quantity,
    String? date,
  }) async {
    String? filePath;
    if (source == ImageSource.camera) {
      filePath = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CustomCameraScreen(
            isVideoMode: false,
            customerName: customerName,
            quantity: quantity,
            date: date,
            customerNote: null,
            customerServiceNotes: [],
          ),
        ),
      );
    } else {
      final file = await _picker.pickImage(source: source);
      filePath = file?.path;
    }

    if (filePath != null) {
      filePath = await MediaCompressor.compressImage(filePath);

      try {
        final file = File(filePath ?? "");
        final sizeInBytes = await file.length();
        final sizeInMB = sizeInBytes / (1024 * 1024);
        if (sizeInMB > 2) {
          if (context.mounted) {
            CustomSnackbar.show(
              context: context,
              message: AppLocalizations.of(context)!.imageSizeLimitError,
              isError: true,
            );
          }
          return null;
        }
      } catch (e) {
        debugPrint('Error checking file size: $e');
      }
    }
    return filePath;
  }

  bool _isBatchUploading = false;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _api = DriverOrdersApi(ApiClient());
    _fetchDetails();
    driver = AuthStorage.getUserData();
  }

  /// True once every sub-order the driver can see has been delivered, i.e.
  /// there is nothing left to deliver in this order. Only trustworthy when the
  /// whole list has been loaded, otherwise a page of delivered sub-orders would
  /// hide the pending ones still waiting on the next page.
  bool get _nothingLeftToDeliver =>
      _subOrders.isNotEmpty &&
      !_hasMore &&
      _subOrders.every(
        (s) => s['status'] == 'DELIVERED' || s['status'] == 'COMPLETED',
      );

  Future<void> _fetchDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
        _currentPage = 1;
        _hasMore = true;
        _isFetchingMore = false;
      });
      String? sortBy;
      String? sortOrder;

      if (_dateSortDirection != null) {
        sortBy = 'assignedAt';
        sortOrder = _dateSortDirection;
      } else if (_quantitySortDirection != null) {
        sortBy = 'quantity';
        sortOrder = _quantitySortDirection;
      }

      final details = widget.isAutoOrder
          ? await _api.getAutoOrderDetails(
              widget.orderId,
              widget.orderType ?? '',
              sortBy: sortBy,
              sortOrder: sortOrder,
              hasNote: _showOnlyWithNotes,
              search: _searchQuery,
              page: 1,
              limit: 30,
            )
          : await _api.getNormalOrderSubOrders(
              widget.orderId,
              sortBy: sortBy,
              sortOrder: sortOrder,
              hasNote: _showOnlyWithNotes,
              search: _searchQuery,
              page: 1,
              limit: 30,
            );

      if (mounted) {
        setState(() {
          _subOrders = details.map((s) => s.toJson()).toList();
          _hasMore = details.length == 30;
          _isLoading = false;
          _allOrdersCompleted = _nothingLeftToDeliver;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchMoreDetails() async {
    if (_isFetchingMore || !_hasMore) return;

    setState(() {
      _isFetchingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      String? sortBy;
      String? sortOrder;

      if (_dateSortDirection != null) {
        sortBy = 'assignedAt';
        sortOrder = _dateSortDirection;
      } else if (_quantitySortDirection != null) {
        sortBy = 'quantity';
        sortOrder = _quantitySortDirection;
      }

      final newDetails = widget.isAutoOrder
          ? await _api.getAutoOrderDetails(
              widget.orderId,
              widget.orderType ?? '',
              sortBy: sortBy,
              sortOrder: sortOrder,
              hasNote: _showOnlyWithNotes,
              search: _searchQuery,
              page: nextPage,
              limit: 30,
            )
          : await _api.getNormalOrderSubOrders(
              widget.orderId,
              sortBy: sortBy,
              sortOrder: sortOrder,
              hasNote: _showOnlyWithNotes,
              search: _searchQuery,
              page: nextPage,
              limit: 30,
            );

      if (mounted) {
        setState(() {
          _currentPage = nextPage;
          _subOrders.addAll(newDetails.map((s) => s.toJson()).toList());
          if (newDetails.isEmpty || newDetails.length < 30) {
            _hasMore = false;
          }
          _isFetchingMore = false;
          _allOrdersCompleted = _nothingLeftToDeliver;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFetchingMore = false;
        });
      }
    }
  }

  Future<void> _navigateToSingleProofSubmission(String subId) async {
    try {
      setState(() => _isLoading = true);
      final detailedSubOrder = await _api.getSubOrderDetails(subId);
      if (!mounted) return;
      setState(() => _isLoading = false);

      final customer =
          detailedSubOrder['customerDetails'] ?? <String, dynamic>{};
      final address =
          detailedSubOrder['deliveryAddress'] ?? customer['address'];

      final submitted = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProofSubmissionPage(
            isAutoOrder: widget.isAutoOrder,
            orderId: widget.orderId,
            orderType: widget.orderType,
            product: Product(
              id: (detailedSubOrder['product'] ?? {})['id']?.toString() ?? '',
              name:
                  (detailedSubOrder['product'] ?? {})['name']?.toString() ?? '',
              nameAr:
                  (detailedSubOrder['product'] ?? {})['nameAr']?.toString() ??
                  '',
              image:
                  (detailedSubOrder['product'] ?? {})['image']?.toString() ??
                  '',
              serialNumber:
                  (detailedSubOrder['product'] ?? {})['serialNumber'] as int?,
            ),
            subOrders: [subId],
            singleCustomerData: {
              'firstName': customer['firstName'],
              'lastName': customer['lastName'],
              'phoneNumber': customer['phoneNumber'],
              'address': address,
              'subOrderNumber':
                  detailedSubOrder['subOrderNumber']?.toString() ??
                  (subId.length > 8 ? subId.substring(0, 8) : subId),
              'quantity': detailedSubOrder['quantity'],
              'countryCode':
                  detailedSubOrder['customerDetails']?['countryCode'] ??
                  customer['countryCode'] ??
                  '',
              'deliveryNotes': detailedSubOrder['deliveryNotes'],
              'csNotes': detailedSubOrder['csNotes'],
              'giftCard': detailedSubOrder['giftCard'],
              'isChillerRefill': detailedSubOrder['isChillerRefill'] == true,
            },
            initialMosqueFrontImage: detailedSubOrder['mosqueFrontImage'],
            initialMosqueInsideImage: detailedSubOrder['mosqueInsideImage'],
            latitude: widget.latitude,
            longitude: widget.longitude,
          ),
        ),
      );

      if (submitted == true && mounted) {
        setState(() {
          _isMultiSelectMode = false;
          _selectedSubOrders.clear();
        });
        _fetchDetails();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        CustomSnackbar.show(
          context: context,
          message: e.toString(),
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.buttonBlueDark,
      floatingActionButtonAnimator: FloatingActionButtonAnimator.noAnimation,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton:
          (_isMultiSelectMode && _selectedSubOrders.isNotEmpty)
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(30),
                color: AppColors.buttonBlueDark,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.buttonBlueDark,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,

                    children: [
                      Text(
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        '${_selectedSubOrders.length} ${AppLocalizations.of(context)!.ordersSelected} ',
                      ),
                      GestureDetector(
                        onTap: () {
                          if (_selectedSubOrders.length == 1) {
                            final subId = _selectedSubOrders.first;
                            _navigateToSingleProofSubmission(subId);
                          } else {
                            _showBatchImagesBottomSheet(context);
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            _selectedSubOrders.length == 1
                                ? AppLocalizations.of(context)!.completeOrder
                                : AppLocalizations.of(context)!.continue_text,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.buttonBlueDark,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (!_isLoading &&
              !_isFetchingMore &&
              _hasMore &&
              scrollInfo.metrics.pixels >=
                  scrollInfo.metrics.maxScrollExtent - 200) {
            _fetchMoreDetails();
          }
          return false;
        },
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  // ── Header ────────────────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    color: AppColors.buttonBlueDark,
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      16,
                      60,
                      16,
                      20,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 0),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            (Localizations.localeOf(context).languageCode ==
                                        'ar' &&
                                    widget.nameAr.isNotEmpty)
                                ? widget.nameAr
                                : widget.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 38),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 28, 0, 100),
                        child: Column(
                          children: [
                            if (_error != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _error!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),

                            (!_isLoading &&
                                    (_subOrders.isEmpty || _allOrdersCompleted))
                                ? Expanded(child: _buildSubOrdersSection())
                                : _buildSubOrdersSection(),

                            if (_isLoading ||
                                (_subOrders.isNotEmpty && !_allOrdersCompleted))
                              const Spacer(),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubOrdersSection() {
    final sortedSubOrders = _subOrders;
    final visibleUncompleted = sortedSubOrders
        .where(
          (s) =>
              s['status'] != 'DELIVERED' &&
              s['status'] != 'COMPLETED' &&
              s['status'] != 'CONFIRMED',
        )
        .toList();

    final bool isAllSelected =
        visibleUncompleted.isNotEmpty &&
        visibleUncompleted.every(
          (s) => _selectedSubOrders.contains(s['id'].toString()),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
          child: Text(
            AppLocalizations.of(context)!.orders,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
          child: Material(
            color: Colors.white,
            elevation: 1,
            borderRadius: BorderRadius.circular(12),
            child: TextField(
              cursorColor: AppColors.buttonBlueDark,
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchByOrderNumber,
                prefixIcon: Icon(Icons.search, color: AppColors.buttonBlueDark),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.buttonBlueDark),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.buttonBlueDark),
                ),

                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.buttonBlueDark),
                ),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.buttonBlueDark),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(const Duration(milliseconds: 500), () {
                  setState(() {
                    _searchQuery = value.trim();
                  });
                  _fetchDetails();
                });
              },
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsetsDirectional.only(start: 16),
                child: FilterChip(
                  showCheckmark: false,
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: isAllSelected
                        ? AppColors.buttonBlueDark.withValues(alpha: 0.7)
                        : Colors.grey.shade300,
                    width: 1,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  labelStyle: const TextStyle(color: Colors.black87),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 18,
                        height: 18,

                        decoration: BoxDecoration(
                          color: isAllSelected
                              ? AppColors.buttonBlueDark
                              : Colors.white,
                          border: Border.all(
                            color: isAllSelected
                                ? AppColors.buttonBlueDark
                                : Colors.black87,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: isAllSelected
                            ? const Center(
                                child: Icon(
                                  Icons.check,
                                  size: 14,
                                  color: AppColors.white,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.select_all,
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  selected: isAllSelected,
                  onSelected: (val) {
                    setState(() {
                      if (val == true) {
                        _isMultiSelectMode = true;
                        _selectedSubOrders.addAll(
                          visibleUncompleted.map((s) => s['id'].toString()),
                        );
                      } else {
                        _selectedSubOrders.removeAll(
                          visibleUncompleted.map((s) => s['id'].toString()),
                        );
                        if (_selectedSubOrders.isEmpty) {
                          _isMultiSelectMode = false;
                        }
                      }
                    });
                  },
                  selectedColor: AppColors.white,
                ),
              ),
              const SizedBox(width: 8),

              FilterChip(
                showCheckmark: false,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: _showOnlyWithNotes ? Colors.white : Colors.black87,
                ),
                labelPadding: EdgeInsets.symmetric(horizontal: 2),
                label: Text(AppLocalizations.of(context)!.notes_text),
                selected: _showOnlyWithNotes,
                onSelected: (val) {
                  setState(() {
                    _isLoading = true;
                    _showOnlyWithNotes = val;
                  });
                  _fetchDetails();
                },
                selectedColor: AppColors.buttonBlueDark,
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                position: PopupMenuPosition.under,
                onOpened: () => setState(() => _isDateMenuOpen = true),
                onCanceled: () => setState(() => _isDateMenuOpen = false),
                onSelected: (val) {
                  setState(() {
                    _isLoading = true;
                    _isDateMenuOpen = false;
                    if (val == 'clear') {
                      _dateSortDirection = null;
                    } else {
                      _dateSortDirection = val;
                      _quantitySortDirection = null;
                    }
                  });
                  _fetchDetails();
                },
                itemBuilder: (context) {
                  final isAr =
                      Localizations.localeOf(context).languageCode == 'ar';
                  return [
                    PopupMenuItem(
                      value: 'asc',
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              isAr ? 'من الأقدم للأحدث' : 'Oldest to Newest',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            _dateSortDirection == 'asc'
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: _dateSortDirection == 'asc'
                                ? AppColors.buttonBlueDark
                                : Colors.grey,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'desc',
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              isAr ? 'من الأحدث للأقدم' : 'Newest to Oldest',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            _dateSortDirection == 'desc'
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: _dateSortDirection == 'desc'
                                ? AppColors.buttonBlueDark
                                : Colors.grey,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                    if (_dateSortDirection != null)
                      PopupMenuItem(
                        value: 'clear',
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                isAr ? 'مسح الفرز' : 'Clear Sort',
                                style: TextStyle(
                                  color: AppColors.buttonBlueDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ];
                },
                child: IgnorePointer(
                  child: FilterChip(
                    label: Text('↑↓ ${AppLocalizations.of(context)!.date}'),
                    selected: _dateSortDirection != null || _isDateMenuOpen,
                    onSelected: (_) {}, // Handled by PopupMenuButton
                    selectedColor: AppColors.buttonBlueDark,
                    labelPadding: EdgeInsets.symmetric(horizontal: 2),
                    showCheckmark: false,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: (_dateSortDirection != null || _isDateMenuOpen)
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: EdgeInsetsDirectional.only(end: 16),
                child: PopupMenuButton<String>(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  position: PopupMenuPosition.under,
                  onOpened: () => setState(() => _isQuantityMenuOpen = true),
                  onCanceled: () => setState(() => _isQuantityMenuOpen = false),
                  onSelected: (val) {
                    setState(() {
                      _isLoading = true;
                      _isQuantityMenuOpen = false;
                      if (val == 'clear') {
                        _quantitySortDirection = null;
                      } else {
                        _quantitySortDirection = val;
                        _dateSortDirection = null;
                      }
                    });
                    _fetchDetails();
                  },
                  itemBuilder: (context) {
                    final isAr =
                        Localizations.localeOf(context).languageCode == 'ar';
                    return [
                      PopupMenuItem(
                        value: 'asc',
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                isAr ? 'من الأقل للأكثر' : 'Lowest to Highest',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              _quantitySortDirection == 'asc'
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: _quantitySortDirection == 'asc'
                                  ? AppColors.buttonBlueDark
                                  : Colors.grey,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'desc',
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                isAr ? 'من الأكثر للأقل' : 'Highest to Lowest',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              _quantitySortDirection == 'desc'
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: _quantitySortDirection == 'desc'
                                  ? AppColors.buttonBlueDark
                                  : Colors.grey,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                      if (_quantitySortDirection != null)
                        PopupMenuItem(
                          value: 'clear',
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  isAr ? 'مسح الفرز' : 'Clear Sort',
                                  style: TextStyle(
                                    color: AppColors.buttonBlueDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ];
                  },
                  child: IgnorePointer(
                    child: FilterChip(
                      label: Text(
                        '↑↓ ${AppLocalizations.of(context)!.quantity}',
                      ),
                      selected:
                          _quantitySortDirection != null || _isQuantityMenuOpen,
                      onSelected: (_) {}, // Handled by PopupMenuButton
                      selectedColor: AppColors.buttonBlueDark,
                      labelPadding: EdgeInsets.symmetric(horizontal: 2),
                      showCheckmark: false,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color:
                            (_quantitySortDirection != null ||
                                _isQuantityMenuOpen)
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Builder(
          builder: (context) {
            if (_isLoading) {
              return Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Column(
                  children: List.generate(
                    4,
                    (index) => Container(
                      width: double.infinity,
                      height: 120,
                      margin: const EdgeInsets.only(
                        bottom: 12,
                        left: 16,
                        right: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              );
            }
            final sortedList = _subOrders;
            // An empty list with no search/filter narrowing it down means the
            // order is done, not that the driver filtered everything out.
            final bool isNarrowedDown =
                _searchQuery.isNotEmpty || _showOnlyWithNotes;
            if (_allOrdersCompleted ||
                (sortedList.isEmpty && !isNarrowedDown)) {
              final isAr = Localizations.localeOf(context).languageCode == 'ar';
              return Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isAr ? 'لا توجد طلبات متاحة' : 'No orders available',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                          });
                          _fetchDetails();
                        },
                        icon: const Icon(Icons.refresh),
                        label: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonBlueDark,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (sortedList.isEmpty) {
              final isAr = Localizations.localeOf(context).languageCode == 'ar';
              return Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.search_off_rounded,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isAr
                            ? 'لا توجد طلبات تطابق الفلاتر المحددة'
                            : 'No orders match your filters',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _dateSortDirection = null;
                            _quantitySortDirection = null;
                          });
                          _fetchDetails();
                        },
                        icon: const Icon(Icons.refresh),
                        label: Text(isAr ? 'تحديث' : 'Refresh'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonBlueDark,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Column(
              children:
                  sortedList
                      .map((subOrder) {
                        final product = subOrder['product'] ?? {};
                        final subId = subOrder['id']?.toString() ?? '';
                        final isSelected = _selectedSubOrders.contains(subId);
                        final isCompleted =
                            subOrder['status'] == 'DELIVERED' ||
                            subOrder['status'] == 'COMPLETED';

                        return GestureDetector(
                          onLongPress: () {
                            if (isCompleted) return;
                            if (_subOrders.length > 1) {
                              setState(() {
                                _isMultiSelectMode = true;
                                _selectedSubOrders.add(subId);
                              });
                            }
                          },
                          onTap: () {
                            if (isCompleted) return;
                            if (_isMultiSelectMode) {
                              setState(() {
                                if (isSelected) {
                                  _selectedSubOrders.remove(subId);
                                  if (_selectedSubOrders.isEmpty) {
                                    _isMultiSelectMode = false;
                                  }
                                } else {
                                  _selectedSubOrders.add(subId);
                                }
                              });
                            } else {
                              _navigateToSingleProofSubmission(subId);
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(
                              bottom: 12,
                              left: 16,
                              right: 16,
                            ),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: isSelected
                                  ? Border.all(
                                      color: AppColors.buttonBlueDark,
                                      width: 2,
                                    )
                                  : Border.all(
                                      color: Colors.transparent,
                                      width: 2,
                                    ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Padding(
                                            padding:
                                                const EdgeInsetsDirectional.only(
                                                  end: 8,
                                                ),
                                            child: SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: Checkbox(
                                                value: isSelected,
                                                onChanged: isCompleted
                                                    ? null
                                                    : (bool? value) {
                                                        setState(() {
                                                          _isMultiSelectMode =
                                                              true;
                                                          if (value == true) {
                                                            _selectedSubOrders
                                                                .add(subId);
                                                          } else {
                                                            _selectedSubOrders
                                                                .remove(subId);
                                                            if (_selectedSubOrders
                                                                .isEmpty) {
                                                              _isMultiSelectMode =
                                                                  false;
                                                            }
                                                          }
                                                        });
                                                      },
                                                activeColor:
                                                    AppColors.buttonBlueDark,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              (Localizations.localeOf(
                                                            context,
                                                          ).languageCode ==
                                                          'ar'
                                                      ? 'رقم الطلب : '
                                                      : 'Order Number : ') +
                                                  (subOrder['subOrderNumber']
                                                          ?.toString() ??
                                                      subOrder['id']
                                                          ?.toString()
                                                          .substring(0, 8) ??
                                                      ''),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.buttonBlueDark,
                                              ),
                                            ),
                                          ),
                                          if (subOrder['isChillerRefill'] ==
                                              true) ...[
                                            const ChillerRefillBadge(
                                              compact: true,
                                            ),
                                            const SizedBox(width: 6),
                                          ],
                                          if (isCompleted)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.green.withValues(
                                                  alpha: 0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                AppLocalizations.of(
                                                  context,
                                                )!.completed,
                                                style: TextStyle(
                                                  color: Colors.green,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),

                                      const Divider(),

                                      Row(
                                        children: [
                                          if (product['image'] != null &&
                                              product['image']
                                                  .toString()
                                                  .isNotEmpty)
                                            Container(
                                              width: 40,
                                              height: 40,
                                              margin:
                                                  EdgeInsetsDirectional.only(
                                                    end: 12,
                                                  ),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                color: Colors.grey.withValues(
                                                  alpha: 0.1,
                                                ),
                                              ),
                                              clipBehavior: Clip.antiAlias,
                                              child: CachedNetworkImage(
                                                imageUrl: product['image'],
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) =>
                                                    Shimmer.fromColors(
                                                      baseColor:
                                                          Colors.grey[300]!,
                                                      highlightColor:
                                                          Colors.grey[100]!,
                                                      child: Container(
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                errorWidget:
                                                    (
                                                      context,
                                                      url,
                                                      error,
                                                    ) => const Icon(
                                                      Icons
                                                          .inventory_2_outlined,
                                                      color: Colors.grey,
                                                    ),
                                              ),
                                            )
                                          else
                                            Container(
                                              width: 40,
                                              height: 40,
                                              margin: const EdgeInsets.only(
                                                right: 12,
                                              ),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                color: Colors.grey.withValues(
                                                  alpha: 0.1,
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.inventory_2_outlined,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  (Localizations.localeOf(
                                                                context,
                                                              ).languageCode ==
                                                              'ar' &&
                                                          product['nameAr'] !=
                                                              null &&
                                                          product['nameAr']
                                                              .toString()
                                                              .isNotEmpty)
                                                      ? product['nameAr']
                                                      : (product['name'] ??
                                                            AppLocalizations.of(
                                                              context,
                                                            )!.product),
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  AppLocalizations.of(
                                                    context,
                                                  )!.qty(
                                                    subOrder['quantity']
                                                            ?.toString() ??
                                                        '1',
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors
                                                        .buttonBlueDark,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              if (subOrder['deliveryNotes'] !=
                                                      null &&
                                                  subOrder['deliveryNotes']
                                                      .toString()
                                                      .isNotEmpty) ...[
                                                ElevatedButton(
                                                  onPressed: () {
                                                    _showNotesBottomSheet(
                                                      context,
                                                      subOrder,
                                                      true,
                                                    );
                                                  },
                                                  style: ButtonStyle(
                                                    backgroundColor:
                                                        WidgetStatePropertyAll(
                                                          Colors.white,
                                                        ),
                                                    shape:
                                                        WidgetStatePropertyAll(
                                                          CircleBorder(),
                                                        ),
                                                    padding:
                                                        WidgetStatePropertyAll(
                                                          EdgeInsetsDirectional
                                                              .zero,
                                                        ),
                                                    minimumSize:
                                                        WidgetStatePropertyAll(
                                                          Size(36, 36),
                                                        ),
                                                    tapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                  ),
                                                  child: Stack(
                                                    children: [
                                                      Icon(
                                                        Symbols.note_stack,
                                                        size: 20,
                                                        color: AppColors
                                                            .buttonBlueDark,
                                                      ),
                                                      Positioned.directional(
                                                        textDirection:
                                                            TextDirection.ltr,
                                                        top: 1,
                                                        end: 1,
                                                        child: CircleAvatar(
                                                          backgroundColor:
                                                              Colors.orange,
                                                          radius: 4,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                              if (subOrder['deliveryNotes'] !=
                                                      null &&
                                                  subOrder['deliveryNotes']
                                                      .toString()
                                                      .isNotEmpty &&
                                                  subOrder['csNotes'] != null &&
                                                  (subOrder['csNotes'] as List)
                                                      .isNotEmpty)
                                                const SizedBox(width: 6),
                                              if (subOrder['csNotes'] != null &&
                                                  (subOrder['csNotes'] as List)
                                                      .isNotEmpty) ...{
                                                ElevatedButton(
                                                  onPressed: () {
                                                    _showNotesBottomSheet(
                                                      context,
                                                      subOrder,
                                                      false,
                                                    );
                                                  },
                                                  style: ButtonStyle(
                                                    backgroundColor:
                                                        WidgetStatePropertyAll(
                                                          Colors.white,
                                                        ),
                                                    shape:
                                                        WidgetStatePropertyAll(
                                                          CircleBorder(),
                                                        ),
                                                    padding:
                                                        WidgetStatePropertyAll(
                                                          EdgeInsets.zero,
                                                        ),
                                                    minimumSize:
                                                        WidgetStatePropertyAll(
                                                          Size(36, 36),
                                                        ),
                                                    tapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                  ),
                                                  child: Stack(
                                                    children: [
                                                      Icon(
                                                        Symbols.support_agent,
                                                        size: 20,
                                                        color: AppColors
                                                            .buttonBlueDark,
                                                      ),
                                                      Positioned.directional(
                                                        textDirection:
                                                            TextDirection.ltr,
                                                        top: 1,
                                                        end: 1,
                                                        child: CircleAvatar(
                                                          backgroundColor:
                                                              Colors.orange,
                                                          radius: 4,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              },
                                              if (subOrder['giftCard'] !=
                                                  null) ...[
                                                if ((subOrder['deliveryNotes'] !=
                                                            null &&
                                                        subOrder['deliveryNotes']
                                                            .toString()
                                                            .isNotEmpty) ||
                                                    (subOrder['csNotes'] !=
                                                            null &&
                                                        (subOrder['csNotes']
                                                                as List)
                                                            .isNotEmpty))
                                                  const SizedBox(width: 6),
                                                Container(
                                                  width: 36,
                                                  height: 36,
                                                  decoration:
                                                      const BoxDecoration(
                                                        color: Colors.white,
                                                        shape: BoxShape.circle,
                                                      ),
                                                  child: Icon(
                                                    Symbols
                                                        .featured_seasonal_and_gifts,
                                                        size: 20,
                                                    color: const Color.fromARGB(
                                                      255,
                                                      162,
                                                      38,
                                                      29,
                                                    ),
                                                  ),
                                                    
                                                  
                                                
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                      if ((subOrder['mosqueFrontImage'] !=
                                                  null &&
                                              subOrder['mosqueFrontImage']
                                                  .toString()
                                                  .isNotEmpty) ||
                                          (subOrder['mosqueInsideImage'] !=
                                                  null &&
                                              subOrder['mosqueInsideImage']
                                                  .toString()
                                                  .isNotEmpty)) ...[
                                        const SizedBox(height: 8),
                                        const Divider(),
                                        const SizedBox(height: 8),

                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child:
                                                  (subOrder['mosqueFrontImage'] !=
                                                          null &&
                                                      subOrder['mosqueFrontImage']
                                                          .toString()
                                                          .isNotEmpty)
                                                  ? GestureDetector(
                                                      onTap: () =>
                                                          _showFullScreenImage(
                                                            context,
                                                            subOrder['mosqueFrontImage'],
                                                          ),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          AspectRatio(
                                                            aspectRatio: 0.8,
                                                            child: ClipRRect(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    8,
                                                                  ),
                                                              child: CachedNetworkImage(
                                                                imageUrl:
                                                                    subOrder['mosqueFrontImage'],
                                                                width: double
                                                                    .infinity,
                                                                fit: BoxFit
                                                                    .cover,
                                                                placeholder: (context, url) => Shimmer.fromColors(
                                                                  baseColor: Colors
                                                                      .grey[300]!,
                                                                  highlightColor:
                                                                      Colors
                                                                          .grey[100]!,
                                                                  child: Container(
                                                                    color: Colors
                                                                        .white,
                                                                  ),
                                                                ),
                                                                errorWidget:
                                                                    (
                                                                      context,
                                                                      url,
                                                                      error,
                                                                    ) => Container(
                                                                      color: Colors
                                                                          .grey[200],
                                                                      width: double
                                                                          .infinity,
                                                                      child: const Icon(
                                                                        Icons
                                                                            .image_not_supported,
                                                                        color: Colors
                                                                            .grey,
                                                                      ),
                                                                    ),
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 8,
                                                          ),
                                                          Text(
                                                            (widget.orderType
                                                                            ?.toLowerCase() ==
                                                                        'orphanage' ||
                                                                    widget.orderType
                                                                            ?.toLowerCase() ==
                                                                        'orphanages')
                                                                ? AppLocalizations.of(
                                                                    context,
                                                                  )!.orphanageFront
                                                                : (widget.orderType
                                                                              ?.toLowerCase() ==
                                                                          'graveyard' ||
                                                                      widget.orderType
                                                                              ?.toLowerCase() ==
                                                                          'graveyards')
                                                                ? AppLocalizations.of(
                                                                    context,
                                                                  )!.graveyardFront
                                                                : AppLocalizations.of(
                                                                    context,
                                                                  )!.mosqueFront,
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  color: Colors
                                                                      .black87,
                                                                ),
                                                            maxLines: 2,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ],
                                                      ),
                                                    )
                                                  : const SizedBox(),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child:
                                                  (subOrder['mosqueInsideImage'] !=
                                                          null &&
                                                      subOrder['mosqueInsideImage']
                                                          .toString()
                                                          .isNotEmpty)
                                                  ? GestureDetector(
                                                      onTap: () =>
                                                          _showFullScreenImage(
                                                            context,
                                                            subOrder['mosqueInsideImage'],
                                                          ),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          AspectRatio(
                                                            aspectRatio: 0.8,
                                                            child: ClipRRect(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    8,
                                                                  ),
                                                              child: CachedNetworkImage(
                                                                imageUrl:
                                                                    subOrder['mosqueInsideImage'],
                                                                width: double
                                                                    .infinity,
                                                                fit: BoxFit
                                                                    .cover,
                                                                placeholder: (context, url) => Shimmer.fromColors(
                                                                  baseColor: Colors
                                                                      .grey[300]!,
                                                                  highlightColor:
                                                                      Colors
                                                                          .grey[100]!,
                                                                  child: Container(
                                                                    color: Colors
                                                                        .white,
                                                                  ),
                                                                ),
                                                                errorWidget:
                                                                    (
                                                                      context,
                                                                      url,
                                                                      error,
                                                                    ) => Container(
                                                                      color: Colors
                                                                          .grey[200],
                                                                      width: double
                                                                          .infinity,
                                                                      child: const Icon(
                                                                        Icons
                                                                            .image_not_supported,
                                                                        color: Colors
                                                                            .grey,
                                                                      ),
                                                                    ),
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 8,
                                                          ),
                                                          Text(
                                                            (widget.orderType
                                                                            ?.toLowerCase() ==
                                                                        'orphanage' ||
                                                                    widget.orderType
                                                                            ?.toLowerCase() ==
                                                                        'orphanages')
                                                                ? AppLocalizations.of(
                                                                    context,
                                                                  )!.orphanageInsideImage
                                                                : (widget.orderType
                                                                              ?.toLowerCase() ==
                                                                          'graveyard' ||
                                                                      widget.orderType
                                                                              ?.toLowerCase() ==
                                                                          'graveyards')
                                                                ? AppLocalizations.of(
                                                                    context,
                                                                  )!.graveyardInsideImage
                                                                : AppLocalizations.of(
                                                                    context,
                                                                  )!.mosqueInsideImage,
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  color: Colors
                                                                      .black87,
                                                                ),
                                                            maxLines: 2,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ],
                                                      ),
                                                    )
                                                  : const SizedBox(),
                                            ),
                                            const SizedBox(width: 12),
                                            const Expanded(child: SizedBox()),
                                            const SizedBox(width: 12),
                                            const Expanded(child: SizedBox()),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      })
                      .cast<Widget>()
                      .toList()
                    ..addAll(
                      _isFetchingMore
                          ? [const ListShimmerLoader(itemCount: 2)]
                          : [],
                    ),
            );
          },
        ),
      ],
    );
  }

  void _showNotesBottomSheet(
    BuildContext context,
    Map<String, dynamic> subOrder,
    bool isForDeliveryNote,
  ) {
    showModalBottomSheet(
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.3,
      ),
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.buttonBlueDark,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                padding: const EdgeInsets.only(
                  top: 24,
                  left: 16,
                  right: 16,
                  bottom: 24,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.notes_text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Container(
                color: AppColors.buttonBlueDark,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (subOrder['csNotes'] != null &&
                          (subOrder['csNotes'] as List).isNotEmpty &&
                          isForDeliveryNote == false) ...[
                        Row(
                          children: [
                            const Icon(
                              Icons.support_agent_outlined,
                              size: 20,
                              color: AppColors.buttonBlueDark,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppLocalizations.of(
                                context,
                              )!.customer_service_notes,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          csNotesToRemarks(
                            subOrder['csNotes'] as List?,
                          ).join('\n'),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      if (subOrder['deliveryNotes'] != null &&
                          subOrder['deliveryNotes']
                              .toString()
                              .trim()
                              .isNotEmpty &&
                          isForDeliveryNote == true) ...[
                        Row(
                          children: [
                            const Icon(
                              Icons.local_shipping_outlined,
                              size: 20,
                              color: AppColors.buttonBlueDark,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppLocalizations.of(context)!.customer_note,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          subOrder['deliveryNotes'].toString().trim(),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBatchImagesBottomSheet(BuildContext context) {
    debugPrint('Bulk Image Upload: Bottom sheet opened');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final canSave =
                _batchMosqueFrontImage != null &&
                _batchMosqueInsideImage != null;

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: AppColors.buttonBlueDark,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    padding: const EdgeInsets.only(
                      top: 24,
                      left: 16,
                      right: 16,
                      bottom: 24,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.uploadBatchImages,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),

                  Container(
                    color: AppColors.buttonBlueDark,

                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,

                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDottedImagePicker(
                                context,
                                label:
                                    (widget.orderType?.toLowerCase() ==
                                            'orphanage' ||
                                        widget.orderType?.toLowerCase() ==
                                            'orphanages')
                                    ? AppLocalizations.of(
                                        context,
                                      )!.orphanageFront
                                    : (widget.orderType?.toLowerCase() ==
                                              'graveyard' ||
                                          widget.orderType?.toLowerCase() ==
                                              'graveyards')
                                    ? AppLocalizations.of(
                                        context,
                                      )!.graveyardFront
                                    : AppLocalizations.of(context)!.mosqueFront,
                                path: _batchMosqueFrontImage,
                                onPick: (source) async {
                                  debugPrint(
                                    'Bulk Image Upload: Mosque front image picking started from source: $source',
                                  );
                                  setSheetState(
                                    () => _isCompressingBatchFrontImage = true,
                                  );
                                  final file = await _pickImageWithConstraints(
                                    context,
                                    source,
                                  );
                                  setSheetState(
                                    () => _isCompressingBatchFrontImage = false,
                                  );
                                  if (file != null) {
                                    debugPrint(
                                      'Bulk Image Upload: Mosque front image picked successfully: $file',
                                    );
                                    setSheetState(
                                      () => _batchMosqueFrontImage = file,
                                    );
                                  } else {
                                    debugPrint(
                                      'Bulk Image Upload: Mosque front image picking cancelled',
                                    );
                                  }
                                },
                                isLoading: _isCompressingBatchFrontImage,
                              ),
                              const SizedBox(width: 12),
                              _buildDottedImagePicker(
                                context,
                                label:
                                    (widget.orderType?.toLowerCase() ==
                                            'orphanage' ||
                                        widget.orderType?.toLowerCase() ==
                                            'orphanages')
                                    ? AppLocalizations.of(
                                        context,
                                      )!.orphanageInsideImage
                                    : (widget.orderType?.toLowerCase() ==
                                              'graveyard' ||
                                          widget.orderType?.toLowerCase() ==
                                              'graveyards')
                                    ? AppLocalizations.of(
                                        context,
                                      )!.graveyardInsideImage
                                    : AppLocalizations.of(
                                        context,
                                      )!.mosqueInsideImage,
                                path: _batchMosqueInsideImage,
                                onPick: (source) async {
                                  debugPrint(
                                    'Bulk Image Upload: Mosque inside image picking started from source: $source',
                                  );
                                  setSheetState(
                                    () => _isCompressingBatchInsideImage = true,
                                  );
                                  final file = await _pickImageWithConstraints(
                                    context,
                                    source,
                                  );
                                  setSheetState(
                                    () =>
                                        _isCompressingBatchInsideImage = false,
                                  );
                                  if (file != null) {
                                    debugPrint(
                                      'Bulk Image Upload: Mosque inside image picked successfully: $file',
                                    );
                                    setSheetState(
                                      () => _batchMosqueInsideImage = file,
                                    );
                                  } else {
                                    debugPrint(
                                      'Bulk Image Upload: Mosque inside image picking cancelled',
                                    );
                                  }
                                },
                                isLoading: _isCompressingBatchInsideImage,
                              ),
                              const SizedBox(width: 12),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: canSave && !_isBatchUploading
                                  ? () async {
                                      debugPrint(
                                        'Bulk Image Upload: Upload button pressed',
                                      );
                                      setSheetState(
                                        () => _isBatchUploading = true,
                                      );
                                      setState(() => _isBatchUploading = true);
                                      try {
                                        debugPrint(
                                          'Bulk Image Upload: Request started for Order ID: ${widget.orderId}',
                                        );
                                        debugPrint(
                                          'Bulk Image Upload: Request SubOrder IDs: ${_selectedSubOrders.toList()}',
                                        );
                                        debugPrint(
                                          'Bulk Image Upload: Request Mosque Front Image Path: $_batchMosqueFrontImage',
                                        );
                                        debugPrint(
                                          'Bulk Image Upload: Request Mosque Inside Image Path: $_batchMosqueInsideImage',
                                        );

                                        await _api.bulkUploadMosqueImages(
                                          orderId: widget.orderId,
                                          subOrderIds: _selectedSubOrders
                                              .toList(),
                                          mosqueFrontImagePath:
                                              _batchMosqueFrontImage!,
                                          mosqueInsideImagePath:
                                              _batchMosqueInsideImage!,
                                        );
                                        debugPrint(
                                          'Bulk Image Upload: Response successful',
                                        );
                                        if (context.mounted) {
                                          CustomSnackbar.show(
                                            context: context,
                                            message:
                                                'Images uploaded successfully!',
                                          );
                                          Navigator.pop(context);
                                        }
                                        setState(() {
                                          _batchMosqueFrontImage = null;
                                          _batchMosqueInsideImage = null;

                                          _isMultiSelectMode = false;
                                          _selectedSubOrders.clear();
                                        });
                                        _fetchDetails();
                                      } catch (e) {
                                        debugPrint(
                                          'Bulk Image Upload: Error occurred: $e',
                                        );
                                        if (context.mounted) {
                                          String errorMessage =
                                              AppLocalizations.of(
                                                context,
                                              )!.somethingWentWrong;
                                          if (e is DioException &&
                                              e.response?.data is Map &&
                                              e.response?.data['message'] !=
                                                  null) {
                                            errorMessage =
                                                e.response!.data['message'];
                                            debugPrint(
                                              'Bulk Image Upload: API Error Response Message: $errorMessage',
                                            );
                                          }
                                          CustomSnackbar.show(
                                            context: context,
                                            message: errorMessage,
                                            isError: true,
                                          );
                                        }
                                      } finally {
                                        setSheetState(
                                          () => _isBatchUploading = false,
                                        );
                                        setState(
                                          () => _isBatchUploading = false,
                                        );
                                      }
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.buttonBlueDark,
                                disabledBackgroundColor: Colors.grey[300],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: _isBatchUploading
                                  ? const WaterLoadingIndicator(
                                      waveColor1: Colors.white,
                                      size: 24,
                                    )
                                  : Text(
                                      AppLocalizations.of(context)!.saveImages,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDottedImagePicker(
    BuildContext context, {
    required String label,
    required String? path,
    required Function(ImageSource) onPick,
    bool isLoading = false,
  }) {
    final hasMedia = path != null && !isLoading;
    return Expanded(
      child: GestureDetector(
        onTap: () => _showSourceBottomSheet(context, onPick),
        onLongPress: hasMedia
            ? () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ImagePreviewPage(path: path)),
              )
            : null,
        child: Column(
          children: [
            DottedBorder(
              options: RoundedRectDottedBorderOptions(
                radius: Radius.circular(12),
                color: Colors.grey.shade400,
                strokeWidth: 1.5,
                dashPattern: const [6, 4],
              ),
              child: Container(
                padding: const EdgeInsets.all(10),
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.hardEdge,
                child: isLoading
                    ? const Center(
                        child: WaterLoadingIndicator(
                          waveColor1: AppColors.buttonBlueDark,
                        ),
                      )
                    : path != null
                    ? ClipRRect(
                        borderRadius: BorderRadiusGeometry.circular(12),
                        child: path.startsWith('http')
                            ? Image.network(path, fit: BoxFit.cover)
                            : Image.file(File(path), fit: BoxFit.cover),
                      )
                    : const Center(
                        child: Icon(
                          Icons.image_outlined,
                          color: Colors.grey,
                          size: 32,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showSourceBottomSheet(
    BuildContext parentContext,
    Function(ImageSource) onPick,
  ) {
    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        height: MediaQuery.of(parentContext).size.height * 0.4,
        color: Colors.transparent,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.buttonBlueDark,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.only(
                top: 24,
                left: 16,
                right: 16,
                bottom: 24,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(sheetContext),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(sheetContext)!.selectSource,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.buttonBlueDark,
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    child: Column(
                      children: [
                        _buildBottomSheetTile(
                          icon: Icons.camera_alt,
                          title: AppLocalizations.of(sheetContext)!.takeAPhoto,
                          onTap: () {
                            Navigator.pop(sheetContext);
                            onPick(ImageSource.camera);
                          },
                        ),
                        if (driver?.canUploadFromGallery == true) ...[
                          const Divider(height: 1, color: Color(0xFFEAEFF2)),
                          _buildBottomSheetTile(
                            icon: Icons.photo_library,
                            title: AppLocalizations.of(
                              sheetContext,
                            )!.chooseFromGallery,
                            onTap: () {
                              Navigator.pop(sheetContext);
                              onPick(ImageSource.gallery);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheetTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.buttonBlueDark, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.white,
                  child: const Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 50,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
            Positioned.directional(
              textDirection: Directionality.of(context),
              top: 16,
              start: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.buttonBlueDark.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
