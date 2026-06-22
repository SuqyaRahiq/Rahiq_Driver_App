import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:rahiq_driver/pages/shared/proof_submission_provider.dart';
import 'package:rahiq_driver/utils/colors.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:rahiq_driver/l10n/app_localizations.dart';

class ProofSubmissionPage extends StatelessWidget {
  final String orderId;
  final bool isAutoOrder;
  final List<String> subOrders;
  final Map<String, dynamic>? singleCustomerData;
  final String? initialMosqueFrontImage;
  final String? initialMosqueInsideImage;

  const ProofSubmissionPage({
    super.key,
    required this.orderId,
    required this.isAutoOrder,
    required this.subOrders,
    this.singleCustomerData,
    this.initialMosqueFrontImage,
    this.initialMosqueInsideImage,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProofSubmissionProvider(
        orderId: orderId,
        isAutoOrder: isAutoOrder,
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
                    CircularProgressIndicator(color: AppColors.buttonBlueDark),
                    SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.uploadingProof,
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
                              0,
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
                          horizontal: 24,
                          vertical: 24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!provider.isMultiSelect && singleCustomerData != null) ...[
                              _buildCustomerCard(context, singleCustomerData!),
                              const SizedBox(height: 24),
                            ],

                            if (provider.useSameImages) ...[
                              _buildSectionTitle(
                                AppLocalizations.of(
                                  context,
                                )!.imagesInstructions,
                              ),
                              _buildGlobalImagesPicker(context, provider),
                              const SizedBox(height: 24),
                              _buildSectionTitle(
                                AppLocalizations.of(context)!.video,
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildDottedImagePicker(
                                    context,
                                    label: AppLocalizations.of(context)!.productInsideMosque,
                                    path: provider.globalProofVideo,
                                    isVideo: true,
                                    onPick: (source) => provider.pickGlobalVideo(source),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(child: SizedBox()),
                                  const SizedBox(width: 12),
                                  const Expanded(child: SizedBox()),
                                ],
                              ),
                            ] else ...[
                              _buildSectionTitle(
                                AppLocalizations.of(context)!.video,
                              ),
                              ...provider.proofs.map((proof) {
                                return _buildSubOrderSection(
                                  context,
                                  provider,
                                  proof,
                                );
                              }),
                            ],
                            SizedBox(height: 24),
                            Container(
                              color: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(0, 0, 0, 45),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 55,
                                  child: ElevatedButton(
                                    onPressed: provider.canSubmit
                                        ? () async {
                                            try {
                                              await provider.submitProofs();
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      AppLocalizations.of(
                                                        context,
                                                      )!.proofsUploaded,
                                                    ),
                                                  ),
                                                );
                                                Navigator.pop(context);
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                String errorMessage = AppLocalizations.of(context)!.error(e.toString());
                                                if (e is DioException && e.response?.data is Map && e.response?.data['message'] != null) {
                                                  errorMessage = e.response!.data['message'];
                                                }
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(errorMessage),
                                                    backgroundColor: Colors.red,
                                                  ),
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

  Widget _buildGlobalImagesPicker(
    BuildContext context,
    ProofSubmissionProvider provider,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDottedImagePicker(
          context,
          label: AppLocalizations.of(context)!.mosqueFront,
          path: provider.globalMosqueFrontImage,
          onPick: (source) => provider.pickGlobalImage('front', source),
        ),
        const SizedBox(width: 12),
        _buildDottedImagePicker(
          context,
          label: AppLocalizations.of(context)!.mosqueInsideImage,
          path: provider.globalMosqueInsideImage,
          onPick: (source) => provider.pickGlobalImage('inside', source),
        ),
        const SizedBox(width: 12),
        _buildDottedImagePicker(
          context,
          label: AppLocalizations.of(context)!.productInsideMosque,
          path: provider.globalPackagesImage,
          onPick: (source) => provider.pickGlobalImage('package', source),
        ),
      ],
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
        const SizedBox(height: 12),
        if (!provider.useSameImages) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDottedImagePicker(
                context,
                label: AppLocalizations.of(context)!.mosqueName,
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
                label: AppLocalizations.of(context)!.mosqueInsideImage,
                path: proof.mosqueInsideImage,
                onPick: (source) => provider.pickSubOrderImage(
                  proof.subOrderId,
                  'inside',
                  source,
                ),
              ),
              const SizedBox(width: 12),
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
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDottedImagePicker(
              context,
              label: AppLocalizations.of(context)!.productInsideMosque,
              path: proof.proofVideo,
              isVideo: true,
              onPick: (source) =>
                  provider.pickSubOrderVideo(proof.subOrderId, source),
            ),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
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
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.hardEdge,
                child: path != null
                    ? (isVideo
                          ? const Center(
                              child: Icon(
                                Icons.videocam,
                                color: Colors.green,
                                size: 40,
                              ),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadiusGeometry.circular(12),
                              child: path.startsWith('http')
                                  ? Image.network(path, fit: BoxFit.cover)
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

  Widget _buildMediaPickerRow(
    BuildContext context, {
    required String label,
    required String? path,
    required Function(ImageSource) onPick,
    bool isVideo = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              if (path != null)
                const Text(
                  'Selected',
                  style: TextStyle(color: Colors.green, fontSize: 12),
                )
              else
                const Text(
                  'Not selected',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
            ],
          ),
        ),
        if (path != null && !isVideo)
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(path),
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
          )
        else if (path != null && isVideo)
          const Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: Icon(Icons.videocam, color: Colors.green),
          ),
        ElevatedButton(
          onPressed: () =>
              _showSourceBottomSheet(context, onPick, isVideo: isVideo),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[200],
            foregroundColor: Colors.black87,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          child: Text(path == null ? 'Select' : 'Change'),
        ),
      ],
    );
  }

  void _showSourceBottomSheet(
    BuildContext context,
    Function(ImageSource) onPick, {
    bool isVideo = false,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.4,
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
                  SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.selectSource,
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
                          title: isVideo
                              ? AppLocalizations.of(context)!.takeAVideo
                              : AppLocalizations.of(context)!.takeAPhoto,
                          onTap: () {
                            Navigator.pop(context);
                            onPick(ImageSource.camera);
                          },
                        ),
                        const Divider(height: 1, color: Color(0xFFEAEFF2)),
                        _buildBottomSheetTile(
                          icon: Icons.photo_library,
                          title: AppLocalizations.of(
                            context,
                          )!.chooseFromGallery,
                          onTap: () {
                            Navigator.pop(context);
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

  Widget _buildCustomerCard(BuildContext context, Map<String, dynamic> customer) {
    final address = customer['address'];
    final name = '${customer['firstName'] ?? ''} ${customer['lastName'] ?? ''}'.trim();
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.buttonBlueDark.withValues(alpha: 0.1)),
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.buttonBlueDark.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: AppColors.buttonBlueDark,
                    size: 17,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.customerDetails,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEF1F4)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (name.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                if (customer['phoneNumber'] != null && customer['phoneNumber'].toString().isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_outlined,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${customer['phoneNumber']}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
                if (address != null && address.toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          address.toString(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
