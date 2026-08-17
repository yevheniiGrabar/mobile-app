import 'package:flutter/foundation.dart';

/// Спільні налаштування меню — редагуються з окремих екранів
/// (Склад сім'ї, Раціон і алергії), читаються при генерації.
class MenuPrefs extends ChangeNotifier {
  MenuPrefs._();
  static final MenuPrefs instance = MenuPrefs._();

  double budget = 2000;
  int people = 2;
  String dietStyle = 'pp';

  /// Режим генерації: 'economy' (ціна — акції/найдешевше) або 'quality' (склад/кращі товари).
  String mode = 'economy';

  /// Дозволене перевищення бюджету у % (лише для 'quality'). 0 = суворо в межах.
  int flexPct = 0;

  /// Додаткова сума понад базовий бюджет (₴) від flexPct.
  int get flexAmount => (budget * flexPct / 100).round();

  final Set<String> prefs = {'ПП'};
  final Set<String> allergies = {};
  final Set<String> equipment = {'Плита', 'Духовка'};

  static const allPrefs = ['ПП', 'Білкове', 'Овочі', 'Бюджетно', 'Здивуй мене'];
  static const allAllergies = ['Горіхи', 'Лактоза', 'Глютен', 'Морепродукти', 'Яйця', 'Соя', 'Цитрусові'];
  static const allEquipment = ['Плита', 'Духовка', 'Мікрохвильовка', 'Мультиварка', 'Аерогриль', 'Блендер'];

  /// К-сть активних фільтрів раціону (для підпису у профілі).
  int get filtersCount => prefs.length + allergies.length;

  /// Мапа стилю харчування для API (перший обраний преференс).
  String get diet => switch (prefs.isNotEmpty ? prefs.first : 'ПП') {
        'Білкове' => 'protein',
        'Овочі' => 'veggie',
        'Бюджетно' => 'budget',
        'Здивуй мене' => 'surprise',
        _ => 'pp',
      };

  void notify() => notifyListeners();
}
