import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CustomCameraScreen extends StatefulWidget {
  final int maxDurationSeconds;

  const CustomCameraScreen({
    super.key,
    this.maxDurationSeconds = 10,
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

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        _controller = CameraController(
          _cameras.first,
          ResolutionPreset.medium,
          enableAudio: true,
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

  Future<void> _stopRecording() async {
    if (_controller == null || !_controller!.value.isRecordingVideo) return;

    _timer?.cancel();

    try {
      final XFile videoFile = await _controller!.stopVideoRecording();
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
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera Preview
            Positioned.fill(
              child: Center(
                child: CameraPreview(_controller!),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.fiber_manual_record, color: Colors.white, size: 16),
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

            // Bottom Controls
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _isRecording ? _stopRecording : _startRecording,
                    child: Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          height: _isRecording ? 30 : 60,
                          width: _isRecording ? 30 : 60,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: _isRecording 
                                ? BorderRadius.circular(8) 
                                : BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Helper Text
            if (!_isRecording)
              Positioned(
                bottom: 120,
                left: 0,
                right: 0,
                child: Text(
                  'Tap to record (Max ${widget.maxDurationSeconds}s)',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    shadows: [
                      Shadow(
                        color: Colors.black,
                        blurRadius: 4,
                      )
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
