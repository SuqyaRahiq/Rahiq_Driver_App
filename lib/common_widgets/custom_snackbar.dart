import 'package:flutter/material.dart';
import 'package:rahiq_driver/utils/colors.dart';
import 'dart:async';
import 'dart:math' as math;

class CustomSnackbar {
  static OverlayEntry? _currentOverlay;
  static _AnimatedSnackbarOverlayState? _currentState;

  static void show({
    required BuildContext context,
    required String message,
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
    double bottomMargin = 24,
  }) {
    // Hide any existing custom snackbar immediately
    if (_currentOverlay != null) {
      _currentState?.dismiss(immediate: true);
    }
    // Also hide default ones just in case
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final overlay = Navigator.of(context, rootNavigator: true).overlay;
    if (overlay == null) return;

    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _AnimatedSnackbarOverlay(
        message: message,
        isError: isError,
        displayDuration: duration,
        bottomMargin: bottomMargin,
        onDismissed: () {
          if (_currentOverlay == overlayEntry) {
            _currentOverlay?.remove();
            _currentOverlay = null;
            _currentState = null;
          }
        },
        onStateCreated: (state) {
          _currentState = state;
        },
      ),
    );

    _currentOverlay = overlayEntry;
    overlay.insert(overlayEntry);
  }
}

class _AnimatedSnackbarOverlay extends StatefulWidget {
  final String message;
  final bool isError;
  final Duration displayDuration;
  final double bottomMargin;
  final VoidCallback onDismissed;
  final void Function(_AnimatedSnackbarOverlayState) onStateCreated;

  const _AnimatedSnackbarOverlay({
    required this.message,
    required this.isError,
    required this.displayDuration,
    required this.bottomMargin,
    required this.onDismissed,
    required this.onStateCreated,
  });

  @override
  _AnimatedSnackbarOverlayState createState() =>
      _AnimatedSnackbarOverlayState();
}

class _AnimatedSnackbarOverlayState extends State<_AnimatedSnackbarOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    widget.onStateCreated(this);

    // Slowed down animation for a sleeker entrance/exit
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      reverseDuration: const Duration(milliseconds: 500),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInBack,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        );

    _controller.forward();

    // Start duration timer only after the entrance animation finishes
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _timer = Timer(widget.displayDuration, () {
          dismiss();
        });
      } else if (status == AnimationStatus.dismissed) {
        widget.onDismissed();
      }
    });
  }

  void dismiss({bool immediate = false}) {
    _timer?.cancel();
    if (immediate) {
      widget.onDismissed();
    } else {
      if (mounted && !_controller.isAnimating) {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: math.max(
        MediaQuery.of(context).viewInsets.bottom + 24,
        widget.bottomMargin,
      ), // Respect keyboard and clear bottom nav
      left: 20,
      right: 20,
      child: SafeArea(
        child: Material(
          color: Colors.transparent,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _opacityAnimation,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: widget.isError
                        ? Colors.red
                        : AppColors.buttonBlueDark,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (widget.isError
                                    ? Colors.red
                                    : AppColors.buttonBlueDark)
                                .withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.isError
                              ? Icons.error_outline_rounded
                              : Icons.check_circle_outline_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          widget.message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: dismiss,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white70,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
