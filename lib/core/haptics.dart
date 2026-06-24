import 'package:flutter/services.dart';

/// Tiny haptic vocabulary so interactions feel physical, not flat.
class Haptics {
  static void tap() => HapticFeedback.lightImpact();
  static void select() => HapticFeedback.selectionClick();
  static void success() => HapticFeedback.mediumImpact();
}
