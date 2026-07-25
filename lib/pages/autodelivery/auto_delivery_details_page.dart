import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:flutter/material.dart';
import 'package:rahiq_driver/data/api/api_client.dart';
import 'package:rahiq_driver/data/api/driver/driver_auto_deliveries_api.dart';
import 'package:rahiq_driver/data/models/driver/driver_auto_delivery.dart';
import 'package:rahiq_driver/pages/shared/proof_submission_page.dart';
import 'package:rahiq_driver/utils/colors.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:dio/dio.dart';
import 'package:rahiq_driver/l10n/app_localizations.dart';
import 'package:shimmer/shimmer.dart';
import 'package:rahiq_driver/pages/shared/custom_camera_screen.dart';
import 'package:rahiq_driver/utils/media_compressor.dart';
import 'package:rahiq_driver/common_widgets/custom_snackbar.dart';
import 'package:rahiq_driver/utils/water_loading.dart';

class AutoDeliveryDetailsPage extends StatefulWidget {
  final DriverAutoDelivery item;

  const AutoDeliveryDetailsPage({super.key, required this.item});

  @override
  State<AutoDeliveryDetailsPage> createState() =>
      _AutoDeliveryDetailsPageState();
}

class _AutoDeliveryDetailsPageState extends State<AutoDeliveryDetailsPage> {
  late DriverAutoDeliveriesApi _api;
  bool _isLoading = true;
  String? _error;
  List<dynamic> _subOrders = [];
  bool _isMultiSelectMode = false;
  final Set<String> _selectedSubOrders = {};

  bool _isDateAscending = false;
  bool _isQuantityAscending = false;
  bool _isNotesTop = false;
  String _primarySort = 'date';

  List<dynamic> _getSortedSubOrders() {
    List<dynamic> sorted = List.from(_subOrders);

    sorted.sort((a, b) {
      if (_isNotesTop) {
        final aHasNotes =
            (a['deliveryNotes'] != null &&
                a['deliveryNotes'].toString().isNotEmpty) ||
            (a['csNotes'] != null && (a['csNotes'] as List).isNotEmpty);
        final bHasNotes =
            (b['deliveryNotes'] != null &&
                b['deliveryNotes'].toString().isNotEmpty) ||
            (b['csNotes'] != null && (b['csNotes'] as List).isNotEmpty);
        if (aHasNotes && !bHasNotes) return -1;
        if (!aHasNotes && bHasNotes) return 1;
      }

      int dateComparison = 0;
      final aDateStr = a['assignedDate']?.toString();
      final bDateStr = b['assignedDate']?.toString();
      final aDate = aDateStr != null ? DateTime.tryParse(aDateStr) : null;
      final bDate = bDateStr != null ? DateTime.tryParse(bDateStr) : null;
      if (aDate != null && bDate != null) {
        dateComparison = _isDateAscending
            ? aDate.compareTo(bDate)
            : bDate.compareTo(aDate);
      } else if (aDate != null) {
        dateComparison = -1;
      } else if (bDate != null) {
        dateComparison = 1;
      }

      int qtyComparison = 0;
      final aQty = int.tryParse(a['quantity']?.toString() ?? '0') ?? 0;
      final bQty = int.tryParse(b['quantity']?.toString() ?? '0') ?? 0;
      qtyComparison = _isQuantityAscending
          ? aQty.compareTo(bQty)
          : bQty.compareTo(aQty);

      if (_primarySort == 'date') {
        if (dateComparison != 0) return dateComparison;
        return qtyComparison;
      } else {
        if (qtyComparison != 0) return qtyComparison;
        return dateComparison;
      }
    });

    return sorted;
  }

  String? _batchMosqueFrontImage;
  String? _batchMosqueInsideImage;
  String? _batchPackagesImage;
  final ImagePicker _picker = ImagePicker();

  Future<String?> _pickImageWithConstraints(
    BuildContext context,
    ImageSource source, {
    String? customerName,
    String? quantity,
    String? date,
    List<String>? customerNotes,
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
  void initState() {
    super.initState();
    _api = DriverAutoDeliveriesApi(ApiClient());
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final details = await _api.getAutoDeliveryDetails(widget.item.id);
      setState(() {
        // Adapt the single DriverAutoDelivery into a list for the UI
        final json = details.toJson();
        // Map fields that the UI expects
        json['assignedDate'] = json['assignedAt'];
        json['subOrderNumber'] = json['batchNumber'];
        _subOrders = [json];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  double _getLatitude() {
    return widget.item.deliveryLocation?.mosque?.latitude ?? 0.0;
  }

  double _getLongitude() {
    return widget.item.deliveryLocation?.mosque?.longitude ?? 0.0;
  }

  Widget _buildMapArea(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.3;
    final lat = _getLatitude();
    final lng = _getLongitude();
    final target = LatLng(lat, lng);

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: target, zoom: 15),
              markers: {
                Marker(markerId: const MarkerId('dest'), position: target),
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
            ),
          ),
          PositionedDirectional(
            bottom: 16,
            end: 16,
            child: FloatingActionButton.extended(
              onPressed: () async {
                final url =
                    'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(
                    Uri.parse(url),
                    mode: LaunchMode.externalApplication,
                  );
                }
              },
              icon: const Icon(Icons.directions),
              label: Text(AppLocalizations.of(context)!.getDirections),
              backgroundColor: AppColors.buttonBlueDark,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.buttonBlueDark,
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
                                  (widget
                                          .item
                                          .deliveryLocation
                                          ?.mosque
                                          ?.nameAr
                                          ?.isNotEmpty ??
                                      false))
                              ? widget.item.deliveryLocation?.mosque?.nameAr ??
                                    ''
                              : widget.item.deliveryLocation?.mosque?.name ??
                                    '',
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
                    child: _isLoading
                        ? _buildShimmerBody(context)
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_getLatitude() != 0.0 &&
                                  _getLongitude() != 0.0)
                                _buildMapArea(context),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  28,
                                  24,
                                  100,
                                ),
                                child: Column(
                                  children: [
                                    if (_error != null)
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        margin: const EdgeInsets.only(
                                          bottom: 16,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          _error!,
                                          style: const TextStyle(
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),

                                    // ── Category card ────────────────────────────────────
                                    _buildCategoryCard(),

                                    const SizedBox(height: 16),

                                    if (_subOrders.isNotEmpty)
                                      _buildSubOrdersSection(),

                                    const SizedBox(height: 24),

                                    // ── Submit proof button ──────────────────────────────
                                    if (_isMultiSelectMode &&
                                        _selectedSubOrders.isNotEmpty)
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            if (_selectedSubOrders.length ==
                                                1) {
                                              final subId =
                                                  _selectedSubOrders.first;
                                              final subOrder = _subOrders
                                                  .firstWhere(
                                                    (s) =>
                                                        s['id']?.toString() ==
                                                        subId,
                                                    orElse: () => {},
                                                  );
                                              final customer =
                                                  subOrder['customerDetails'] ??
                                                  {};
                                              final address =
                                                  subOrder['deliveryAddress'] ??
                                                  customer['address'];

                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => ProofSubmissionPage(
                                                    isAutoOrder: false,
                                                    isAutoDelivery: true,
                                                    orderId: widget.item.id,
                                                    product:
                                                        widget.item.product,
                                                    subOrders: [subId],
                                                    singleCustomerData: {
                                                      'firstName':
                                                          customer['firstName'],
                                                      'lastName':
                                                          customer['lastName'],
                                                      'phoneNumber':
                                                          customer['phoneNumber'],
                                                      'address': address,
                                                    },
                                                    initialMosqueFrontImage:
                                                        subOrder['mosqueFrontImage'],
                                                    initialMosqueInsideImage:
                                                        subOrder['mosqueInsideImage'],
                                                  ),
                                                ),
                                              ).then((_) {
                                                setState(() {
                                                  _isMultiSelectMode = false;
                                                  _selectedSubOrders.clear();
                                                });
                                                _fetchDetails();
                                              });
                                            } else {
                                              _showBatchImagesBottomSheet(
                                                context,
                                              );
                                            }
                                          },
                                          icon: const Icon(
                                            Icons.upload_file_rounded,
                                            size: 20,
                                          ),
                                          label: Text(
                                            _selectedSubOrders.length == 1
                                                ? AppLocalizations.of(
                                                    context,
                                                  )!.completeOrder
                                                : AppLocalizations.of(
                                                    context,
                                                  )!.uploadBatchImages,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppColors.buttonBlueDark,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
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

  Widget _buildShimmerBody(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 140,
              height: 20,
              margin: const EdgeInsets.only(left: 8, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 80,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 80,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 80,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard() {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final mosque = widget.item.deliveryLocation?.mosque;
    final campaign = widget.item.deliveryLocation?.campaign;

    String localizedName = '';
    if (mosque != null) {
      localizedName = (isArabic && (mosque.nameAr?.isNotEmpty ?? false))
          ? mosque.nameAr!
          : (mosque.name ?? '');
    } else if (campaign != null) {
      localizedName = (isArabic && (campaign.titleAr?.isNotEmpty ?? false))
          ? campaign.titleAr!
          : (campaign.title ?? '');
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Category image
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.buttonBlueDark.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: const Icon(
                Icons.mosque_rounded,
                color: AppColors.buttonBlueDark,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizedName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.buttonBlueDark.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_subOrders.length} ${AppLocalizations.of(context)!.subOrdersLabel}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.buttonBlueDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubOrdersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.batchDeliveries,
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
                label: Text(
                  '${AppLocalizations.of(context)!.date} ${_isDateAscending ? '↑' : '↓'}',
                ),
                selected: _isDateAscending,
                onSelected: (val) {
                  setState(() {
                    _isDateAscending = val;
                    _primarySort = 'date';
                  });
                },
                selectedColor: AppColors.buttonBlueDark,
                showCheckmark: false,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: _isDateAscending ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: Text(
                  '${AppLocalizations.of(context)!.quantity} ${_isQuantityAscending ? '↑' : '↓'}',
                ),
                selected: _isQuantityAscending,
                onSelected: (val) {
                  setState(() {
                    _isQuantityAscending = val;
                    _primarySort = 'quantity';
                  });
                },
                selectedColor: AppColors.buttonBlueDark,
                showCheckmark: false,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: _isQuantityAscending ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                showCheckmark: false,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: _isNotesTop ? Colors.white : Colors.black87,
                ),
                label: Text(AppLocalizations.of(context)!.notes_text),
                selected: _isNotesTop,
                onSelected: (val) {
                  setState(() {
                    _isNotesTop = val;
                  });
                },
                selectedColor: AppColors.buttonBlueDark,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ..._getSortedSubOrders().map((subOrder) {
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
                          subOrder['deliveryAddress'] ?? customer['address'];

                      return ProofSubmissionPage(
                        isAutoOrder: false,
                        isAutoDelivery: true,
                        orderId: widget.item.id,
                        product: widget.item.product,
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
                        initialMosqueFrontImage: subOrder['mosqueFrontImage'],
                        initialMosqueInsideImage: subOrder['mosqueInsideImage'],
                      );
                    },
                  ),
                ).then((_) => _fetchDetails());
              }
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: isSelected
                    ? Border.all(color: AppColors.buttonBlueDark, width: 2)
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
                            Expanded(
                              child: Text(
                                AppLocalizations.of(context)!.subOrderNumber(
                                  subOrder['subOrderNumber']?.toString() ??
                                      subOrder['id']?.toString().substring(
                                        0,
                                        8,
                                      ) ??
                                      '',
                                ),
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
                                  color: Colors.green.withValues(alpha: 0.1),
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
                        if (subOrder['customerDetails'] != null) ...[
                          if ((subOrder['customerDetails']['firstName'] ?? '')
                                  .toString()
                                  .isNotEmpty ||
                              (subOrder['customerDetails']['lastName'] ?? '')
                                  .toString()
                                  .isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.person_outline,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${subOrder['customerDetails']['firstName'] ?? ''} ${subOrder['customerDetails']['lastName'] ?? ''}'
                                          .trim(),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if ((subOrder['customerDetails']['phoneNumber'] ?? '')
                              .toString()
                              .isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.phone_outlined,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      subOrder['customerDetails']['phoneNumber']
                                          .toString(),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                        if (subOrder['deliveryNotes'] != null &&
                            subOrder['deliveryNotes'].toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.note_alt_outlined,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(context)!.notes(
                                      subOrder['deliveryNotes'].toString(),
                                    ),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (subOrder['csNotes'] != null &&
                            (subOrder['csNotes'] as List).isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.support_agent_outlined,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(context)!.notes(
                                      (subOrder['csNotes'] as List).join('\n'),
                                    ),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (subOrder['assignedDate'] != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  AppLocalizations.of(context)!.assigned(
                                    _formatDate(subOrder['assignedDate']),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Row(
                          children: [
                            if (product['image'] != null &&
                                product['image'].toString().isNotEmpty)
                              Container(
                                width: 40,
                                height: 40,
                                margin: EdgeInsetsDirectional.only(end: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey.withValues(alpha: 0.1),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Image.network(
                                  product['image'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
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
                                  color: Colors.grey.withValues(alpha: 0.1),
                                ),
                                child: const Icon(
                                  Icons.inventory_2_outlined,
                                  color: Colors.grey,
                                ),
                              ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                      subOrder['quantity']?.toString() ?? '1',
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
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr.toString()).toLocal();
      final locale = Localizations.localeOf(context).languageCode;
      return DateFormat.yMMMd(locale).add_jm().format(dt);
    } catch (_) {
      return dateStr.toString().length > 10
          ? dateStr.toString().substring(0, 10)
          : dateStr.toString();
    }
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
                _batchMosqueInsideImage != null &&
                _batchPackagesImage != null;

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.uploadBatchImages,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.buttonBlueDark,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDottedImagePicker(
                          context,
                          label: AppLocalizations.of(context)!.mosqueFront,
                          path: _batchMosqueFrontImage,
                          onPick: (source) async {
                            debugPrint(
                              'Bulk Image Upload: Mosque front image picking started from source: $source',
                            );
                            final file = await _pickImageWithConstraints(context, source);
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
                            final file = await _pickImageWithConstraints(context, source);
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
                                setSheetState(() => _isBatchUploading = true);
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
                                  debugPrint(
                                    'Bulk Image Upload: Request Packages Image Path: $_batchPackagesImage',
                                  );
                                  // Not used for Auto Delivery, handled by ProofSubmissionPage
                                  // await _api.bulkUploadMosqueImages(
                                  //   orderId: widget.item.id,
                                  //   subOrderIds: _selectedSubOrders.toList(),
                                  //   mosqueFrontImagePath: _batchMosqueFrontImage!,
                                  //   mosqueInsideImagePath: _batchMosqueInsideImage!,
                                  // );

                                  Navigator.pop(context);

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProofSubmissionPage(
                                        isAutoOrder: false,
                                        isAutoDelivery: true,
                                        orderId: widget.item.id,
                                        product: widget.item.product,
                                        subOrders: _selectedSubOrders.toList(),
                                        initialMosqueFrontImage:
                                            _batchMosqueFrontImage,
                                        initialMosqueInsideImage:
                                            _batchMosqueInsideImage,
                                      ),
                                    ),
                                  ).then((_) {
                                    setState(() {
                                      _isMultiSelectMode = false;
                                      _selectedSubOrders.clear();
                                    });
                                    _fetchDetails();
                                  });
                                  debugPrint(
                                    'Bulk Image Upload: Response successful',
                                  );
                                  if (context.mounted) {
                                    CustomSnackbar.show(
                                      context: context,
                                      message:
                                          'Batch images uploaded successfully!',
                                    );
                                    Navigator.pop(context);
                                  }
                                  setState(() {
                                    _batchMosqueFrontImage = null;
                                    _batchMosqueInsideImage = null;
                                    _batchPackagesImage = null;
                                    _isMultiSelectMode = false;
                                    _selectedSubOrders.clear();
                                  });
                                  _fetchDetails();
                                } catch (e) {
                                  debugPrint(
                                    'Bulk Image Upload: Error occurred: $e',
                                  );
                                  if (context.mounted) {
                                    String errorMessage = AppLocalizations.of(
                                      context,
                                    )!.somethingWentWrong;
                                    if (e is DioException &&
                                        e.response?.data is Map &&
                                        e.response?.data['message'] != null) {
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
                                  setState(() => _isBatchUploading = false);
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
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.hardEdge,
                child: path != null
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
}
