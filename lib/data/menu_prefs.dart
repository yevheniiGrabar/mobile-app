import 'package:flutter/foundation.dart';

/// Спільні налаштування меню — редагуються з окремих екранів
/// (Склад сім'ї, Раціон і алергії, Тижневий бюджет), читаються при генерації.
class MenuPrefs extends ChangeNotifier {
  MenuPrefs._();
  static final MenuPrefs instance = MenuPrefs._();

  double budget = 2000;
  int people = 2;

  /// Режим генерації: 'economy' (ціна — акції/найдешевше) або 'quality' (склад/кращі товари).
  String mode = 'economy';

  /// Дозволене перевищення бюджету у % (лише для 'quality'). 0 = суворо в межах.
  int flexPct = 0;

  /// Додаткова сума понад базовий бюджет (₴) від flexPct.
  int get flexAmount => (budget * flexPct / 100).round();

  /// Система харчування (одна) — жорстке правило для агента.
  String dietSystem = 'omnivore';

  final Set<String> cuisines = {};       // м'які вподобання стилю
  final Set<String> healthFilters = {};  // цілі оптимізації складу
  final Set<String> allergies = {};      // жорсткі виключення
  final Set<String> equipment = {'Плита', 'Духовка'};

  /// Системи харчування: код → людська назва (код іде на бекенд).
  static const dietSystems = <String, String>{
    'omnivore': 'Звичайне',
    'vegetarian': 'Вегетаріанське',
    'vegan': 'Веганське',
    'pescetarian': 'Пескетаріанське',
    'keto': 'Кето',
    'paleo': 'Палео',
  };

  static const allCuisines = [
    'Домашня', 'Середземноморська', 'Італійська', 'Азійська',
    'Мексиканська', 'Американська', 'Близькосхідна',
  ];
  static const allHealthFilters = [
    'Менше цукру', 'Без доданого цукру', 'Менше солі', 'Менше жиру',
    'Більше білка', 'Більше клітковини',
  ];
  static const allAllergies = [
    'Горіхи', 'Лактоза', 'Глютен', 'Морепродукти', 'Яйця', 'Соя', 'Цитрусові',
    'Свинина', 'Червоне м\'ясо', 'Гриби', 'Алкоголь у стравах',
  ];
  static const allEquipment = [
    'Плита', 'Духовка', 'Мікрохвильовка', 'Мультиварка', 'Аерогриль', 'Блендер',
  ];

  /// Назва обраної системи харчування (для підпису).
  String get dietSystemLabel => dietSystems[dietSystem] ?? 'Звичайне';

  /// К-сть активних фільтрів раціону (для підпису у профілі).
  int get filtersCount =>
      cuisines.length + healthFilters.length + allergies.length +
      (dietSystem != 'omnivore' ? 1 : 0);

  void notify() => notifyListeners();
}
