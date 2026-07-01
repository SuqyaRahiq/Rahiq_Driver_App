import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rahiq_driver/data/api/api_client.dart';
import 'package:rahiq_driver/data/api/driver/driver_orders_api.dart';
import 'dart:io';
import 'package:video_player/video_player.dart';
import 'package:rahiq_driver/data/api/driver/driver_auto_deliveries_api.dart';

class SubOrderProof {
  final String subOrderId;
  String? mosqueFrontImage;
  String? mosqueInsideImage;
  String? packagesImage;
  String? proofVideo;

  SubOrderProof(this.subOrderId);
}

class ProofSubmissionProvider extends ChangeNotifier {
  final String orderId;
  final bool isAutoOrder;
  final bool isAutoDelivery;
  final List<String> subOrderIds;
  final DriverOrdersApi _api = DriverOrdersApi(ApiClient());
  final DriverAutoDeliveriesApi _autoDeliveriesApi = DriverAutoDeliveriesApi(ApiClient());

  bool _useSameImages = false;
  bool get useSameImages => _useSameImages;
  bool get isMultiSelect => subOrderIds.length > 1;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _globalMosqueFrontImage;
  String? _globalMosqueInsideImage;
  String? _globalPackagesImage;
  String? _globalProofVideo;

  String? get globalMosqueFrontImage => _globalMosqueFrontImage;
  String? get globalMosqueInsideImage => _globalMosqueInsideImage;
  String? get globalPackagesImage => _globalPackagesImage;
  String? get globalProofVideo => _globalProofVideo;

  List<SubOrderProof> _proofs = [];
  List<SubOrderProof> get proofs => _proofs;

  final ImagePicker _picker = ImagePicker();

  ProofSubmissionProvider({
    required this.orderId,
    required this.isAutoOrder,
    this.isAutoDelivery = false,
    required this.subOrderIds,
    String? initialMosqueFrontImage,
    String? initialMosqueInsideImage,
  }) {
    if (isAutoOrder || isMultiSelect || isAutoDelivery) {
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
  }

  void toggleUseSameImages(bool? value) {
    _useSameImages = value ?? false;
    notifyListeners();
  }

  Future<void> pickGlobalImage(String type, ImageSource source) async {
    final XFile? file = await _picker.pickImage(source: source);
    if (file != null) {
      if (type == 'front') _globalMosqueFrontImage = file.path;
      if (type == 'inside') _globalMosqueInsideImage = file.path;
      if (type == 'package') _globalPackagesImage = file.path;
      notifyListeners();
    }
  }

  Future<void> pickSubOrderImage(
    String subOrderId,
    String type,
    ImageSource source,
  ) async {
    final XFile? file = await _picker.pickImage(source: source);
    if (file != null) {
      final proof = _proofs.firstWhere((p) => p.subOrderId == subOrderId);
      if (type == 'front') proof.mosqueFrontImage = file.path;
      if (type == 'inside') proof.mosqueInsideImage = file.path;
      if (type == 'package') proof.packagesImage = file.path;
      notifyListeners();
    }
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

  Future<String?> pickSubOrderVideo(String subOrderId, ImageSource source) async {
    final XFile? file = await _picker.pickVideo(source: source, maxDuration: const Duration(seconds: 10));
    if (file != null) {
      if (await _isVideoTooLong(file.path)) {
        return 'video_too_long';
      }
      final proof = _proofs.firstWhere((p) => p.subOrderId == subOrderId);
      proof.proofVideo = file.path;
      notifyListeners();
    }
    return null;
  }

  Future<String?> pickGlobalVideo(ImageSource source) async {
    final XFile? file = await _picker.pickVideo(source: source, maxDuration: const Duration(seconds: 10));
    if (file != null) {
      if (await _isVideoTooLong(file.path)) {
        return 'video_too_long';
      }
      _globalProofVideo = file.path;
      notifyListeners();
    }
    return null;
  }

  bool get canSubmit {
    if (isMultiSelect || _useSameImages) {
      if (_globalMosqueFrontImage == null ||
          _globalMosqueInsideImage == null ||
          _globalPackagesImage == null ||
          _globalProofVideo == null) {
        return false;
      }
      return true;
    } else {
      if (_proofs.isEmpty) return false;
      final p = _proofs.first;
      return p.mosqueFrontImage != null &&
          p.mosqueInsideImage != null &&
          p.packagesImage != null &&
          p.proofVideo != null;
    }
  }

  Future<bool> submitProofs() async {
    _isSubmitting = true;
    notifyListeners();

    try {
      if (isAutoDelivery) {
        if (!canSubmit) throw Exception('missing_media');
        await _autoDeliveriesApi.confirmAutoDelivery(
          deliveryId: orderId,
          mosqueFrontImage: _globalMosqueFrontImage!,
          mosqueInsideImage: _globalMosqueInsideImage!,
          packagesImage: _globalPackagesImage!,
          deliveryVideo: _globalProofVideo!,
        );
      } else if (isMultiSelect || _useSameImages) {
        if (!canSubmit) throw Exception('missing_media');

        await _api.bulkUploadMosqueImages(
          orderId: orderId,
          subOrderIds: _proofs.map((p) => p.subOrderId).toList(),
          mosqueFrontImagePath: _globalMosqueFrontImage!,
          mosqueInsideImagePath: _globalMosqueInsideImage!,
        );
      } else {
        // Single submission
        if (!canSubmit) throw Exception('missing_media');
        final p = _proofs.first;
        await _api.confirmSubOrder(
          subOrderId: p.subOrderId,
          mosqueFrontImagePath: p.mosqueFrontImage!,
          mosqueInsideImagePath: p.mosqueInsideImage!,
          packagesImagePath: p.packagesImage!,
          proofVideoPath: p.proofVideo!,
        );
      }
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmitting = false;
      notifyListeners();
      rethrow;
    }
  }
}
