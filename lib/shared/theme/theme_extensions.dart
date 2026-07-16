import 'package:flutter/material.dart';

extension AppThemeX on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;

  Color get bg => colors.surface;

  Color get surface => colors.surface;

  Color get textPrimary => colors.onSurface;

  Color get textSecondary => colors.onSurfaceVariant;

  Color get borderColor => colors.outlineVariant;
}
