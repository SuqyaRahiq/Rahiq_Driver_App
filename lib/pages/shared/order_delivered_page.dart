import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rahiq_driver/l10n/app_localizations.dart';
import 'package:rahiq_driver/utils/colors.dart';

/// Full-screen success moment shown right after a delivery is confirmed.
/// Dismisses itself automatically after 2s, or immediately when the action
/// button (or the screen) is tapped, so the caller's `await Navigator.push(...)`
/// continues and takes the driver to the next screen.
class OrderDeliveredPage extends StatefulWidget {
  /// Whether the caller sends the driver home afterwards (auto delivery) or
  /// back to the order listing. Only decides the button label.
  final bool returnsHome;

  const OrderDeliveredPage({super.key, this.returnsHome = false});

  @override
  State<OrderDeliveredPage> createState() => _OrderDeliveredPageState();
}

class _OrderDeliveredPageState extends State<OrderDeliveredPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _badgeScale;
  late final Animation<double> _ring;
  late final Animation<double> _fade;
  Timer? _autoCloseTimer;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _badgeScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    );
    _ring = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 1.0, curve: Curves.easeIn),
    );

    _autoCloseTimer = Timer(const Duration(seconds: 2), _leave);
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Hands control back to the caller, which decides where the driver lands.
  /// Guarded so the auto-navigate timer can never fire on top of a tap that
  /// already dismissed this screen.
  void _leave() {
    if (_leaving) return;
    _leaving = true;
    _autoCloseTimer?.cancel();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.buttonBlueDark,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _leave,
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Opacity(
                            opacity: (1 - _ring.value).clamp(0.0, 1.0),
                            child: Transform.scale(
                              scale: 0.6 + (_ring.value * 0.6),
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    width: 3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Transform.scale(
                            scale: _badgeScale.value,
                            child: Container(
                              width: 96,
                              height: 96,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check_rounded,
                                color: AppColors.buttonBlueDark,
                                size: 56,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Opacity(
                      opacity: _fade.value,
                      child: Column(
                        children: [
                          Text(
                            AppLocalizations.of(context)!.orderDeliveredTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              AppLocalizations.of(
                                context,
                              )!.orderDeliveredMessage,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: 220,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _leave,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.buttonBlueDark,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: Text(
                                widget.returnsHome
                                    ? AppLocalizations.of(context)!.goToHome
                                    : AppLocalizations.of(
                                        context,
                                      )!.backToOrders,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
