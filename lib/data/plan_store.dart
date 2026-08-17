import 'package:flutter/foundation.dart';
import '../models.dart';

/// Позиція реального кошика (результат генерації BFF: matching + optimizer).
class PlanItem {
  final int id;
  final String ingredient, title, sku;
  final int qty, price, priceTotal, saved;
  final int? oldPrice, packSize, leftover;
  final String? reason;
  final bool isPromo, isPrivateLabel;
  const PlanItem(this.id, this.ingredient, this.title, this.sku, this.qty,
      this.price, this.priceTotal, this.isPromo, this.isPrivateLabel,
      {this.oldPrice, this.saved = 0, this.packSize, this.leftover, this.reason});

  factory PlanItem.fromJson(Map<String, dynamic> j) => PlanItem(
        (j['id'] ?? 0) as int,
        (j['ingredient'] ?? '').toString(),
        (j['title'] ?? '').toString(),
        (j['sku'] ?? '').toString(),
        (j['qty'] ?? 1) as int,
        (j['price'] ?? 0) as int,
        (j['price_total'] ?? j['price'] ?? 0) as int,
        j['is_promo'] == true,
        j['is_private_label'] == true,
        oldPrice: (j['old_price'] as num?)?.toInt(),
        saved: (j['saved'] as num?)?.toInt() ?? 0,
        packSize: (j['pack_size'] as num?)?.toInt(),
        leftover: (j['leftover'] as num?)?.toInt(),
        reason: (j['reason'] as String?),
      );
}

/// Останнє згенероване меню/кошик із BFF. Якщо є — екрани показують реальні
/// дані; якщо ні — демо-мок. Оновлюється після «Скласти меню».
class PlanStore extends ChangeNotifier {
  PlanStore._();
  static final PlanStore instance = PlanStore._();

  int? id;
  int? naiveTotal, optimizedTotal, savings;
  List<PlanItem> items = [];
  List<DayMenu> days = []; // згенероване меню на тиждень (для карток на Головній)

  bool get hasPlan => id != null && items.isNotEmpty;
  bool get hasMenu => days.isNotEmpty;

  /// Заповнити з відповіді GET /api/meal-plans/{id} (data: MealPlanResource).
  void setFromPlan(Map<String, dynamic> data) {
    id = data['id'] as int?;
    naiveTotal = data['naive_total'] as int?;
    optimizedTotal = data['optimized_total'] as int?;
    savings = data['savings'] as int?;
    items = ((data['items'] as List?) ?? const [])
        .map((e) => PlanItem.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
    days = _parseMenu(data['menu']);
    notifyListeners();
  }

  void clear() {
    id = null;
    naiveTotal = optimizedTotal = savings = null;
    items = [];
    days = [];
    notifyListeners();
  }

  static const _weekdays = ['', 'Понеділок', 'Вівторок', 'Середа', 'Четвер', 'П\'ятниця', 'Субота', 'Неділя'];
  static const _mealType = {'breakfast': 'Сніданок', 'lunch': 'Обід', 'dinner': 'Вечеря'};

  /// menu (plan_json) у список днів з Meal (фото через photo_hint).
  List<DayMenu> _parseMenu(dynamic menu) {
    if (menu is! Map) return [];
    final out = <DayMenu>[];
    for (final d in (menu['days'] as List?) ?? const []) {
      if (d is! Map) continue;
      final wd = (d['weekday'] as num?)?.toInt() ?? 0;
      final name = (wd >= 1 && wd <= 7) ? _weekdays[wd] : 'День';
      final meals = <Meal>[];
      for (final m in (d['meals'] as List?) ?? const []) {
        if (m is! Map) continue;
        final ings = <Ingredient>[];
        for (final ing in (m['ingredients'] as List?) ?? const []) {
          if (ing is! Map) continue;
          final qty = ing['qty'];
          final unit = (ing['unit'] ?? '').toString();
          ings.add(Ingredient(
            (ing['name'] ?? '').toString(),
            '${qty ?? ''} $unit'.trim(),
            0,
            (ing['category'] ?? 'Інше').toString(),
          ));
        }
        meals.add(Meal(
          type: _mealType[(m['type'] ?? '').toString()] ?? 'Страва',
          title: (m['title'] ?? '').toString(),
          equipment: '',
          minutes: (m['cook_minutes'] as num?)?.toInt() ?? 0,
          kcal: (m['kcal'] as num?)?.toInt() ?? 0,
          price: 0,
          img: '',
          photoHint: m['photo_hint']?.toString(),
          ingredients: ings,
        ));
      }
      out.add(DayMenu(name, meals));
    }
    return out;
  }
}
