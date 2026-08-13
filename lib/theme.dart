import 'package:flutter/material.dart';

/// Палітра «Розумний кошик» (тёмна тема, фіолетовий акцент — вайб прототипу).
class AppColors {
  static const bg = Color(0xFF0E0E13);
  static const surface = Color(0xFF1A1A22);
  static const surface2 = Color(0xFF23232E);
  static const accent = Color(0xFFB9A7F5); // фіолетовий
  static const accentInk = Color(0xFF2A2140);
  static const green = Color(0xFF7CE7A6); // ціни/економія
  static const amber = Color(0xFFF4C24E); // бали
  static const warn = Color(0xFFE07A6B);
  static const text = Color(0xFFECECF2);
  static const muted = Color(0xFF9A9AAB);
  static const line = Color(0xFF2C2C38);
}

ThemeData buildTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.accent,
      secondary: AppColors.accent,
      surface: AppColors.surface,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
    dividerColor: AppColors.line,
  );
}
