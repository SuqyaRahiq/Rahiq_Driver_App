import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rahiq_driver/data/api/api_client.dart';
import 'package:rahiq_driver/data/api/driver/driver_orders_api.dart';
import 'dart:io';
import 'package:video_player/video_player.dart';
import 'package:rahiq_driver/data/api/driver/driver_auto_deliveries_api.dart';
import 'package:rahiq_driver/utils/media_compressor.dart';
import 'package:rahiq_driver/pages/shared/custom_camera_screen.dart';

class SubOrderProof {
  final String subOrderId;
  String? mosqueFrontImage;
  String? mosqueInsideImage;
  String? packagesImage;
  String? proofVideo;
  bool deliveredToDifferentMosque = false;
  String? differentMosqueReason;
  String? deliveredLocationId;
  String? deliveredLocationName;
  bool isLoadingLocations = false;

  SubOrderProof(this.subOrderId);
}

class ProofSubmissionProvider extends ChangeNotifier {
  final String orderId;
  final bool isAutoOrder;
  final bool isAutoDelivery;
  final bool isChillerProduct;
  final List<String> subOrderIds;
  final DriverOrdersApi _api = DriverOrdersApi(ApiClient());
  final DriverAutoDeliveriesApi _autoDeliveriesApi = DriverAutoDeliveriesApi(
    ApiClient(),
  );

  bool _useSameImages = false;
  bool get isMultiSelect => subOrderIds.length > 1;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _globalMosqueFrontImage;
  String? _globalMosqueInsideImage;

  List<SubOrderProof> _proofs = [];
  List<SubOrderProof> get proofs => _proofs;

  final ImagePicker _picker = ImagePicker();
  final Map<String, bool> _isCompressingVideo = {};
  final Map<String, bool> _isCompressingImage = {};

  bool isCompressingVideo(String id) => _isCompressingVideo[id] ?? false;
  bool isCompressingImage(String subOrderId, String type) =>
      _isCompressingImage['$subOrderId:$type'] ?? false;

  ProofSubmissionProvider({
    required this.orderId,
    required this.isAutoOrder,
    this.isAutoDelivery = false,
    this.isChillerProduct = false,
    required this.subOrderIds,
    String? initialMosqueFrontImage,
    String? initialMosqueInsideImage,
  }) {
    if (isMultiSelect || isAutoDelivery) {
      _useSameImages = true;
    }
    _proofs = subOrderIds.map((id) => SubOrderProof(id)).toList();
    if (_proofs.isEmpty) {
      _proofs.add(SubOrderProof(orderId)); // Fallback if no suborders exist
    }

    if (!isMultiSelect && _proofs.isNotEmpty) {
      _proofs.first.mosqueFrontImage = initialMosqueFrontImage;
      _proofs.first.mosqueInsideImage = initialMosqueInsideImage;
    }
    if (_useSameImages) {
      _globalMosqueFrontImage = initialMosqueFrontImage;
      _globalMosqueInsideImage = initialMosqueInsideImage;
    }
  }

  Future<bool> _isFileTooLarge(String path, double maxSizeInMB) async {
    try {
      final file = File(path);
      final sizeInBytes = await file.length();
      final sizeInMB = sizeInBytes / (1024 * 1024);
      return sizeInMB > maxSizeInMB;
    } catch (e) {
      return false;
    }
  }

  Future<String?> pickSubOrderImage(
    BuildContext context,
    String subOrderId,
    String type,
    ImageSource source, {
    String? customerName,
    String? quantity,
    String? date,
    String? customerNote,
    List<String>? customerServiceNotes,
    String? productName,
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
            customerNote: customerNote,
            customerServiceNotes: customerServiceNotes,
            productName: productName,
          ),
        ),
      );
    } else {
      final XFile? file = await _picker.pickImage(source: source);
      filePath = file?.path;
    }

    if (filePath != null) {
      final compressionKey = '$subOrderId:$type';
      _isCompressingImage[compressionKey] = true;
      notifyListeners();
      filePath = await MediaCompressor.compressImage(filePath);
      _isCompressingImage[compressionKey] = false;
      notifyListeners();

      if (await _isFileTooLarge(filePath!, 2)) {
        return 'image_too_large';
      }
      final proof = _proofs.firstWhere((p) => p.subOrderId == subOrderId);
      if (type == 'front') proof.mosqueFrontImage = filePath;
      if (type == 'inside') proof.mosqueInsideImage = filePath;
      if (type == 'package') proof.packagesImage = filePath;
      notifyListeners();
    }
    return null;
  }

  Future<bool> _isVideoTooLong(String path) async {
    try {
      final controller = VideoPlayerController.file(File(path));
      await controller.initialize();
      final duration = controller.value.duration;
      await controller.dispose();
      return duration.inSeconds > 10;
    } catch (e) {
      return false;
    }
  }

  Future<String?> pickSubOrderVideo(
    BuildContext context,
    String subOrderId,
    ImageSource source, {
    String? customerName,
    String? quantity,
    String? date,
    String? customerNote,
    List<String>? customerServiceNotes,
    String? productName,
    String? giftCardSenderName,
    String? giftCardRecipientName,
  }) async {
    String? filePath;

    if (source == ImageSource.camera) {
      filePath = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CustomCameraScreen(
            maxDurationSeconds: 10,
            customerName: customerName,
            quantity: quantity,
            date: date,
            customerNote: customerNote,
            customerServiceNotes: customerServiceNotes,
            productName: productName,
            giftCardSenderName: giftCardSenderName,
            giftCardRecipientName: giftCardRecipientName,
          ),
        ),
      );
    } else {
      final XFile? file = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: 10),
      );
      filePath = file?.path;
    }

    if (filePath != null) {
      if (await _isVideoTooLong(filePath)) {
        return 'video_too_long';
      }

      _isCompressingVideo[subOrderId] = true;
      notifyListeners();
      filePath = await MediaCompressor.compressVideo(filePath);
      _isCompressingVideo[subOrderId] = false;
      notifyListeners();

      if (source == ImageSource.gallery) {
        if (await _isFileTooLarge(filePath!, 5.9)) {
          return 'file_too_large';
        }
      }
      final proof = _proofs.firstWhere((p) => p.subOrderId == subOrderId);
      proof.proofVideo = filePath;
      notifyListeners();
    }
    return null;
  }

  void removeSubOrderVideo(String subOrderId) {
    try {
      final proof = _proofs.firstWhere((p) => p.subOrderId == subOrderId);
      proof.proofVideo = null;
      notifyListeners();
    } catch (e) {
      // SubOrder proof not found
    }
  }

  bool get canSubmit {
    // For multi-select / shared mode: allow flexible mix of global + per-suborder images.
    // Each of the 4 required images can come from either global or suborder-specific source.
    // Scenarios:
    //   1. Global mosque front + inside (bulk upload) + per-suborder package + video
    //   2. All 4 images manually selected per suborder
    //   3. Mix: some from global, some from suborder
    if (isMultiSelect || _useSameImages) {
      for (final p in _proofs) {
        final mosqueFront = _globalMosqueFrontImage ?? p.mosqueFrontImage;
        final mosqueInside = _globalMosqueInsideImage ?? p.mosqueInsideImage;
        final packages = p.packagesImage;
        final video = p.proofVideo;

        if (mosqueFront == null ||
            mosqueInside == null ||
            packages == null ||
            video == null) {
          return false;
        }

        if (p.deliveredToDifferentMosque &&
            (p.differentMosqueReason == null ||
                p.differentMosqueReason!.isEmpty)) {
          return false;
        }

        if (isChillerProduct &&
            (p.deliveredLocationId == null || p.deliveredLocationId!.isEmpty)) {
          return false;
        }
      }
      return true;
    } else {
      if (_proofs.isEmpty) return false;
      final p = _proofs.first;
      return p.mosqueFrontImage != null &&
          p.mosqueInsideImage != null &&
          p.packagesImage != null &&
          p.proofVideo != null &&
          (!p.deliveredToDifferentMosque ||
              (p.differentMosqueReason != null &&
                  p.differentMosqueReason!.isNotEmpty)) &&
          (!isChillerProduct ||
              (p.deliveredLocationId != null &&
                  p.deliveredLocationId!.isNotEmpty));
    }
  }

  /// Returns a short code describing why submission is not allowed, or `null`
  /// when `canSubmit` is true. Useful for debugging UI state when the button
  /// stays disabled.
  String? get missingSubmitReason {
    if (isMultiSelect || _useSameImages) {
      for (final p in _proofs) {
        final mosqueFront = _globalMosqueFrontImage ?? p.mosqueFrontImage;
        final mosqueInside = _globalMosqueInsideImage ?? p.mosqueInsideImage;
        final packages = p.packagesImage;
        final video = p.proofVideo;

        if (mosqueFront == null)
          return 'missing_mosque_front_for_${p.subOrderId}';
        if (mosqueInside == null)
          return 'missing_mosque_inside_for_${p.subOrderId}';
        if (packages == null) return 'missing_packages_for_${p.subOrderId}';
        if (video == null) return 'missing_video_for_${p.subOrderId}';

        if (p.deliveredToDifferentMosque &&
            (p.differentMosqueReason == null ||
                p.differentMosqueReason!.isEmpty)) {
          return 'missing_different_mosque_reason_for_${p.subOrderId}';
        }

        if (isChillerProduct &&
            (p.deliveredLocationId == null || p.deliveredLocationId!.isEmpty)) {
          return 'missing_delivered_location_for_${p.subOrderId}';
        }
      }
      return null;
    } else {
      if (_proofs.isEmpty) return 'no_proofs_available';
      final p = _proofs.first;
      if (p.mosqueFrontImage == null) return 'missing_mosque_front';
      if (p.mosqueInsideImage == null) return 'missing_mosque_inside';
      if (p.packagesImage == null) return 'missing_packages_image';
      if (p.proofVideo == null) return 'missing_proof_video';
      if (p.deliveredToDifferentMosque &&
          (p.differentMosqueReason == null ||
              p.differentMosqueReason!.isEmpty)) {
        return 'missing_different_mosque_reason';
      }
      if (isChillerProduct &&
          (p.deliveredLocationId == null || p.deliveredLocationId!.isEmpty)) {
        return 'missing_delivered_location';
      }
      return null;
    }
  }

  Future<bool> submitProofs() async {
    _isSubmitting = true;
    notifyListeners();

    try {
      print("Checking Autodelivey or not");
      if (isAutoDelivery) {
        if (!canSubmit) throw Exception(missingSubmitReason);
        print('[ProofSubmission] Submitting auto-delivery: $orderId');
        print('[ProofSubmission] Mosque front: $_globalMosqueFrontImage');
        print('[ProofSubmission] Mosque inside: $_globalMosqueInsideImage');

        // For auto-delivery, mosque front/inside may come from the shared
        // batch upload; packages/video are always picked per sub-order.
        final mosqueFront =
            _globalMosqueFrontImage ??
            (_proofs.isNotEmpty ? _proofs.first.mosqueFrontImage : null);
        final mosqueInside =
            _globalMosqueInsideImage ??
            (_proofs.isNotEmpty ? _proofs.first.mosqueInsideImage : null);
        final packages = _proofs.isNotEmpty
            ? _proofs.first.packagesImage
            : null;
        final video = _proofs.isNotEmpty ? _proofs.first.proofVideo : null;

        await _autoDeliveriesApi.confirmAutoDelivery(
          deliveryId: orderId,
          mosqueFrontImage: mosqueFront!,
          mosqueInsideImage: mosqueInside!,
          packagesImage: packages!,
          deliveryVideo: video!,
        );
      } else {
        if (!canSubmit) throw Exception(missingSubmitReason);
        final p = _proofs.first;

        final frontImg = _useSameImages
            ? (_globalMosqueFrontImage ?? p.mosqueFrontImage!)
            : p.mosqueFrontImage!;
        final insideImg = _useSameImages
            ? (_globalMosqueInsideImage ?? p.mosqueInsideImage!)
            : p.mosqueInsideImage!;
        final packagesImg = p.packagesImage!;
        final videoImg = p.proofVideo!;

        await _api.confirmSubOrder(
          subOrderId: p.subOrderId,
          mosqueFrontImagePath: frontImg,
          mosqueInsideImagePath: insideImg,
          packagesImagePath: packagesImg,
          proofVideoPath: videoImg,
          deliveredToDifferentMosque: p.deliveredToDifferentMosque,
          differentMosqueReason: p.differentMosqueReason,
          deliveredLocationId: p.deliveredLocationId,
        );
      }

      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('[ProofSubmission] Error submitting proofs: $e');
      _isSubmitting = false;
      notifyListeners();
      rethrow;
    }
  }

  void setLoadingLocations(String subOrderId, bool loading) {
    try {
      final proof = _proofs.firstWhere((p) => p.subOrderId == subOrderId);
      proof.isLoadingLocations = loading;
      notifyListeners();
    } catch (e) {
      // SubOrder proof not found
    }
  }

  void updateUI() {
    notifyListeners();
  }
}
