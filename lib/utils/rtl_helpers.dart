import 'package:flutter/material.dart';

/// Centralized RTL-aware helpers for directional icons and layout utilities.
///
/// Flutter's directional Material Icons (like arrow_back, chevron_right)
/// inherently support auto-mirroring when the text direction is RTL.
/// Therefore, we just return the base LTR icon and let the Framework handle the flip.

/// Returns the correct back arrow icon for the current text direction.
IconData backArrowIcon(BuildContext context) {
  return Icons.arrow_back;
}

/// Returns the correct forward arrow icon for the current text direction.
IconData forwardArrowIcon(BuildContext context) {
  return Icons.arrow_forward;
}

/// Returns the correct forward iOS-style arrow icon for the current text direction.
IconData forwardIosArrowIcon(BuildContext context) {
  return Icons.arrow_forward_ios_rounded;
}

/// Returns the correct chevron icon for "end" direction.
IconData chevronEndIcon(BuildContext context) {
  return Icons.chevron_right;
}

/// Whether the current text direction is RTL.
bool isRtl(BuildContext context) {
  return Directionality.of(context) == TextDirection.rtl;
}
