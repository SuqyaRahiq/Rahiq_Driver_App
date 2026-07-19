import 'dart:async' show Timer;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rahiq_driver/data/models/driver/driver_auto_delivery.dart';
import 'package:rahiq_driver/data/models/driver/normal_sub_order.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:rahiq_driver/data/models/driver/product.dart';
import 'package:rahiq_driver/pages/shared/proof_submission_provider.dart';
import 'package:rahiq_driver/utils/colors.dart';
import 'package:rahiq_driver/utils/rtl_helpers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:video_player/video_player.dart';
import 'package:rahiq_driver/l10n/app_localizations.dart';
import 'package:rahiq_driver/utils/water_loading.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:rahiq_driver/data/api/api_client.dart';
import 'package:rahiq_driver/data/api/driver/driver_locations_api.dart';
import 'package:rahiq_driver/data/models/driver/locations_context_response.dart';

import 'package:rahiq_driver/common_widgets/custom_snackbar.dart';

class ProofSubmissionPage extends StatelessWidget {
  final String orderId;
  final bool isAutoOrder;
  final bool isAutoDelivery;
  final DriverAutoDelivery? autoDelivery;
  final List<String> subOrders;
  final Map<String, dynamic>? singleCustomerData;
  final NormalSubOrder? normalSubOrder;
  final String? initialMosqueFrontImage;
  final String? initialMosqueInsideImage;
  final String? orderType;
  final Product? product;
  final double? latitude;
  final double? longitude;

  const ProofSubmissionPage({
    super.key,
    required this.orderId,
    required this.isAutoOrder,
    this.autoDelivery,
    this.isAutoDelivery = false,
    required this.subOrders,
    this.singleCustomerData,
    this.normalSubOrder,
    this.initialMosqueFrontImage,
    this.product,
    this.initialMosqueInsideImage,
    this.orderType,
    this.latitude,
    this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    bool isAr = Directionality.of(context) == TextDirection.rtl;
    return ChangeNotifierProvider(
      create: (_) => ProofSubmissionProvider(
        orderId: orderId,
        isAutoOrder: isAutoOrder,
        isAutoDelivery: isAutoDelivery,
        subOrderIds: subOrders,
        initialMosqueFrontImage: initialMosqueFrontImage,
        initialMosqueInsideImage: initialMosqueInsideImage,
      ),
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: Consumer<ProofSubmissionProvider>(
          builder: (context, provider, child) {
            if (provider.isSubmitting) {
              return Stack(
                children: [
                  Positioned(
                    top: -100,
                    right: isAr ? null : -100,
                    left: isAr ? -100 : null,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.buttonBlueDark.withValues(alpha: 0.15),
                            Colors.transparent,
                          ],
                          stops: const [0.2, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 100,
                    right: isAr ? -100 : null,
                    left: isAr ? null : -100,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.buttonBlueDark.withValues(alpha: 0.15),
                            Colors.transparent,
                          ],
                          stops: const [0.2, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const WaterLoadingIndicator(size: 32),
                        const SizedBox(height: 16),
                        _CyclingStatusText(
                          messages: [
                            AppLocalizations.of(context)!.completingOrder,
                            AppLocalizations.of(context)!.uploadingImages,
                            AppLocalizations.of(context)!.uploadingVideo,
                            AppLocalizations.of(context)!.almostThere,
                          ],
                          style: const TextStyle(
                            color: AppColors.buttonBlueDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                children: [
                  // ── Header ──────────────────────────
                  Container(
                    width: double.infinity,
                    color: AppColors.buttonBlueDark,
                    child: SafeArea(
                      bottom: false,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                              16,
                              16,
                              16,
                              12,
                            ),
                            child: Center(
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.arrow_back_ios_new_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.submitDeliveryProof,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.uploadMediaToSupportDeliveryCompletion,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 38),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  // ── Rounded white body ────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(color: AppColors.buttonBlueDark),
                    child: Container(
                      width: double.infinity,
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height - 160,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!provider.isMultiSelect &&
                                singleCustomerData != null &&
                                !isAutoDelivery) ...[
                              _buildCustomerCard(context, singleCustomerData!),
                              const SizedBox(height: 12),
                            ],
                            if (isAutoDelivery) ...[
                              _buildAutoDeliveryCard(context, autoDelivery!),
                              const SizedBox(height: 12),
                            ],

                            ...provider.proofs.map((proof) {
                              return _buildSubOrderSection(
                                context,
                                provider,
                                proof,
                              );
                            }),

                            Container(
                              color: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 55,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      try {
                                        await provider.submitProofs();
                                        if (context.mounted) {
                                          CustomSnackbar.show(
                                            context: context,
                                            message: AppLocalizations.of(
                                              context,
                                            )!.proofsUploaded,
                                          );
                                          Navigator.pop(context, true);
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          String errorMessage =
                                              AppLocalizations.of(
                                                context,
                                              )!.somethingWentWrong;
                                          if (e.toString().contains(
                                            'missing_media',
                                          )) {
                                            errorMessage = AppLocalizations.of(
                                              context,
                                            )!.missingMediaError;
                                          } else if (e is DioException &&
                                              e.response?.data is Map &&
                                              e.response?.data['message'] !=
                                                  null) {
                                            errorMessage =
                                                e.response!.data['message'];
                                          }
                                          CustomSnackbar.show(
                                            context: context,
                                            message: errorMessage,
                                            isError: true,
                                          );
                                        }
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.buttonBlueDark,
                                      disabledBackgroundColor: Colors.grey[300],
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      fixedSize: const Size(
                                        double.infinity,
                                        50,
                                      ),
                                    ),
                                    child: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.completeOrder,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildAutoDeliveryCard(
    BuildContext context,
    DriverAutoDelivery order,
  ) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.all(0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.circular(20),
      ),
      color: Colors.white,
      child: Padding(
        padding: EdgeInsetsGeometry.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${AppLocalizations.of(context)!.batch_Number}: ${order.batchNumber}",
            ),
            const SizedBox(height: 6),
            Divider(),
            SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.packages,
                      style: TextStyle(color: AppColors.grey, fontSize: 13),
                    ),
                    SizedBox(height: 3),
                    Text(
                      "${autoDelivery!.quantity} ${isRtl(context) ? autoDelivery!.product!.nameAr : autoDelivery!.product!.name}",
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.orders,
                      style: TextStyle(color: AppColors.grey, fontSize: 13),
                    ),
                    SizedBox(height: 3),
                    Text(
                      "${autoDelivery!.orderCount} ${AppLocalizations.of(context)!.orders}",
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 2),
              ],
            ),
            SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.locationLabel,
              style: TextStyle(color: AppColors.grey, fontSize: 13),
            ),
            SizedBox(height: 3),
            Text(
              "${isRtl(context) ? autoDelivery!.deliveryLocation!.campaign!.titleAr : autoDelivery!.deliveryLocation!.campaign!.title} ",
              style: TextStyle(
                fontSize: 14,
                color: AppColors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.buttonBlueDark,
        ),
      ),
    );
  }

  Widget _buildSubOrderSection(
    BuildContext context,
    ProofSubmissionProvider provider,
    SubOrderProof proof,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProofImagesSection(provider, context, proof),
        const SizedBox(height: 16),
        if (!isAutoDelivery && !isAutoOrder) ...[
          _buildNotDeliveredSection(context, provider, proof),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildNotDeliveredSection(
    BuildContext context,
    ProofSubmissionProvider provider,
    SubOrderProof proof,
  ) {
    return Card(
      elevation: 3,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(AppLocalizations.of(context)!.delivery_location),

            const SizedBox(height: 12),
            _buildRadioOption(
              title: AppLocalizations.of(context)!.delivered_to_target_location,
              isSelected: !proof.deliveredToDifferentMosque,
              onTap: () {
                proof.deliveredToDifferentMosque = false;
                proof.differentMosqueReason = null;
                provider.updateUI();
              },
            ),
            const SizedBox(height: 12),
            _buildRadioOption(
              title: AppLocalizations.of(context)!.not_delivered,
              isSelected: proof.deliveredToDifferentMosque,
              onTap: () {
                _showReasonBottomSheet(context, provider, proof);
              },
            ),
            if (proof.deliveredToDifferentMosque) ...[
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4, left: 4),
                child: Text(
                  '${AppLocalizations.of(context)!.reason_for_not_delivered} : ${proof.differentMosqueReason ?? AppLocalizations.of(context)!.no_reason_selected}.',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.buttonBlueDark,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Divider(color: Colors.grey, thickness: 1),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.select_delivered_location,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.buttonBlueDark,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.buttonBlueDark),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: proof.deliveredLocationName != null
                        ? AppColors.buttonBlueDark
                        : Colors.white,
                  ),
                  onPressed: () async {
                    try {
                      provider.setLoadingLocations(proof.subOrderId, true);
                      final locationsApi = DriverLocationsApi(ApiClient());
                      final locationsResponse = await locationsApi
                          .getSubOrderLocationsContext(
                            subOrderId: proof.subOrderId,
                            page: 1,
                            limit: 30,
                          );

                      if (!context.mounted) {
                        provider.setLoadingLocations(proof.subOrderId, false);
                        return;
                      }

                      if (locationsResponse.data.items.isEmpty) {
                        provider.setLoadingLocations(proof.subOrderId, false);
                        CustomSnackbar.show(
                          context: context,
                          message: AppLocalizations.of(
                            context,
                          )!.no_locations_available,
                          isError: true,
                        );
                        return;
                      }

                      _showLocationsBottomSheet(
                        context,
                        provider,
                        proof,
                        locationsResponse,
                      );
                      provider.setLoadingLocations(proof.subOrderId, false);
                    } catch (e) {
                      print('[LocationsContext] Error: $e');
                      provider.setLoadingLocations(proof.subOrderId, false);
                      if (context.mounted) {
                        CustomSnackbar.show(
                          context: context,
                          message: AppLocalizations.of(
                            context,
                          )!.failed_to_load_locations,
                          isError: true,
                        );
                      }
                    }
                  },

                  child: proof.isLoadingLocations
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: WaterLoadingIndicator(
                            waveColor1: proof.deliveredLocationName != null
                                ? Colors.white
                                : AppColors.buttonBlueDark,
                          ),
                        )
                      : Text(
                          proof.deliveredLocationName ??
                              AppLocalizations.of(context)!.selectNewLocation,
                          style: TextStyle(
                            color: proof.deliveredLocationName != null
                                ? Colors.white
                                : AppColors.buttonBlueDark,
                          ),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showReasonBottomSheet(
    BuildContext context,
    ProofSubmissionProvider provider,
    SubOrderProof proof,
  ) async {
    final reasonsEn = [
      "Mosque is under construction",
      "Mosque has been removed",
      "Mosque refused to accept water",
      "Mosque did not need the water",
      "Mosque was in a secuirity facility",
    ];
    final reasonsAr = [
      "المسجد تحت الإنشاء",
      "تم إزالة المسجد",
      "رفض المسجد استلام المياه",
      "المسجد لا يحتاج إلى المياه",
      "المسجد داخل منشأة أمنية",
    ];

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                        AppLocalizations.of(context)!.reason_for_not_delivered,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 42),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (Directionality.of(context) == TextDirection.ltr) ...{
                ...reasonsEn.map(
                  (reason) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: InkWell(
                      onTap: () => Navigator.pop(context, reason),
                      child: Card(
                        margin: EdgeInsets.all(0),
                        elevation: 2,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  reason,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              },
              if (Directionality.of(context) == TextDirection.rtl) ...{
                ...reasonsAr.map(
                  (reason) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: InkWell(
                      onTap: () => Navigator.pop(context, reason),
                      child: Card(
                        margin: EdgeInsets.all(0),
                        elevation: 2,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  reason,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              },

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      proof.deliveredToDifferentMosque = true;
      proof.differentMosqueReason = selected;
      provider.updateUI();
    } else {
      if (proof.differentMosqueReason == null) {
        proof.deliveredToDifferentMosque = true;
        provider.updateUI();
      }
    }
  }

  Widget _buildRadioOption({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.buttonBlueDark : Colors.grey,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.buttonBlueDark : Colors.black87,
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.buttonBlueDark,
                size: 20,
              )
            else
              const Icon(
                Icons.radio_button_unchecked,
                color: Color(0xFFEAEFF2),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProofImagesSection(
    ProofSubmissionProvider provider,
    BuildContext context,
    SubOrderProof proof,
  ) {
    return Card(
      elevation: 3,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSectionTitle(
              (orderType?.toLowerCase() == 'orphanage' ||
                      orderType?.toLowerCase() == 'orphanages')
                  ? AppLocalizations.of(context)!.orphanage_photos
                  : (orderType?.toLowerCase() == 'graveyard' ||
                        orderType?.toLowerCase() == 'graveyards')
                  ? AppLocalizations.of(context)!.graveyard_photos
                  : AppLocalizations.of(context)!.mosque_photos,
            ),
            SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDottedImagePicker(
                  context,
                  label:
                      (orderType?.toLowerCase() == 'orphanage' ||
                          orderType?.toLowerCase() == 'orphanages')
                      ? AppLocalizations.of(context)!.orphanageFront
                      : (orderType?.toLowerCase() == 'graveyard' ||
                            orderType?.toLowerCase() == 'graveyards')
                      ? AppLocalizations.of(context)!.graveyardFront
                      : AppLocalizations.of(context)!.mosqueFront,
                  path: proof.mosqueFrontImage,
                  onPick: (source) => provider.pickSubOrderImage(
                    proof.subOrderId,
                    'front',
                    source,
                  ),
                ),
                const SizedBox(width: 16),
                _buildDottedImagePicker(
                  context,
                  label:
                      (orderType?.toLowerCase() == 'orphanage' ||
                          orderType?.toLowerCase() == 'orphanages')
                      ? AppLocalizations.of(context)!.orphanageInsideImage
                      : (orderType?.toLowerCase() == 'graveyard' ||
                            orderType?.toLowerCase() == 'graveyards')
                      ? AppLocalizations.of(context)!.graveyardInsideImage
                      : AppLocalizations.of(context)!.mosqueInsideImage,
                  path: proof.mosqueInsideImage,
                  onPick: (source) => provider.pickSubOrderImage(
                    proof.subOrderId,
                    'inside',
                    source,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSectionTitle(
              AppLocalizations.of(context)!.order_photos_and_video,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDottedImagePicker(
                  context,
                  label: AppLocalizations.of(context)!.productPlaced,
                  path: proof.packagesImage,
                  onPick: (source) => provider.pickSubOrderImage(
                    proof.subOrderId,
                    'package',
                    source,
                  ),
                ),
                const SizedBox(width: 16),
                _buildDottedImagePicker(
                  context,
                  label:
                      (orderType?.toLowerCase() == 'orphanage' ||
                          orderType?.toLowerCase() == 'orphanages')
                      ? AppLocalizations.of(context)!.productInsideOrphanage
                      : (orderType?.toLowerCase() == 'graveyard' ||
                            orderType?.toLowerCase() == 'graveyards')
                      ? AppLocalizations.of(context)!.productInsideGraveyard
                      : AppLocalizations.of(context)!.productInsideMosque,
                  path: proof.proofVideo,
                  isVideo: true,
                  onPick: (source) => provider.pickSubOrderVideo(
                    context,
                    proof.subOrderId,
                    source,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDottedImagePicker(
    BuildContext context, {
    required String label,
    required String? path,
    required Function(ImageSource) onPick,
    bool isVideo = false,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _showSourceBottomSheet(context, onPick, isVideo: isVideo),
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
                padding: EdgeInsets.all(10),
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.hardEdge,
                child: path != null
                    ? (isVideo
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: VideoThumbnailWidget(path: path),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: path.startsWith('http')
                                  ? CachedNetworkImage(
                                      imageUrl: path,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          Shimmer.fromColors(
                                            baseColor: Colors.grey[300]!,
                                            highlightColor: Colors.grey[100]!,
                                            child: Container(
                                              color: Colors.white,
                                            ),
                                          ),
                                    )
                                  : Image.file(File(path), fit: BoxFit.cover),
                            ))
                    : Center(
                        child: Icon(
                          isVideo
                              ? Icons.videocam_outlined
                              : Icons.image_outlined,
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

  void _showLocationsBottomSheet(
    BuildContext context,
    ProofSubmissionProvider provider,
    SubOrderProof proof,
    LocationsContextResponse initialResponse,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => LocationsBottomSheetContent(
        context: sheetContext,
        provider: provider,
        proof: proof,
        initialResponse: initialResponse,
      ),
    );
  }

  void _showSourceBottomSheet(
    BuildContext parentContext,
    Function(ImageSource) onPick, {
    bool isVideo = false,
  }) {
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
                  SizedBox(width: 8),
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
                        if (isVideo)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  color: Colors.orange,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(
                                      sheetContext,
                                    )!.videoDurationLimitNote,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        _buildBottomSheetTile(
                          icon: Icons.camera_alt,
                          title: isVideo
                              ? AppLocalizations.of(sheetContext)!.takeAVideo
                              : AppLocalizations.of(sheetContext)!.takeAPhoto,
                          onTap: () async {
                            Navigator.pop(sheetContext);
                            final error = await onPick(ImageSource.camera);
                            if (error != null &&
                                error is String &&
                                parentContext.mounted) {
                              final errorMsg = error == 'video_too_long'
                                  ? AppLocalizations.of(
                                      parentContext,
                                    )!.videoDurationLimitError
                                  : error;
                              CustomSnackbar.show(
                                context: parentContext,
                                message: errorMsg,
                                isError: true,
                              );
                            }
                          },
                        ),
                        const Divider(height: 1, color: Color(0xFFEAEFF2)),
                        _buildBottomSheetTile(
                          icon: Icons.photo_library,
                          title: AppLocalizations.of(
                            sheetContext,
                          )!.chooseFromGallery,
                          onTap: () async {
                            Navigator.pop(sheetContext);
                            final error = await onPick(ImageSource.gallery);
                            if (error != null &&
                                error is String &&
                                parentContext.mounted) {
                              final errorMsg = error == 'video_too_long'
                                  ? AppLocalizations.of(
                                      parentContext,
                                    )!.videoDurationLimitError
                                  : error;
                              CustomSnackbar.show(
                                context: parentContext,
                                message: errorMsg,
                                isError: true,
                              );
                            }
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

  Widget _buildCustomerCard(
    BuildContext context,
    Map<String, dynamic> customer,
  ) {
    final normalSub = normalSubOrder;

    final firstName =
        normalSub?.customerDetails?.firstName ?? customer['firstName'] ?? '';
    final lastName =
        normalSub?.customerDetails?.lastName ?? customer['lastName'] ?? '';
    final name = '$firstName $lastName'.trim();
    final subOrderNumber =
        normalSub?.subOrderNumber ?? customer['subOrderNumber'] ?? "";
    final phoneNumber =
        normalSub?.customerDetails?.phoneNumber ?? customer['phoneNumber'];
    final countryCode =
        normalSub?.customerDetails?.countryCode ??
        customer['countryCode'] ??
        '';
    final quantity = normalSub?.quantity ?? customer['quantity'];
    final orderedDate = customer['orderedDate'];

    String formatDate(dynamic dateStr) {
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

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.buttonBlueDark.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    subOrderNumber,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEF1F4)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (name.isNotEmpty) ...[
                  Text(
                    AppLocalizations.of(context)!.customer_name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (phoneNumber != null &&
                            phoneNumber.toString().isNotEmpty) ...[
                          Text(
                            AppLocalizations.of(context)!.phoneNumber,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              '$countryCode$phoneNumber',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (quantity != null) ...[
                          Text(
                            AppLocalizations.of(context)!.quantity,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            Directionality.of(context) == TextDirection.ltr
                                ? "$quantity ${product?.name ?? ''}"
                                : "$quantity ${product?.nameAr ?? ''}",

                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),

                if (orderedDate != null) ...[
                  const SizedBox(height: 12),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      AppLocalizations.of(context)!.date,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Text(
                    formatDate(orderedDate),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (latitude != null && longitude != null) ...[
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.locationLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _LocationLinkWidget(
                        latitude: latitude!,
                        longitude: longitude!,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                if (phoneNumber != null &&
                    phoneNumber.toString().isNotEmpty) ...{
                  Text(
                    AppLocalizations.of(context)!.contact_customer,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Material(
                        elevation: 3,
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            if (phoneNumber != null &&
                                phoneNumber.toString().isNotEmpty) {
                              final number = '$countryCode$phoneNumber'
                                  .replaceAll('+', '');
                              launchUrl(
                                Uri.parse('https://wa.me/$number'),
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            height: 45,
                            width: 45,
                            child: Image.asset("assets/whatsapp.png"),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Material(
                        elevation: 3,
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            if (phoneNumber != null &&
                                phoneNumber.toString().isNotEmpty) {
                              final number = '$countryCode$phoneNumber';
                              launchUrl(Uri.parse('sms:$number'));
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            height: 45,
                            width: 45,
                            child: const Icon(CupertinoIcons.text_bubble),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Material(
                        elevation: 3,
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            if (phoneNumber != null &&
                                phoneNumber.toString().isNotEmpty) {
                              final number = '$countryCode$phoneNumber';
                              launchUrl(Uri.parse('tel:$number'));
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            height: 45,
                            width: 45,
                            child: const Icon(CupertinoIcons.phone),
                          ),
                        ),
                      ),
                    ],
                  ),
                },
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LocationsBottomSheetContent extends StatefulWidget {
  final BuildContext context;
  final ProofSubmissionProvider provider;
  final SubOrderProof proof;
  final LocationsContextResponse initialResponse;

  const LocationsBottomSheetContent({
    required this.context,
    required this.provider,
    required this.proof,
    required this.initialResponse,
    super.key,
  });

  @override
  State<LocationsBottomSheetContent> createState() =>
      _LocationsBottomSheetContentState();
}

class _LocationsBottomSheetContentState
    extends State<LocationsBottomSheetContent> {
  late LocationsContextResponse _currentResponse;
  late ScrollController _scrollController;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _currentResponse = widget.initialResponse;
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadNextPage();
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoadingMore) return;
    if (_currentResponse.data.meta.page >=
        _currentResponse.data.meta.totalPages) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final locationsApi = DriverLocationsApi(ApiClient());
      final nextPage = _currentResponse.data.meta.page + 1;
      final response = await locationsApi.getSubOrderLocationsContext(
        subOrderId: widget.proof.subOrderId,
        page: nextPage,
        limit: 30,
      );

      setState(() {
        _currentResponse = LocationsContextResponse(
          success: response.success,
          message: response.message,
          data: LocationsContextData(
            items: [..._currentResponse.data.items, ...response.data.items],
            meta: response.data.meta,
          ),
        );
        _isLoadingMore = false;
      });
    } catch (e) {
      print('Error loading next page: $e');
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
                const Expanded(
                  child: Text(
                    'Select Delivery Location',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 42),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(color: AppColors.buttonBlueDark),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  itemCount:
                      _currentResponse.data.items.length +
                      (_isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _currentResponse.data.items.length) {
                      return Column(
                        children: List.generate(3, (itemIndex) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Card(
                              margin: EdgeInsets.zero,
                              elevation: 2,
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Shimmer.fromColors(
                                      baseColor: Colors.grey[300]!,
                                      highlightColor: Colors.grey[100]!,
                                      child: Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Shimmer.fromColors(
                                            baseColor: Colors.grey[300]!,
                                            highlightColor: Colors.grey[100]!,
                                            child: Container(
                                              height: 16,
                                              width: double.infinity,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Shimmer.fromColors(
                                            baseColor: Colors.grey[300]!,
                                            highlightColor: Colors.grey[100]!,
                                            child: Container(
                                              height: 12,
                                              width: double.infinity,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Shimmer.fromColors(
                                            baseColor: Colors.grey[300]!,
                                            highlightColor: Colors.grey[100]!,
                                            child: Container(
                                              height: 12,
                                              width: 120,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Shimmer.fromColors(
                                      baseColor: Colors.grey[300]!,
                                      highlightColor: Colors.grey[100]!,
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      );
                    }

                    final location = _currentResponse.data.items[index];
                    final isArabic =
                        Localizations.localeOf(context).languageCode == 'ar';
                    final displayName = isArabic
                        ? location.nameAr
                        : location.name;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          widget.proof.deliveredLocationId = location.id;
                          widget.proof.deliveredLocationName = displayName;
                          widget.provider.updateUI();
                          Navigator.pop(context);
                        },
                        child: Card(
                          margin: EdgeInsets.zero,
                          elevation: 2,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey[200],
                                        child:
                                            location.image != null &&
                                                location.image!.isNotEmpty
                                            ? CachedNetworkImage(
                                                imageUrl: location.image!,
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
                                                    ) => const Center(
                                                      child: Icon(
                                                        Icons
                                                            .location_on_outlined,
                                                        color: AppColors
                                                            .buttonBlueDark,
                                                        size: 32,
                                                      ),
                                                    ),
                                              )
                                            : const Center(
                                                child: Icon(
                                                  Icons.location_on_outlined,
                                                  color:
                                                      AppColors.buttonBlueDark,
                                                  size: 32,
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            displayName,
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            location.address,
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '${location.zone.name} - ${location.zone.city.name}',
                                            style: const TextStyle(
                                              color: AppColors.buttonBlueDark,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Colors.black54,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class VideoThumbnailWidget extends StatefulWidget {
  final String path;

  const VideoThumbnailWidget({super.key, required this.path});

  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  void _initializeController() {
    _controller = widget.path.startsWith('http')
        ? VideoPlayerController.networkUrl(Uri.parse(widget.path))
        : VideoPlayerController.file(File(widget.path));

    _controller.initialize().then((_) {
      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  @override
  void didUpdateWidget(VideoThumbnailWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.path != oldWidget.path) {
      _initialized = false;
      _controller.dispose();
      _initializeController();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Center(
        child: SizedBox(
          height: 24,
          width: 24,
          child: WaterLoadingIndicator(size: 24),
        ),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller.value.size.width,
            height: _controller.value.size.height,
            child: VideoPlayer(_controller),
          ),
        ),
        Center(
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 24),
          ),
        ),
      ],
    );
  }
}

class _LocationLinkWidget extends StatefulWidget {
  final double latitude;
  final double longitude;

  const _LocationLinkWidget({required this.latitude, required this.longitude});

  @override
  State<_LocationLinkWidget> createState() => _LocationLinkWidgetState();
}

class _LocationLinkWidgetState extends State<_LocationLinkWidget> {
  Future<String>? _addressFuture;

  @override
  void initState() {
    super.initState();
    _fetchAddress();
  }

  @override
  void didUpdateWidget(_LocationLinkWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude) {
      _fetchAddress();
    }
  }

  void _fetchAddress() {
    _addressFuture = geocoding.Geocoding()
        .placemarkFromCoordinates(widget.latitude, widget.longitude)
        .then((placemarks) {
          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            return [
              place.street,
              place.subLocality,
              place.locality,
              place.administrativeArea,
              place.country,
            ].where((e) => e != null && e.isNotEmpty).join(', ');
          }
          return "${widget.latitude}, ${widget.longitude}";
        })
        .catchError((_) => "${widget.latitude}, ${widget.longitude}");
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _addressFuture,
      builder: (context, snapshot) {
        String displayText = "${widget.latitude}, ${widget.longitude}";
        if (snapshot.connectionState == ConnectionState.waiting) {
          displayText = "...";
        } else if (snapshot.hasData) {
          displayText = snapshot.data!;
        }

        return GestureDetector(
          onTap: () async {
            final url =
                'https://www.google.com/maps/search/?api=1&query=${widget.latitude},${widget.longitude}';
            if (await canLaunchUrl(Uri.parse(url))) {
              await launchUrl(
                Uri.parse(url),
                mode: LaunchMode.externalApplication,
              );
            }
          },
          child: Text(
            displayText,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.buttonBlueDark,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.buttonBlueDark,
            ),
          ),
        );
      },
    );
  }
}

class _CyclingStatusText extends StatefulWidget {
  final List<String> messages;
  final TextStyle? style;

  const _CyclingStatusText({required this.messages, this.style});

  @override
  State<_CyclingStatusText> createState() => _CyclingStatusTextState();
}

class _CyclingStatusTextState extends State<_CyclingStatusText> {
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
      if (!mounted) return;
      setState(() {
        _index = (_index + 1) % widget.messages.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: Text(
        widget.messages[_index],
        key: ValueKey<int>(_index),
        style: widget.style,
        textAlign: TextAlign.center,
      ),
    );
  }
}
