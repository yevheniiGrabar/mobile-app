// Моделі даних + мок-меню (реальні дані підключимо через Silpo MCP пізніше).

class Ingredient {
  final String name;
  final String qty;
  final int price; // грн
  final String dept;
  final String store; // "Сільпо"
  const Ingredient(this.name, this.qty, this.price, this.dept, {this.store = 'Сільпо'});
}

class Meal {
  final String type; // Сніданок / Обід / Вечеря
  final String title;
  final String equipment; // Плита / Духовка ...
  final int minutes;
  final int kcal;
  final int price; // грн
  final List<Ingredient> ingredients;
  const Meal({
    required this.type,
    required this.title,
    required this.equipment,
    required this.minutes,
    required this.kcal,
    required this.price,
    this.ingredients = const [],
  });
}

class DayMenu {
  final String day;
  final List<Meal> meals;
  const DayMenu(this.day, this.meals);
  int get total => meals.fold(0, (s, m) => s + m.price);
  int get kcal => meals.fold(0, (s, m) => s + m.kcal);
}

/// Демо-меню на кілька днів.
final List<DayMenu> mockWeek = [
  DayMenu('Понеділок', const [
    Meal(type: 'Сніданок', title: 'Вівсяна каша з бананом та медом', equipment: 'Плита', minutes: 15, kcal: 380, price: 55, ingredients: [
      Ingredient('Вівсяні пластівці «Премія»', '400 г', 32, 'Бакалія'),
      Ingredient('Банан', '2 шт', 18, 'Овочі та фрукти'),
      Ingredient('Мед квітковий', '250 г', 89, 'Бакалія'),
    ]),
    Meal(type: 'Обід', title: 'Курячий бульйон з гречаною локшиною', equipment: 'Духовка', minutes: 30, kcal: 520, price: 82, ingredients: [
      Ingredient('Куряче філе', '1 кг', 149, 'М\'ясо та птиця'),
      Ingredient('Гречана локшина', '400 г', 44, 'Бакалія'),
      Ingredient('Морква рання', '1 кг', 20, 'Овочі та фрукти'),
    ]),
    Meal(type: 'Вечеря', title: 'Запечене куряче філе з картоплею', equipment: 'Духовка', minutes: 35, kcal: 610, price: 79, ingredients: [
      Ingredient('Картопля рання', '1 кг', 15, 'Овочі та фрукти'),
      Ingredient('Куряче філе', '0.5 кг', 75, 'М\'ясо та птиця'),
    ]),
  ]),
  DayMenu('Вівторок', const [
    Meal(type: 'Сніданок', title: 'Омлет із сиром та хлібом', equipment: 'Плита', minutes: 12, kcal: 420, price: 48, ingredients: [
      Ingredient('Яйця C0 10 шт', '1 уп', 78, 'Молочні продукти'),
      Ingredient('Сир твердий Пирятин', '200 г', 83, 'Молочні продукти'),
    ]),
    Meal(type: 'Обід', title: 'Плов з куркою та рисом', equipment: 'Мультиварка', minutes: 45, kcal: 640, price: 96, ingredients: [
      Ingredient('Рис «Премія»', '900 г', 44, 'Бакалія'),
      Ingredient('Куряче філе', '0.6 кг', 90, 'М\'ясо та птиця'),
    ]),
    Meal(type: 'Вечеря', title: 'Салат із запеченою рибою', equipment: 'Духовка', minutes: 25, kcal: 480, price: 120, ingredients: [
      Ingredient('Сьомга філе', '300 г', 199, 'Риба'),
      Ingredient('Огірки', '300 г', 22, 'Овочі та фрукти'),
    ]),
  ]),
  DayMenu('Середа', const [
    Meal(type: 'Сніданок', title: 'Сирники зі сметаною', equipment: 'Плита', minutes: 20, kcal: 450, price: 62),
    Meal(type: 'Обід', title: 'Суп з фрикадельками', equipment: 'Плита', minutes: 40, kcal: 500, price: 88),
    Meal(type: 'Вечеря', title: 'Тушкована картопля з цибулею', equipment: 'Плита', minutes: 35, kcal: 430, price: 54),
  ]),
];

/// Плоский список покупок з мок-меню (для екрана «Кошик»).
Map<String, List<Ingredient>> shoppingListByDept() {
  final map = <String, List<Ingredient>>{};
  for (final d in mockWeek) {
    for (final m in d.meals) {
      for (final i in m.ingredients) {
        map.putIfAbsent(i.dept, () => []).add(i);
      }
    }
  }
  return map;
}
