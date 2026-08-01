import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rahiq_driver/l10n/app_localizations.dart';
import 'package:rahiq_driver/utils/water_loading.dart';

class CustomCameraScreen extends StatefulWidget {
  final int maxDurationSeconds;
  final bool isVideoMode;
  final String? customerName;
  final String? quantity;
  final String? date;
  final String? customerNote;
  final List<String>? customerServiceNotes;
  final String? productName;
  final String? giftCardSenderName;
  final String? giftCardRecipientName;

  const CustomCameraScreen({
    super.key,
    this.maxDurationSeconds = 10,
    this.isVideoMode = true,
    this.customerName,
    this.quantity,
    this.date,
    this.customerNote,
    this.customerServiceNotes,
    this.productName,
    this.giftCardSenderName,
    this.giftCardRecipientName,
  });

  @override
  State<CustomCameraScreen> createState() => _CustomCameraScreenState();
}

class _CustomCameraScreenState extends State<CustomCameraScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _timer;
  FlashMode _flashMode = FlashMode.off;
  bool _isDetailsVisible = true;

  bool get _hasGiftCardInfo =>
      (widget.giftCardSenderName != null &&
          widget.giftCardSenderName!.isNotEmpty) ||
      (widget.giftCardRecipientName != null &&
          widget.giftCardRecipientName!.isNotEmpty);

  bool get _hasOverlayContent =>
      widget.customerName != null ||
      _hasGiftCardInfo ||
      widget.quantity != null ||
      (widget.customerNote != null && widget.customerNote!.isNotEmpty) ||
      (widget.customerServiceNotes != null &&
          widget.customerServiceNotes!.isNotEmpty);

  @override
  void initState() {
    super.initState();
    // Camera/video recording should follow the device's rotation instead of
    // being stuck in portrait — matches the orientations declared in
    // Info.plist (portrait + both landscapes, no upside-down).
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        _controller = CameraController(
          _cameras.first,
          widget.isVideoMode
              ? ResolutionPreset.medium
              : ResolutionPreset.veryHigh,
          enableAudio: widget.isVideoMode,
        );

        await _controller!.initialize();
        await _controller!.setFlashMode(_flashMode);

        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    // Restore unrestricted rotation for the rest of the app (it doesn't
    // lock orientation anywhere else, so an empty list is the correct way
    // to lift the restriction set above rather than re-locking to portrait).
    SystemChrome.setPreferredOrientations([]);
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  void _toggleFlash() async {
    if (_controller == null || !_isInitialized) return;

    if (_flashMode == FlashMode.off) {
      _flashMode = FlashMode.torch;
    } else if (_flashMode == FlashMode.torch) {
      _flashMode = FlashMode.auto;
    } else {
      _flashMode = FlashMode.off;
    }

    await _controller!.setFlashMode(_flashMode);
    setState(() {});
  }

  Future<void> _startRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_controller!.value.isRecordingVideo) return;

    try {
      await _controller!.startVideoRecording();
      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        setState(() {
          _recordingSeconds++;
        });

        if (_recordingSeconds >= widget.maxDurationSeconds) {
          await _stopRecording();
        }
      });
    } catch (e) {
      debugPrint('Error starting video recording: $e');
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final XFile imageFile = await _controller!.takePicture();

      try {
        final size = await imageFile.length();
        final resolution = _controller!.value.previewSize;
        debugPrint('📸 Image captured:');
        debugPrint(' - Path: ${imageFile.path}');
        debugPrint(' - Size: ${(size / 1024).toStringAsFixed(2)} KB');
        if (resolution != null) {
          debugPrint(
            ' - Resolution: ${resolution.width} x ${resolution.height}',
          );
        }
      } catch (logError) {
        debugPrint('Error logging image details: $logError');
      }

      if (mounted) {
        Navigator.pop(context, imageFile.path);
      }
    } catch (e) {
      debugPrint('Error taking picture: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (_controller == null || !_controller!.value.isRecordingVideo) return;

    _timer?.cancel();

    try {
      final XFile videoFile = await _controller!.stopVideoRecording();

      try {
        final size = await videoFile.length();
        final resolution = _controller!.value.previewSize;
        debugPrint('🎥 Video recorded:');
        debugPrint(' - Path: ${videoFile.path}');
        debugPrint(' - Size: ${(size / (1024 * 1024)).toStringAsFixed(2)} MB');
        if (resolution != null) {
          debugPrint(
            ' - Resolution: ${resolution.width} x ${resolution.height}',
          );
        }
      } catch (logError) {
        debugPrint('Error logging video details: $logError');
      }

      setState(() {
        _isRecording = false;
      });

      if (mounted) {
        Navigator.pop(context, videoFile.path);
      }
    } catch (e) {
      debugPrint('Error stopping video recording: $e');
      setState(() {
        _isRecording = false;
      });
    }
  }

  IconData _getFlashIcon() {
    switch (_flashMode) {
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.torch:
        return Icons.flash_on;
      case FlashMode.always:
        return Icons.flash_on;
    }
  }

  String _formatDuration(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: WaterLoadingIndicator(waveColor1: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // ── Camera area: preview + all overlays that must never reach
            // into the bottom controls bar below. Because this Stack is a
            // sibling of the bottom bar inside a Column (not absolutely
            // positioned against the full screen), nothing here can ever
            // visually overlap the record button, regardless of screen
            // size/type or how tall the note content grows.
            Expanded(child: _buildCameraStack()),

            // Bottom Controls
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraStack() {
    return LayoutBuilder(
      builder: (context, constraints) => _buildCameraStackContent(
        context,
        // Leave headroom for the top controls + a margin, so a long note
        // scrolls internally instead of growing tall enough to reach them.
        constraints.maxHeight - 96,
      ),
    );
  }

  Widget _buildCameraStackContent(BuildContext context, double maxNoteHeight) {
    return Stack(
      children: [
        // Camera Preview
        Positioned.fill(child: Center(child: CameraPreview(_controller!))),

        // Top Controls
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back Button
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () {
                  if (_isRecording) {
                    _stopRecording();
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),

              // Recording Timer
              if (_isRecording)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.fiber_manual_record,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDuration(_recordingSeconds),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

              // Flash Toggle
              IconButton(
                icon: Icon(_getFlashIcon(), color: Colors.white, size: 30),
                onPressed: _toggleFlash,
              ),
            ],
          ),
        ),

        // Note overlay + helper text share this bottom-anchored Column, so
        // they stack top-to-bottom in sequence and can never overlap each
        // other — same non-overlap guarantee as the camera area vs. the
        // bottom controls bar above.
        Positioned(
          left: 0,
          right: 0,
          bottom: 8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isVideoMode && _isDetailsVisible && _hasOverlayContent)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: 16,
                      bottom: 8,
                    ),
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.5,
                        maxHeight: maxNoteHeight > 0 ? maxNoteHeight : 0,
                      ),
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 4),
                        ],
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_hasGiftCardInfo) ...[
                              if (widget.giftCardSenderName != null &&
                                  widget.giftCardSenderName!.isNotEmpty)
                                Text(
                                  '${AppLocalizations.of(context)!.senderName}: ${widget.giftCardSenderName}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              if (widget.giftCardRecipientName != null &&
                                  widget.giftCardRecipientName!.isNotEmpty)
                                Text(
                                  '${AppLocalizations.of(context)!.recipientName}: ${widget.giftCardRecipientName}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              const SizedBox(height: 3),
                            ] else if (widget.customerName != null) ...[
                              Text(
                                widget.customerName!,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 3),
                            ],
                            if (widget.quantity != null) ...[
                              Text(
                                "${widget.quantity} ${widget.productName ?? ""} ${widget.date ?? ""}",
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],

                            if (widget.customerNote != null &&
                                widget.customerNote!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                widget.customerNote!,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (widget.customerServiceNotes != null &&
                                widget.customerServiceNotes!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                widget.customerServiceNotes!.join(', '),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // Helper Text
              if (!_isRecording)
                Text(
                  widget.isVideoMode
                      ? 'Tap to record (Max ${widget.maxDurationSeconds}s)'
                      : 'Tap to take picture',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // Lives outside the camera Stack, as its own fixed-height row below the
  // Expanded camera area — so it can never be overlapped by the note
  // overlay or helper text above it, on any screen size.
  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      child: Row(
        children: [
          Expanded(
            child: (widget.isVideoMode && _hasOverlayContent)
                ? Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 90),
                      child: IconButton(
                        icon: const Icon(
                          Icons.description_outlined,
                          color: Colors.white,
                          size: 30,
                        ),
                        onPressed: () {
                          setState(() {
                            _isDetailsVisible = !_isDetailsVisible;
                          });
                        },
                      ),
                    ),
                  )
                : const SizedBox(),
          ),
          GestureDetector(
            onTap: widget.isVideoMode
                ? (_isRecording ? _stopRecording : _startRecording)
                : _takePicture,
            child: Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: Center(
                child: Container(
                  height: widget.isVideoMode ? (_isRecording ? 30 : 60) : 60,
                  width: widget.isVideoMode ? (_isRecording ? 30 : 60) : 60,
                  decoration: BoxDecoration(
                    color: widget.isVideoMode ? Colors.red : Colors.white,
                    borderRadius: widget.isVideoMode && _isRecording
                        ? BorderRadius.circular(8)
                        : BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ),
          const Expanded(child: SizedBox()),
        ],
      ),
    );
  }
}
