import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:rahiq_driver/data/api/api_client.dart';
import 'package:rahiq_driver/data/api/driver/driver_orders_api.dart';
import 'package:rahiq_driver/data/models/driver/auto_order_item.dart';
import 'package:rahiq_driver/pages/shared/proof_submission_page.dart';
import 'package:rahiq_driver/utils/colors.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:dio/dio.dart';
import 'package:rahiq_driver/l10n/app_localizations.dart';
import 'package:rahiq_driver/utils/shimmer_loading.dart';
import 'package:rahiq_driver/common_widgets/custom_snackbar.dart';
import 'package:rahiq_driver/utils/water_loading.dart';

class AutoOrderDetailsPage extends StatefulWidget {
  final AutoOrderItem item;

  const AutoOrderDetailsPage({super.key, required this.item});

  @override
  State<AutoOrderDetailsPage> createState() => _AutoOrderDetailsPageState();
}

class _AutoOrderDetailsPageState extends State<AutoOrderDetailsPage> {
  late DriverOrdersApi _api;
  bool _isLoading = true;
  String? _error;
  List<dynamic> _subOrders = [];
  bool _isMultiSelectMode = false;
  final Set<String> _selectedSubOrders = {};

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

  Future<void> _fetchDetails() async {
    try {
      final details = await _api.getAutoOrderDetails(
        widget.item.id,
        widget.item.type,
      );
      setState(() {
        _subOrders = details;
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
    if (_subOrders.isNotEmpty) {
      final first = _subOrders.first;
      final cust = first['customerDetails'] ?? {};
      return (first['latitude'] ?? cust['latitude'] ?? 0.0).toDouble();
    }
    return 0.0;
  }

  double _getLongitude() {
    if (_subOrders.isNotEmpty) {
      final first = _subOrders.first;
      final cust = first['customerDetails'] ?? {};
      return (first['longitude'] ?? cust['longitude'] ?? 0.0).toDouble();
    }
    return 0.0;
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
                          widget.item.name,
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
                // ── Map Area ────────────────────────────────────────────────────
                if (_getLatitude() != 0.0 && _getLongitude() != 0.0)
                  _buildMapHeader(context),
                // ── Rounded white body ─────────────────────────────────────────
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
                        ? const Padding(
                            padding: EdgeInsets.only(top: 24.0),
                            child: FullPageShimmerLoader(),
                          )
                        : Padding(
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

                                // ── Category card ────────────────────────────────────
                                _buildCategoryCard(),

                                const SizedBox(height: 16),

                                if (_subOrders.isNotEmpty)
                                  _buildSubOrdersSection(),

                                const Spacer(),
                                const SizedBox(height: 24),

                                // ── Submit proof button ──────────────────────────────
                                if (_isMultiSelectMode &&
                                    _selectedSubOrders.isNotEmpty)
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        if (_selectedSubOrders.length == 1) {
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
                                              subOrder['customerDetails'] ?? {};
                                          final address =
                                              subOrder['deliveryAddress'] ??
                                              customer['address'];

                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ProofSubmissionPage(
                                                isAutoOrder: true,
                                                orderId: widget.item.id,
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
                                          _showBatchImagesBottomSheet(context);
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
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
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

  Widget _buildMapHeader(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.65;
    final lat = _getLatitude();
    final lng = _getLongitude();
    final target = LatLng(lat, lng);

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: target, zoom: 15),
            markers: {
              Marker(markerId: const MarkerId('dest'), position: target),
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          PositionedDirectional(
            bottom: 30, // space for the sheet overlap
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

  Widget _buildCategoryCard() {
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
              child: widget.item.image != null
                  ? Image.network(
                      widget.item.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.mosque_rounded,
                        color: AppColors.buttonBlueDark,
                        size: 32,
                      ),
                    )
                  : const Icon(
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
                    widget.item.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  if (widget.item.nameAr.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.item.nameAr,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black45,
                      ),
                    ),
                  ],
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
          padding: EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            AppLocalizations.of(context)!.batchDeliveries,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
        ..._subOrders.map((subOrder) {
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
                        isAutoOrder: true,
                        orderId: widget.item.id,
                        subOrders: [subId],
                        singleCustomerData: {
                          'firstName': customer['firstName'],
                          'lastName': customer['lastName'],
                          'phoneNumber': customer['phoneNumber'],
                          'address': address,
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
                                margin: const EdgeInsets.only(right: 12),
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
                                    product['name'] ??
                                        AppLocalizations.of(context)!.product,
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
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr.toString().length > 10
          ? dateStr.toString().substring(0, 10)
          : dateStr.toString();
    }
  }

  void _showBatchImagesBottomSheet(BuildContext context) {
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
                            final file = await _picker.pickImage(
                              source: source,
                            );
                            if (file != null) {
                              setSheetState(
                                () => _batchMosqueFrontImage = file.path,
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
                            final file = await _picker.pickImage(
                              source: source,
                            );
                            if (file != null) {
                              setSheetState(
                                () => _batchMosqueInsideImage = file.path,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: canSave && !_isBatchUploading
                            ? () async {
                                setSheetState(() => _isBatchUploading = true);
                                setState(() => _isBatchUploading = true);
                                try {
                                  await _api.bulkUploadMosqueImages(
                                    orderId: widget.item.id,
                                    subOrderIds: _selectedSubOrders.toList(),
                                    mosqueFrontImagePath:
                                        _batchMosqueFrontImage!,
                                    mosqueInsideImagePath:
                                        _batchMosqueInsideImage!,
                                  );
                                  if (context.mounted) {
                                    CustomSnackbar.show(
                                      context: context,
                                      message: 'Batch images uploaded successfully!',
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
                                  if (context.mounted) {
                                    String errorMessage = e.toString();
                                    if (e is DioException &&
                                        e.response?.data is Map &&
                                        e.response?.data['message'] != null) {
                                      errorMessage =
                                          e.response!.data['message'];
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
    BuildContext context,
    Function(ImageSource) onPick,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(AppLocalizations.of(context)!.takeAPhoto),
              onTap: () {
                Navigator.pop(context);
                onPick(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(AppLocalizations.of(context)!.chooseFromGallery),
              onTap: () {
                Navigator.pop(context);
                onPick(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}
