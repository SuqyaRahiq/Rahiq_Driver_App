import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rahiq_driver/l10n/app_localizations.dart';
import 'package:rahiq_driver/main.dart' show isCameraVisible;
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

  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double _currentZoom = 1.0;
  double _baseZoom = 1.0;

  final GlobalKey _previewKey = GlobalKey();
  Offset? _focusIndicatorPosition;
  Timer? _focusIndicatorTimer;

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
    // Take the app backdrop in main.dart black for as long as this screen is
    // up, so the system navigation bar doesn't sit as a white band under the
    // full-bleed viewfinder. Deferred to after this frame because notifying
    // the listener from initState would mark MyApp dirty mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      isCameraVisible.value = true;
    });
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
          fps: widget.isVideoMode ? 30 : null,
        );

        await _controller!.initialize();
        await _controller!.setFlashMode(_flashMode);
        _minZoom = await _controller!.getMinZoomLevel();
        _maxZoom = await _controller!.getMaxZoomLevel();
        _currentZoom = _minZoom;

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
    // Hand the backdrop back to white, deferred for the same reason as above:
    // dispose runs with the element tree locked.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      isCameraVisible.value = false;
    });
    _timer?.cancel();
    _focusIndicatorTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  void _onScaleStart(ScaleStartDetails details) {
    _baseZoom = _currentZoom;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) async {
    if (_controller == null || !_isInitialized) return;
    final zoom = (_baseZoom * details.scale).clamp(_minZoom, _maxZoom);
    if (zoom == _currentZoom) return;
    _currentZoom = zoom;
    await _controller!.setZoomLevel(_currentZoom);
  }

  // Tap-to-focus, for both photo and video. The RenderBox is looked up via
  // _previewKey (attached to the Stack directly wrapping CameraPreview, see
  // _buildCameraStackContent) rather than the full-bleed GestureDetector,
  // since that Stack's bounds match the actual rendered preview exactly —
  // using the outer detector's bounds would drift the focus point whenever
  // the preview is letterboxed.
  void _onTapToFocus(TapUpDetails details) async {
    if (_controller == null || !_isInitialized) return;

    final renderBox =
        _previewKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPosition = renderBox.globalToLocal(details.globalPosition);
    final size = renderBox.size;
    if (localPosition.dx < 0 ||
        localPosition.dx > size.width ||
        localPosition.dy < 0 ||
        localPosition.dy > size.height) {
      return; // Tap landed outside the actual preview (e.g. letterboxing).
    }

    final normalized = Offset(
      (localPosition.dx / size.width).clamp(0.0, 1.0),
      (localPosition.dy / size.height).clamp(0.0, 1.0),
    );

    setState(() => _focusIndicatorPosition = localPosition);
    _focusIndicatorTimer?.cancel();
    _focusIndicatorTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _focusIndicatorPosition = null);
    });

    try {
      await _controller!.setFocusPoint(normalized);
      await _controller!.setExposurePoint(normalized);
      await _controller!.setFocusMode(FocusMode.auto);
      await _controller!.setExposureMode(ExposureMode.auto);
    } catch (e) {
      debugPrint('Error setting focus point: $e');
    }
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

  // Photo mode uses a custom 4:3 viewfinder: the sensor's native preview
  // stream (whatever ratio ResolutionPreset.veryHigh yields — commonly
  // wider than 4:3) is cropped to a 4:3 box via FittedBox(cover) + ClipRect
  // so what's framed on screen is what gets captured, rather than taking
  // the native-ratio photo and cropping the file afterward. Video mode is
  // left at its native ratio, unchanged.
  Widget _buildCameraPreview() {
    if (widget.isVideoMode) {
      return CameraPreview(_controller!);
    }

    // CameraPreview reports/renders `previewSize` in the sensor's landscape
    // orientation but displays upright (rotated) for the current device
    // orientation, so the on-screen box is previewSize flipped: width =
    // previewSize.height, height = previewSize.width.
    final previewSize = _controller!.value.previewSize;
    if (previewSize == null) {
      return CameraPreview(_controller!);
    }

    return AspectRatio(
      aspectRatio: 3 / 4,
      child: ClipRect(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: previewSize.height,
            height: previewSize.width,
            child: CameraPreview(_controller!),
          ),
        ),
      ),
    );
  }

  Widget _buildFocusRing() {
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.4, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 1.5),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildCameraStackContent(BuildContext context, double maxNoteHeight) {
    return Stack(
      children: [
        // Camera Preview
        Positioned.fill(
          child: GestureDetector(
            onScaleStart: _onScaleStart,
            onScaleUpdate: _onScaleUpdate,
            onTapUp: _onTapToFocus,
            child: Center(
              child: Stack(
                key: _previewKey,
                alignment: Alignment.center,
                children: [
                  _buildCameraPreview(),
                  if (_focusIndicatorPosition != null)
                    Positioned(
                      left: _focusIndicatorPosition!.dx - 32,
                      top: _focusIndicatorPosition!.dy - 32,
                      child: _buildFocusRing(),
                    ),
                ],
              ),
            ),
          ),
        ),

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
                                "${widget.quantity} ${widget.productName ?? ""}",
                                style: const TextStyle(fontSize: 14),
                              ),
                              if (widget.date != null &&
                                  widget.date!.isNotEmpty)
                                Text(
                                  widget.date!,
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

              // Helper Text — given its own background (rather than relying
              // on the camera preview's letterboxing) so it looks the same
              // whether the live preview happens to reach behind it or not;
              // photo mode's ResolutionPreset (veryHigh) has a different
              // aspect ratio than video's (medium), so the letterboxing
              // isn't always there.
              if (!_isRecording)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.isVideoMode
                        ? 'Tap to record (Max ${widget.maxDurationSeconds}s)'
                        : 'Tap to take picture',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
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
