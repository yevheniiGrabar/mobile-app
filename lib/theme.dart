import 'package:flutter/material.dart';

/// Палітра Mealize — СВІТЛА, зелений акцент (свіжо/їжа), у дусі Apple.
class AppColors {
  static const bg = Color(0xFFF5F7F4);       // світлий фон з легким зеленим
  static const surface = Color(0xFFFFFFFF);  // картки
  static const surface2 = Color(0xFFEDF1EC); // чіпи/підкладки
  static const accent = Color(0xFF12A15A);   // емералд-зелений (акцент/кнопки/ціни)
  static const accentInk = Color(0xFFFFFFFF);// текст/іконка НА акценті
  static const accentSoft = Color(0xFFE1F3E8);// тонована зелена підкладка
  static const green = Color(0xFF12A15A);    // ціни/економія = акцент
  static const amber = Color(0xFFE0A020);    // калорії/жири
  static const blue = Color(0xFF3B82F6);     // білки
  static const carbs = Color(0xFF34C759);    // вуглеводи
  static const warn = Color(0xFFD6533F);
  static const text = Color(0xFF14181F);
  static const muted = Color(0xFF6B7280);
  static const line = Color(0xFFE5EAE4);
}

ThemeData buildTheme() {
  final base = ThemeData.light(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.accent, secondary: AppColors.accent, surface: AppColors.surface,
    ),
    textTheme: base.textTheme.apply(bodyColor: AppColors.text, displayColor: AppColors.text),
    dividerColor: AppColors.line,
  );
}
