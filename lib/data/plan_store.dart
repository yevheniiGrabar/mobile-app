import 'package:flutter/foundation.dart';

/// Позиція реального кошика (результат генерації BFF: matching + optimizer).
class PlanItem {
  final int id;
  final String ingredient, title, sku;
  final int qty, price, priceTotal;
  final bool isPromo, isPrivateLabel;
  const PlanItem(this.id, this.ingredient, this.title, this.sku, this.qty,
      this.price, this.priceTotal, this.isPromo, this.isPrivateLabel);

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

  bool get hasPlan => id != null && items.isNotEmpty;

  /// Заповнити з відповіді GET /api/meal-plans/{id} (data: MealPlanResource).
  void setFromPlan(Map<String, dynamic> data) {
    id = data['id'] as int?;
    naiveTotal = data['naive_total'] as int?;
    optimizedTotal = data['optimized_total'] as int?;
    savings = data['savings'] as int?;
    items = ((data['items'] as List?) ?? const [])
        .map((e) => PlanItem.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
    notifyListeners();
  }

  void clear() {
    id = null;
    naiveTotal = optimizedTotal = savings = null;
    items = [];
    notifyListeners();
  }
}
