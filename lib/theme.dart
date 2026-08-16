import 'package:flutter/material.dart';

/// Палітра у стилі iOS (Apple HIG): світлий згрупований фон, білі картки,
/// волосяні розділювачі, системні кольори. Бренд-акцент — зелений.
class AppColors {
  static const bg = Color(0xFFF2F2F7);       // iOS systemGroupedBackground
  static const surface = Color(0xFFFFFFFF);  // картки / рядки
  static const surface2 = Color(0xFFEFEFF4); // чіпи/треки
  static const accent = Color(0xFF12A15A);   // бренд-зелений (акцент/ціни)
  static const accentInk = Color(0xFFFFFFFF);
  static const accentSoft = Color(0xFFE3F3EA);
  static const green = Color(0xFF12A15A);
  static const amber = Color(0xFFFF9500);    // iOS orange (жири/калорії)
  static const blue = Color(0xFF007AFF);     // iOS blue (білки)
  static const carbs = Color(0xFFFF6B5E);    // корал (вуглеводи)
  static const warn = Color(0xFFFF3B30);     // iOS red
  static const text = Color(0xFF1C1C1E);     // iOS label
  static const muted = Color(0xFF8E8E93);    // iOS secondary label / systemGray
  static const line = Color(0xFFD8D8DD);     // hairline separator
}

ThemeData buildTheme() {
  final base = ThemeData.light(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.accent, secondary: AppColors.accent, surface: AppColors.surface,
    ),
    // Системний шрифт Apple (SF Pro) на iOS; акуратний фолбек на web/Android.
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.text, displayColor: AppColors.text,
      fontFamily: '.SF Pro Text',
      fontFamilyFallback: const ['.SF Pro Display', 'SF Pro Text', 'Helvetica Neue', 'Arial'],
    ),
    dividerColor: AppColors.line,
  );
}
