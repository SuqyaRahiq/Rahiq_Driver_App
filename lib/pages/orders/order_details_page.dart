import 'package:material_symbols_icons/symbols.dart';
import 'package:rahiq_driver/data/models/driver/product.dart';
import 'package:flutter/material.dart';
import 'package:rahiq_driver/data/api/api_client.dart';
import 'package:rahiq_driver/data/api/driver/driver_orders_api.dart';
import 'package:rahiq_driver/data/models/driver/driver_order.dart';
import 'package:rahiq_driver/pages/shared/proof_submission_page.dart';
import 'package:rahiq_driver/utils/colors.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:dio/dio.dart';
import 'package:rahiq_driver/l10n/app_localizations.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:rahiq_driver/common_widgets/custom_snackbar.dart';
import 'package:rahiq_driver/utils/water_loading.dart';

class OrderDetailsPage extends StatefulWidget {
  final DriverOrder item;

  const OrderDetailsPage({super.key, required this.item});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  late DriverOrdersApi _api;
  bool _isLoading = true;
  String? _error;
  List<dynamic> _subOrders = [];
  bool _isMultiSelectMode = false;
  final Set<String> _selectedSubOrders = {};

  String? _dateSortDirection; // 'asc' or 'desc'
  String? _quantitySortDirection; // 'asc' or 'desc'
  bool _showOnlyWithNotes = false;
  bool _isDateMenuOpen = false;
  bool _isQuantityMenuOpen = false;

  List<dynamic> _getSortedSubOrders() {
    List<dynamic> list = List.from(_subOrders);

    if (_showOnlyWithNotes) {
      list = list.where((a) {
        final hasNotes =
            (a['deliveryNotes'] != null &&
                a['deliveryNotes'].toString().trim().isNotEmpty) ||
            (a['csNotes'] != null && (a['csNotes'] as List).isNotEmpty);
        return hasNotes;
      }).toList();
    }

    if (_dateSortDirection != null || _quantitySortDirection != null) {
      list.sort((a, b) {
        int comparison = 0;

        if (_dateSortDirection != null) {
          final aDateStr = a['assignedDate']?.toString();
          final bDateStr = b['assignedDate']?.toString();
          final aDate = aDateStr != null ? DateTime.tryParse(aDateStr) : null;
          final bDate = bDateStr != null ? DateTime.tryParse(bDateStr) : null;

          if (aDate != null && bDate != null) {
            comparison = aDate.compareTo(bDate);
          } else if (aDate != null) {
            comparison = -1;
          } else if (bDate != null) {
            comparison = 1;
          }
          if (_dateSortDirection == 'desc') {
            comparison = -comparison;
          }
        }

        if (comparison == 0 && _quantitySortDirection != null) {
          final aQty = int.tryParse(a['quantity']?.toString() ?? '0') ?? 0;
          final bQty = int.tryParse(b['quantity']?.toString() ?? '0') ?? 0;
          final qtyComparison = aQty.compareTo(bQty);
          if (_quantitySortDirection == 'desc') {
            comparison = -qtyComparison;
          } else {
            comparison = qtyComparison;
          }
        }

        return comparison;
      });
    }

    return list;
  }

  String? _batchMosqueFrontImage;
  String? _batchMosqueInsideImage;

  final ImagePicker _picker = ImagePicker();
  bool _isBatchUploading = false;

  @override
  void initState() {
    super.initState();
    _api = DriverOrdersApi(ApiClient());
    _fetchDetails();
  }

  Future<void> _fetchDetails({bool checkCompletion = false}) async {
    try {
      final details = await _api.getNormalOrderSubOrders(widget.item.id);
      if (mounted) {
        setState(() {
          _subOrders = details.map((s) => s.toJson()).toList();
          _isLoading = false;
        });

        if (checkCompletion) {
          final uncompleted = _subOrders.where(
            (s) => s['status'] != 'DELIVERED' && s['status'] != 'COMPLETED',
          );
          if (uncompleted.isEmpty) {
            Navigator.popUntil(context, (route) => route.isFirst);
          }
        }
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
                            final subOrder = _subOrders.firstWhere(
                              (s) => s['id']?.toString() == subId,
                              orElse: () => {},
                            );
                            final customer = subOrder['customerDetails'] ?? {};
                            final address =
                                subOrder['deliveryAddress'] ??
                                customer['address'];

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProofSubmissionPage(
                                  isAutoOrder: true,
                                  orderId: widget.item.id,
                                  product: Product(
                                    id:
                                        (subOrder['product'] ?? {})['id']
                                            ?.toString() ??
                                        '',
                                    name:
                                        (subOrder['product'] ?? {})['name']
                                            ?.toString() ??
                                        '',
                                    nameAr:
                                        (subOrder['product'] ?? {})['nameAr']
                                            ?.toString() ??
                                        '',
                                    image:
                                        (subOrder['product'] ?? {})['image']
                                            ?.toString() ??
                                        '',
                                  ),
                                  subOrders: [subId],
                                  singleCustomerData: {
                                    'firstName': customer['firstName'],
                                    'lastName': customer['lastName'],
                                    'phoneNumber': customer['phoneNumber'],
                                    'address': address,
                                  },
                                  initialMosqueFrontImage:
                                      subOrder['mosqueFrontImage'],
                                  initialMosqueInsideImage:
                                      subOrder['mosqueInsideImage'],
                                ),
                              ),
                            ).then((submitted) {
                              setState(() {
                                _isMultiSelectMode = false;
                                _selectedSubOrders.clear();
                              });
                              _fetchDetails(checkCompletion: submitted == true);
                            });
                          } else {
                            _showBatchImagesBottomSheet(context);
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
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
      body: SingleChildScrollView(
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
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 60, 16, 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
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
                          (Localizations.localeOf(context).languageCode ==
                                      'ar' &&
                                  widget.item.nameAr!.isNotEmpty)
                              ? widget.item.nameAr ?? ""
                              : widget.item.name ?? "",
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
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 100),
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

                          if (_isLoading || _subOrders.isNotEmpty)
                            (!_isLoading && _getSortedSubOrders().isEmpty)
                                ? Expanded(child: _buildSubOrdersSection())
                                : _buildSubOrdersSection(),

                          if (_isLoading ||
                              _subOrders.isEmpty ||
                              _getSortedSubOrders().isNotEmpty)
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
    );
  }

  Widget _buildSubOrdersSection() {
    final sortedSubOrders = _getSortedSubOrders();
    final visibleUncompleted = sortedSubOrders
        .where((s) => s['status'] != 'DELIVERED' && s['status'] != 'COMPLETED')
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
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.subOrdersLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(
                showCheckmark: false,
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: isAllSelected
                      ? AppColors.buttonBlueDark.withValues(alpha: 0.7)
                      : Colors.grey.shade300,
                  width: 1,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
                    Text(AppLocalizations.of(context)!.select_all),
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
                    _showOnlyWithNotes = val;
                    if (val) {
                      _dateSortDirection = null;
                      _quantitySortDirection = null;
                    }
                  });
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
                    _isDateMenuOpen = false;
                    _showOnlyWithNotes = false;
                    if (val == 'clear') {
                      _dateSortDirection = null;
                    } else {
                      _dateSortDirection = val;
                    }
                  });
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
              PopupMenuButton<String>(
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
                    _isQuantityMenuOpen = false;
                    _showOnlyWithNotes = false;
                    if (val == 'clear') {
                      _quantitySortDirection = null;
                    } else {
                      _quantitySortDirection = val;
                    }
                  });
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
                    label: Text('↑↓ ${AppLocalizations.of(context)!.quantity}'),
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
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              );
            }
            final sortedList = _getSortedSubOrders();
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
              children: sortedList.map((subOrder) {
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) {
                            final customer = subOrder['customerDetails'] ?? {};
                            final address =
                                subOrder['deliveryAddress'] ??
                                customer['address'];

                            return ProofSubmissionPage(
                              isAutoOrder: true,
                              orderId: widget.item.id,
                              product: Product(
                                id:
                                    (subOrder['product'] ?? {})['id']
                                        ?.toString() ??
                                    '',
                                name:
                                    (subOrder['product'] ?? {})['name']
                                        ?.toString() ??
                                    '',
                                nameAr:
                                    (subOrder['product'] ?? {})['nameAr']
                                        ?.toString() ??
                                    '',
                                image:
                                    (subOrder['product'] ?? {})['image']
                                        ?.toString() ??
                                    '',
                              ),
                              subOrders: [subId],
                              singleCustomerData: {
                                'firstName': customer['firstName'],
                                'lastName': customer['lastName'],
                                'phoneNumber': customer['phoneNumber'],
                                'address': address,
                                'subOrderNumber':
                                    subOrder['subOrderNumber']?.toString() ??
                                    (subId.length > 8
                                        ? subId.substring(0, 8)
                                        : subId),
                                'quantity': subOrder['quantity'],
                              },
                              initialMosqueFrontImage:
                                  subOrder['mosqueFrontImage'],
                              initialMosqueInsideImage:
                                  subOrder['mosqueInsideImage'],
                            );
                          },
                        ),
                      ).then(
                        (submitted) =>
                            _fetchDetails(checkCompletion: submitted == true),
                      );
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: isSelected
                          ? Border.all(
                              color: AppColors.buttonBlueDark,
                              width: 2,
                            )
                          : Border.all(color: Colors.transparent, width: 2),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (_subOrders.length > 1)
                                    Padding(
                                      padding: const EdgeInsetsDirectional.only(
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
                                                    _isMultiSelectMode = true;
                                                    if (value == true) {
                                                      _selectedSubOrders.add(
                                                        subId,
                                                      );
                                                    } else {
                                                      _selectedSubOrders.remove(
                                                        subId,
                                                      );
                                                      if (_selectedSubOrders
                                                          .isEmpty) {
                                                        _isMultiSelectMode =
                                                            false;
                                                      }
                                                    }
                                                  });
                                                },
                                          activeColor: AppColors.buttonBlueDark,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
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
                                  if (isCompleted)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        AppLocalizations.of(context)!.completed,
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
                                      product['image'].toString().isNotEmpty)
                                    Container(
                                      width: 40,
                                      height: 40,
                                      margin: EdgeInsetsDirectional.only(
                                        end: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
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
                                              baseColor: Colors.grey[300]!,
                                              highlightColor: Colors.grey[100]!,
                                              child: Container(
                                                color: Colors.white,
                                              ),
                                            ),
                                        errorWidget: (context, url, error) =>
                                            const Icon(
                                              Icons.inventory_2_outlined,
                                              color: Colors.grey,
                                            ),
                                      ),
                                    )
                                  else
                                    Container(
                                      width: 40,
                                      height: 40,
                                      margin: const EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
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
                                                  product['nameAr'] != null &&
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
                                          AppLocalizations.of(context)!.qty(
                                            subOrder['quantity']?.toString() ??
                                                '1',
                                          ),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.buttonBlueDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      if (subOrder['deliveryNotes'] != null &&
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
                                            shape: WidgetStatePropertyAll(
                                              CircleBorder(),
                                            ),
                                            padding: WidgetStatePropertyAll(
                                              EdgeInsetsDirectional.zero,
                                            ),
                                            minimumSize: WidgetStatePropertyAll(
                                              Size(36, 36),
                                            ),
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          child: Stack(
                                            children: [
                                              const Icon(
                                                Symbols.note_stack,
                                                size: 20,
                                                color: Colors.grey,
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
                                      if (subOrder['deliveryNotes'] != null &&
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
                                            shape: WidgetStatePropertyAll(
                                              CircleBorder(),
                                            ),
                                            padding: WidgetStatePropertyAll(
                                              EdgeInsets.zero,
                                            ),
                                            minimumSize: WidgetStatePropertyAll(
                                              Size(36, 36),
                                            ),
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          child: Stack(
                                            children: [
                                              const Icon(
                                                Icons.support_agent_outlined,
                                                size: 20,
                                                color: Colors.grey,
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
                                    ],
                                  ),
                                ],
                              ),
                              if ((subOrder['mosqueFrontImage'] != null &&
                                      subOrder['mosqueFrontImage']
                                          .toString()
                                          .isNotEmpty) ||
                                  (subOrder['mosqueInsideImage'] != null &&
                                      subOrder['mosqueInsideImage']
                                          .toString()
                                          .isNotEmpty)) ...[
                                const SizedBox(height: 8),
                                const Divider(),
                                const SizedBox(height: 8),

                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child:
                                          (subOrder['mosqueFrontImage'] !=
                                                  null &&
                                              subOrder['mosqueFrontImage']
                                                  .toString()
                                                  .isNotEmpty)
                                          ? GestureDetector(
                                              onTap: () => _showFullScreenImage(
                                                context,
                                                subOrder['mosqueFrontImage'],
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
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
                                                        width: double.infinity,
                                                        fit: BoxFit.cover,
                                                        placeholder:
                                                            (
                                                              context,
                                                              url,
                                                            ) => Shimmer.fromColors(
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
                                                                color:
                                                                    Colors.grey,
                                                              ),
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    AppLocalizations.of(
                                                      context,
                                                    )!.mosqueFront,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.black87,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
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
                                              onTap: () => _showFullScreenImage(
                                                context,
                                                subOrder['mosqueInsideImage'],
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
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
                                                        width: double.infinity,
                                                        fit: BoxFit.cover,
                                                        placeholder:
                                                            (
                                                              context,
                                                              url,
                                                            ) => Shimmer.fromColors(
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
                                                                color:
                                                                    Colors.grey,
                                                              ),
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    AppLocalizations.of(
                                                      context,
                                                    )!.mosqueInsideImage,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.black87,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
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
              }).toList(),
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
                              AppLocalizations.of(context)!.notes_text,
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
                          (subOrder['csNotes'] as List).join('\n'),
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
                              AppLocalizations.of(context)!.notes_text,
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
                                label: AppLocalizations.of(
                                  context,
                                )!.mosqueFront,
                                path: _batchMosqueFrontImage,
                                onPick: (source) async {
                                  debugPrint(
                                    'Bulk Image Upload: Mosque front image picking started from source: $source',
                                  );
                                  final file = await _picker.pickImage(
                                    source: source,
                                  );
                                  if (file != null) {
                                    debugPrint(
                                      'Bulk Image Upload: Mosque front image picked successfully: ${file.path}',
                                    );
                                    setSheetState(
                                      () => _batchMosqueFrontImage = file.path,
                                    );
                                  } else {
                                    debugPrint(
                                      'Bulk Image Upload: Mosque front image picking cancelled',
                                    );
                                  }
                                },
                              ),
                              const SizedBox(width: 12),
                              _buildDottedImagePicker(
                                context,
                                label: AppLocalizations.of(
                                  context,
                                )!.mosqueInsideImage,
                                path: _batchMosqueInsideImage,
                                onPick: (source) async {
                                  debugPrint(
                                    'Bulk Image Upload: Mosque inside image picking started from source: $source',
                                  );
                                  final file = await _picker.pickImage(
                                    source: source,
                                  );
                                  if (file != null) {
                                    debugPrint(
                                      'Bulk Image Upload: Mosque inside image picked successfully: ${file.path}',
                                    );
                                    setSheetState(
                                      () => _batchMosqueInsideImage = file.path,
                                    );
                                  } else {
                                    debugPrint(
                                      'Bulk Image Upload: Mosque inside image picking cancelled',
                                    );
                                  }
                                },
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
                                          'Bulk Image Upload: Request started for Order ID: ${widget.item.id}',
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
                                          orderId: widget.item.id,
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
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _showSourceBottomSheet(context, onPick),
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
                child: path != null
                    ? ClipRRect(
                        borderRadius: BorderRadiusGeometry.circular(12),
                        child: path.startsWith('http')
                            ? CachedNetworkImage(
                                imageUrl: path,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    Shimmer.fromColors(
                                      baseColor: Colors.grey[300]!,
                                      highlightColor: Colors.grey[100]!,
                                      child: Container(color: Colors.white),
                                    ),
                              )
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
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(color: Colors.white),
                ),
                errorWidget: (context, url, error) => Container(
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
