import 'package:flutter/material.dart';
import 'package:rahiq_driver/l10n/app_localizations.dart';

/// The "Refill" pill marking a sub-order that tops up a chiller the customer
/// already owns, rather than a standalone water delivery.
///
/// Shown wherever such an order is listed or opened, so the driver can tell a
/// refill apart without reading the product line — the sub-order list and the
/// proof submission page. Gate it on `NormalSubOrder.isChillerRefill`.
class ChillerRefillBadge extends StatelessWidget {
  const ChillerRefillBadge({super.key, this.compact = false});

  /// Drops the pill to the size that fits on a list card, where it shares a
  /// row with the order number rather than standing on its own.
  final bool compact;

  /// The chillers blue, matching the customer app's badge.
  static const _color = Color(0xFF0284C7);

  @override
  Widget build(BuildContext context) {
    final double fontSize = compact ? 11 : 13;
    final double iconSize = compact ? 13 : 16;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 6,
      ),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.water_drop_rounded, size: iconSize, color: _color),
          SizedBox(width: compact ? 4 : 6),
          Text(
            AppLocalizations.of(context)!.chillerRefill,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}
