import 'package:flutter/material.dart';

/// Accesos cortos al `ColorScheme` activo (claro/oscuro) para que las
/// pantallas dejen de usar colores fijos de `AppColors` en roles
/// estructurales (fondo, superficie, texto, bordes) y sí respondan al tema
/// del sistema.
extension AppThemeX on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;

  /// Fondo general de pantalla.
  Color get bg => colors.surface;

  /// Superficie de tarjetas/paneles.
  Color get surface => colors.surface;

  /// Texto principal (equivalente a lo que antes era `AppColors.slate900`).
  Color get textPrimary => colors.onSurface;

  /// Texto secundario/atenuado (equivalente a `AppColors.slate600/700`).
  Color get textSecondary => colors.onSurfaceVariant;

  /// Bordes y separadores sutiles (equivalente a `Color(0xFFE2E8F0)`).
  Color get borderColor => colors.outlineVariant;
}
