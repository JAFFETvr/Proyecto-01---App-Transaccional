import 'package:flutter/material.dart';

/// ToolShare – Sistema de Colores "Fintech Industrial"
abstract class AppColors {
  // ── Fondo general ──────────────────────────────────────────────────────────
  /// Gris casi-blanco para que las fotos resalten sobre él.
  static const background = Color(0xFFF8FAFC);

  // ── Estructura / Texto ─────────────────────────────────────────────────────
  /// Azul Pizarra muy oscuro: AppBar, títulos, menús.
  static const slate900 = Color(0xFF0F172A);
  static const slate700 = Color(0xFF334155);
  static const slate600 = Color(0xFF475569);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate100 = Color(0xFFF1F5F9);

  // ── Superficie ─────────────────────────────────────────────────────────────
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF8FAFC);

  // ── Primario / Acento naranja ──────────────────────────────────────────────
  static const orange500 = Color(0xFFF97316);
  static const orange600 = Color(0xFFEA580C);

  /// Degradado naranja para todos los botones de acción principal.
  static const primaryGradient = LinearGradient(
    colors: [orange500, orange600],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Estados semánticos ─────────────────────────────────────────────────────
  /// Éxito / Disponible
  static const success = Color(0xFF10B981);
  static const successBg = Color(0x1A10B981); // 10 % opacidad

  /// Error / Alerta / Rechazado
  static const danger = Color(0xFFEF4444);
  static const dangerBg = Color(0x1AEF4444); // 10 % opacidad

  /// Advertencia (info neutral)
  static const amber = Color(0xFFF59E0B);

  // ── Sombra premium de tarjetas ─────────────────────────────────────────────
  /// Sombra muy suave y desvanecida → sensación de "float".
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 20,
          spreadRadius: 0,
          offset: const Offset(0, 8),
        ),
      ];

  /// Sombra naranja para botones de acción principal.
  static List<BoxShadow> get primaryButtonShadow => [
        BoxShadow(
          color: orange500.withOpacity(0.20),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ];
}
