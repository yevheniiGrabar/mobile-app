import 'package:flutter/foundation.dart';

/// Запис у щоденнику харчування (одна з'їдена порція).
class DiaryEntry {
  final String title;
  final int grams, kcal, protein, fat, carbs;
  final String meal; // Сніданок / Обід / Вечеря / Перекус
  const DiaryEntry(this.title, this.grams, this.kcal, this.protein, this.fat, this.carbs,
      {this.meal = 'Перекус'});
}

/// Щоденник харчування (демо: тільки «сьогодні», локально в памʼяті).
/// Годує кільце калорій на Головній. Реальні цілі — з профілю/BFF пізніше.
class DiaryStore extends ChangeNotifier {
  DiaryStore._() {
    // Демо-сід: сніданок уже зʼїдено, щоб кільце не було порожнім.
    today.add(const DiaryEntry('Вівсяна каша з бананом та медом', 250, 238, 13, 8, 29, meal: 'Сніданок'));
  }
  static final DiaryStore instance = DiaryStore._();

  final List<DiaryEntry> today = [];

  // Денна ціль калорій — розраховується на екрані «Цілі калорій» (Mifflin-St Jeor).
  static int goalKcal = 1900;
  // Макро-цілі похідні від калорій (Б30% / Ж30% / В40%).
  static int get goalProtein => (goalKcal * 0.30 / 4).round();
  static int get goalFat => (goalKcal * 0.30 / 9).round();
  static int get goalCarbs => (goalKcal * 0.40 / 4).round();

  // Метрики користувача (демо-стан, щоб екран памʼятав введене).
  static int weightKg = 70, heightCm = 175, age = 30;
  static bool isMale = true;
  static String activity = 'moderate'; // low | moderate | high
  static String goalMode = 'maintain'; // lose | maintain | gain

  /// Зберегти метрики + розраховану ціль (оновлює кільце на Головній).
  void applyGoal({
    required int weightKg,
    required int heightCm,
    required int age,
    required bool isMale,
    required String activity,
    required String goalMode,
    required int kcal,
  }) {
    DiaryStore.weightKg = weightKg;
    DiaryStore.heightCm = heightCm;
    DiaryStore.age = age;
    DiaryStore.isMale = isMale;
    DiaryStore.activity = activity;
    DiaryStore.goalMode = goalMode;
    DiaryStore.goalKcal = kcal;
    notifyListeners();
  }

  int get kcal => today.fold(0, (s, e) => s + e.kcal);
  int get protein => today.fold(0, (s, e) => s + e.protein);
  int get fat => today.fold(0, (s, e) => s + e.fat);
  int get carbs => today.fold(0, (s, e) => s + e.carbs);

  /// Скільки калорій ще лишилось на сьогодні (не менше 0).
  int get remaining => (goalKcal - kcal).clamp(0, goalKcal);

  void add(DiaryEntry e) {
    today.add(e);
    notifyListeners();
  }

  void removeAt(int i) {
    if (i >= 0 && i < today.length) {
      today.removeAt(i);
      notifyListeners();
    }
  }
}
