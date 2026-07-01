import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:rahiq_driver/utils/colors.dart';

/// A modern, premium Soundwave/Audio-wave Loading Indicator.
/// Replaces the legacy Water Loading Indicator with an interactive, glowing soundwave animation.
class WaterLoadingIndicator extends StatefulWidget {
  final double size;

  final Color? waveColor1;

  const WaterLoadingIndicator({super.key, this.size = 24.0, this.waveColor1});

  @override
  State<WaterLoadingIndicator> createState() => _WaterLoadingIndicatorState();
}

class _WaterLoadingIndicatorState extends State<WaterLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Soundwave configuration for 5 beautiful bouncing bars
  final List<double> _minHeights = [0.25, 0.45, 0.30, 0.50, 0.20];
  final List<double> _maxHeights = [0.85, 1.00, 0.90, 1.00, 0.75];

  // Custom multipliers for varying animation cycles and speeds per bar
  final List<double> _speedMultipliers = [1.0, 1.2, 0.9, 1.3, 1.1];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Proportional dimensions using the full widget size
    final innerSize = widget.size;

    final barWidth = innerSize * 0.12;
    final spacing = innerSize * 0.08;

    final Widget animationWidget = AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Build the list of animated bars
        final List<Widget> bars = List.generate(5, (index) {
          // Calculate individual bar motion using sine wave and specific speed/phase offsets
          final double angle =
              (_controller.value * 2 * math.pi * _speedMultipliers[index]) +
              (index * 0.65);
          final double sineValue =
              (math.sin(angle) + 1.0) / 2.0; // Map from [-1, 1] to [0, 1]

          // Final animated height for this specific bar
          final double heightFactor =
              _minHeights[index] +
              (_maxHeights[index] - _minHeights[index]) * sineValue;
          final double barHeight = innerSize * heightFactor;

          return Container(
            width: barWidth,
            height: barHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(barWidth / 2),
              color: widget.waveColor1 ?? AppColors.buttonBlue,
            ),
          );
        });

        final Widget soundwave = SizedBox(
          width: innerSize,
          height: innerSize,
          child: FittedBox(
            fit: BoxFit.contain,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(bars.length * 2 - 1, (index) {
                // Alternate between bar widgets and spacing gaps
                if (index.isEven) {
                  return bars[index ~/ 2];
                } else {
                  return SizedBox(width: spacing);
                }
              }),
            ),
          ),
        );

        return soundwave;
      },
    );

    return SizedBox(height: widget.size, child: animationWidget);
  }
}
