import 'package:flutter/foundation.dart';

/// Запис у щоденнику харчування (одна з'їдена порція).
class DiaryEntry {
  final String title;
  final int grams, kcal, protein, fat, carbs;
  const DiaryEntry(this.title, this.grams, this.kcal, this.protein, this.fat, this.carbs);
}

/// Щоденник харчування (демо: тільки «сьогодні», локально в памʼяті).
/// Годує кільце калорій на Головній. Реальні цілі — з профілю/BFF пізніше.
class DiaryStore extends ChangeNotifier {
  DiaryStore._() {
    // Демо-сід: сніданок уже зʼїдено, щоб кільце не було порожнім.
    today.add(const DiaryEntry('Вівсяна каша з бананом та медом', 250, 238, 13, 8, 29));
  }
  static final DiaryStore instance = DiaryStore._();

  final List<DiaryEntry> today = [];

  // Денні цілі (демо; підключимо Mifflin-St Jeor з профілю).
  static const int goalKcal = 1900, goalProtein = 100, goalFat = 60, goalCarbs = 250;

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
