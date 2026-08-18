import 'package:flutter/foundation.dart';
import '../models.dart';

/// Позиція реального кошика (результат генерації BFF: matching + optimizer).
class PlanItem {
  final int id;
  final String ingredient, title, sku;
  final int qty;
  final double price, priceTotal, saved; // ₴ з копійками
  final double? oldPrice;
  final int? packSize, leftover;
  final String? reason, image, swapSku;
  final bool isPromo, isPrivateLabel, available;
  const PlanItem(this.id, this.ingredient, this.title, this.sku, this.qty,
      this.price, this.priceTotal, this.isPromo, this.isPrivateLabel,
      {this.oldPrice, this.saved = 0, this.packSize, this.leftover, this.reason,
       this.image, this.swapSku, this.available = true});

  factory PlanItem.fromJson(Map<String, dynamic> j) => PlanItem(
        (j['id'] ?? 0) as int,
        (j['ingredient'] ?? '').toString(),
        (j['title'] ?? '').toString(),
        (j['sku'] ?? '').toString(),
        (j['qty'] ?? 1) as int,
        (j['price'] as num?)?.toDouble() ?? 0,
        (j['price_total'] as num?)?.toDouble() ?? (j['price'] as num?)?.toDouble() ?? 0,
        j['is_promo'] == true,
        j['is_private_label'] == true,
        oldPrice: (j['old_price'] as num?)?.toDouble(),
        saved: (j['saved'] as num?)?.toDouble() ?? 0,
        packSize: (j['pack_size'] as num?)?.toInt(),
        leftover: (j['leftover'] as num?)?.toInt(),
        reason: (j['reason'] as String?),
        image: (j['image'] as String?),
        swapSku: (j['swap_sku'] as String?),
        available: j['available'] != false,
      );
}

/// Останнє згенероване меню/кошик із BFF. Якщо є — екрани показують реальні
/// дані; якщо ні — демо-мок. Оновлюється після «Скласти меню».
class PlanStore extends ChangeNotifier {
  PlanStore._();
  static final PlanStore instance = PlanStore._();

  int? id;
  double? naiveTotal, optimizedTotal, savings; // ₴ з копійками
  int shoppingDays = 7; // горизонт списку покупок (днів)
  List<PlanItem> items = [];
  List<DayMenu> days = []; // згенероване меню на тиждень (для карток на Головній)

  bool get hasPlan => id != null && items.isNotEmpty;
  bool get hasMenu => days.isNotEmpty;

  /// Заповнити з відповіді GET /api/meal-plans/{id} (data: MealPlanResource).
  void setFromPlan(Map<String, dynamic> data) {
    id = data['id'] as int?;
    naiveTotal = (data['naive_total'] as num?)?.toDouble();
    optimizedTotal = (data['optimized_total'] as num?)?.toDouble();
    savings = (data['savings'] as num?)?.toDouble();
    shoppingDays = (data['shopping_days'] as num?)?.toInt() ?? 7;
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
          price: (m['price'] as num?)?.toInt() ?? 0,
          img: '',
          photoHint: m['photo_hint']?.toString(),
          note: m['note']?.toString(),
          ingredients: ings,
        ));
      }
      out.add(DayMenu(name, meals));
    }
    return out;
  }
}
