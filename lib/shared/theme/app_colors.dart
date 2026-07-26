import 'package:flutter/material.dart';

abstract class AppColors {
  static const background = Color(0xFFF8FAFC);

  static const slate900 = Color(0xFF0F172A);
  static const slate700 = Color(0xFF334155);
  static const slate600 = Color(0xFF475569);
  static const slate500 = Color(0xFF64748B);
  static const slate400 = Color(0xFF94A3B8);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate100 = Color(0xFFF1F5F9);
  static const emerald600 = Color(0xFF059669);
  static const blue600 = Color(0xFF2563EB);
  static const purple600 = Color(0xFF9333EA);

  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF8FAFC);

  static const orange500 = Color(0xFFF97316);
  static const orange600 = Color(0xFFEA580C);

  static const primaryGradient = LinearGradient(
    colors: [orange500, orange600],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const success = Color(0xFF10B981);
  static const successBg = Color(0x1A10B981);

  static const danger = Color(0xFFEF4444);
  static const dangerBg = Color(0x1AEF4444);

  static const amber = Color(0xFFF59E0B);

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 20,
          spreadRadius: 0,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get primaryButtonShadow => [
        BoxShadow(
          color: orange500.withValues(alpha: 0.20),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ];
}
