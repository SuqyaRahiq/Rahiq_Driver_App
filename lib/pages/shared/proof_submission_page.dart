import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rahiq_driver/data/models/driver/normal_sub_order.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:rahiq_driver/data/models/driver/product.dart';
import 'package:rahiq_driver/pages/shared/proof_submission_provider.dart';
import 'package:rahiq_driver/utils/colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:video_player/video_player.dart';
import 'package:rahiq_driver/l10n/app_localizations.dart';
import 'package:rahiq_driver/utils/water_loading.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geocoding/geocoding.dart';

import 'package:rahiq_driver/common_widgets/custom_snackbar.dart';
import 'package:rahiq_driver/data/models/driver/place.dart';
import 'package:rahiq_driver/pages/shared/driver_specific_mosque_page.dart'
    as import_page;

class ProofSubmissionPage extends StatelessWidget {
  final String orderId;
  final bool isAutoOrder;
  final bool isAutoDelivery;
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
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const WaterLoadingIndicator(size: 30),
                    SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.completingOrder,
                      style: const TextStyle(color: AppColors.buttonBlueDark),
                    ),
                  ],
                ),
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
                                singleCustomerData != null) ...[
                              _buildCustomerCard(context, singleCustomerData!),
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
                                    onPressed: provider.canSubmit
                                        ? () async {
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
                                                  errorMessage =
                                                      AppLocalizations.of(
                                                        context,
                                                      )!.missingMediaError;
                                                } else if (e is DioException &&
                                                    e.response?.data is Map &&
                                                    e
                                                            .response
                                                            ?.data['message'] !=
                                                        null) {
                                                  errorMessage = e
                                                      .response!
                                                      .data['message'];
                                                }
                                                CustomSnackbar.show(
                                                  context: context,
                                                  message: errorMessage,
                                                  isError: true,
                                                );
                                              }
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
                                      fixedSize: const Size(
                                        double.infinity,
                                        50,
                                      ),
                                    ),
                                    child: Text(
                                      provider.isMultiSelect
                                          ? AppLocalizations.of(
                                              context,
                                            )!.completeOrders
                                          : AppLocalizations.of(
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
        _buildNotDeliveredSection(context, provider, proof),
        const SizedBox(height: 16),
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
            _buildSectionTitle('Delivery Location'),

            const SizedBox(height: 12),
            _buildRadioOption(
              title: 'Delivered to target location',
              isSelected: !proof.deliveredToDifferentMosque,
              onTap: () {
                proof.deliveredToDifferentMosque = false;
                proof.differentMosqueReason = null;
                provider.updateUI();
              },
            ),
            const SizedBox(height: 12),
            _buildRadioOption(
              title: 'Not Delivered',
              isSelected: proof.deliveredToDifferentMosque,
              onTap: () {
                _showReasonBottomSheet(context, provider, proof);
              },
            ),
            if (proof.deliveredToDifferentMosque) ...[
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4, left: 4),
                child: Text(
                  'Reason for not delivered : ${proof.differentMosqueReason ?? 'no reason selected'}.',
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
                "Select the location you delivered to (Optional)",
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
                    final String? category = await showModalBottomSheet<String>(
                      backgroundColor: Colors.white,
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
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
                                  children: [
                                    GestureDetector(
                                      onTap: () => Navigator.pop(context),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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
                                      AppLocalizations.of(
                                        context,
                                      )!.select_category,
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
                              const SizedBox(height: 4),

                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Material(
                                  elevation: 2,
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  child: ListTile(
                                    title: Text(
                                      AppLocalizations.of(context)!.orphanage,
                                    ),
                                    onTap: () =>
                                        Navigator.pop(context, 'orphanages'),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Material(
                                  elevation: 2,
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  child: ListTile(
                                    title: Text(
                                      AppLocalizations.of(context)!.mosque,
                                    ),
                                    onTap: () =>
                                        Navigator.pop(context, 'mosques'),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Material(
                                  elevation: 2,
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  child: ListTile(
                                    title: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.meqat_mosque,
                                    ),
                                    onTap: () =>
                                        Navigator.pop(context, 'meqat_mosques'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );

                    if (category == null) return;

                    if (!context.mounted) return;

                    final Place? selected = await Navigator.push<Place>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => import_page.SpecificMosquePage(
                          slug: category,
                          title: AppLocalizations.of(context)!.locationLabel,
                        ),
                      ),
                    );
                    if (selected != null) {
                      proof.deliveredLocationId = selected.id;
                      proof.deliveredLocationName = selected.localizedName(
                        Localizations.localeOf(context).languageCode == 'ar',
                      );
                      provider.updateUI();
                    }
                  },
                  child: Text(
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
    final reasons = [
      "Mosque is under construction",
      "Mosque has been removed",
      "Mosque refused to accept water",
      "Mosque did not need the water",
      "Mosque was in a secuirity facility",
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
                        'Reason for not delivered',
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
              const SizedBox(height: 16),
              ...reasons.map(
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
                  label: (orderType?.toLowerCase() == 'orphanage' ||
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
                const SizedBox(width: 12),
                _buildDottedImagePicker(
                  context,
                  label: (orderType?.toLowerCase() == 'orphanage' ||
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
                const SizedBox(width: 12),
                _buildDottedImagePicker(
                  context,
                  label: (orderType?.toLowerCase() == 'orphanage' ||
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
                          Text(
                            '$countryCode$phoneNumber',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
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
    _addressFuture = Geocoding()
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
