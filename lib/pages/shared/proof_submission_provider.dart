import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rahiq_driver/data/api/api_client.dart';
import 'package:rahiq_driver/data/api/driver/driver_orders_api.dart';

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
  final List<String> subOrderIds;
  final DriverOrdersApi _api = DriverOrdersApi(ApiClient());
  
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
    required this.subOrderIds,
    String? initialMosqueFrontImage,
    String? initialMosqueInsideImage,
  }) {
    if (isAutoOrder || isMultiSelect) {
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

  Future<void> pickSubOrderImage(String subOrderId, String type, ImageSource source) async {
    final XFile? file = await _picker.pickImage(source: source);
    if (file != null) {
      final proof = _proofs.firstWhere((p) => p.subOrderId == subOrderId);
      if (type == 'front') proof.mosqueFrontImage = file.path;
      if (type == 'inside') proof.mosqueInsideImage = file.path;
      if (type == 'package') proof.packagesImage = file.path;
      notifyListeners();
    }
  }

  Future<void> pickSubOrderVideo(String subOrderId, ImageSource source) async {
    final XFile? file = await _picker.pickVideo(source: source);
    if (file != null) {
      final proof = _proofs.firstWhere((p) => p.subOrderId == subOrderId);
      proof.proofVideo = file.path;
      notifyListeners();
    }
  }

  Future<void> pickGlobalVideo(ImageSource source) async {
    final XFile? file = await _picker.pickVideo(source: source);
    if (file != null) {
      _globalProofVideo = file.path;
      notifyListeners();
    }
  }

  bool get canSubmit {
    if (isMultiSelect || _useSameImages) {
      if (_globalMosqueFrontImage == null || _globalMosqueInsideImage == null || _globalPackagesImage == null || _globalProofVideo == null) return false;
      return true;
    } else {
      if (_proofs.isEmpty) return false;
      final p = _proofs.first;
      return p.mosqueFrontImage != null && p.mosqueInsideImage != null && p.packagesImage != null && p.proofVideo != null;
    }
  }

  Future<bool> submitProofs() async {
    _isSubmitting = true;
    notifyListeners();

    try {
      if (isMultiSelect || _useSameImages) {
        if (!canSubmit) throw Exception('Please provide all required media.');
        
        await _api.bulkUploadProof(
          orderId: orderId,
          subOrderIds: _proofs.map((p) => p.subOrderId).toList(),
          mosqueFrontImagePath: _globalMosqueFrontImage!,
          mosqueInsideImagePath: _globalMosqueInsideImage!,
          packagesImagePath: _globalPackagesImage!,
          proofVideoPath: _globalProofVideo,
        );
      } else {
        // Single submission
        if (!canSubmit) throw Exception('Please provide all required media.');
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
