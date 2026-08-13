import 'package:flutter/material.dart';

/// Палітра «Розумний кошик» — СВІТЛА тема (чисто, повітряно, у дусі Apple).
class AppColors {
  static const bg = Color(0xFFF6F5FA);       // фон (світлий з легким лавандовим)
  static const surface = Color(0xFFFFFFFF);  // картки
  static const surface2 = Color(0xFFEFEDF6); // чіпи/підкладки
  static const accent = Color(0xFF7C5CE6);   // фіолетовий (насичений для світлого фону)
  static const accentInk = Color(0xFFFFFFFF);// текст/іконка НА акценті
  static const accentSoft = Color(0xFFECE6FB);// тонована підкладка (аватари/квадрати)
  static const green = Color(0xFF12A150);    // ціни/економія
  static const amber = Color(0xFFD9911A);    // калорії/бали
  static const warn = Color(0xFFD6533F);
  static const text = Color(0xFF1B1B24);     // основний текст
  static const muted = Color(0xFF75758A);    // вторинний
  static const line = Color(0xFFE7E5EF);     // розділювачі/бордери
}

ThemeData buildTheme() {
  final base = ThemeData.light(useMaterial3: true);
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
