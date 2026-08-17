import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';
import '../models.dart';
import '../data/stores.dart';
import '../data/api/mealize_api.dart';
import '../data/plan_store.dart';
import '../data/menu_prefs.dart';

/// Список покупок (Stitch): згруповано по відділах, картки з чекбоксами,
/// куплене — закреслено. Зверху — доказова економія (проти звичайних цін).
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _checked = <String>{}; // ключі куплених позицій
  final _api = MealizeApi.instance;
  bool _busy = false;

  String _key(String dept, int i) => '$dept#$i';

  /// Checkout через BFF. Якщо plan вже згенеровано — оформлюємо його id;
  /// інакше спершу генеруємо (демо), потім checkout → checkoutWebLink.
  Future<void> _checkout({int? planId}) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      int id;
      if (planId != null) {
        id = planId;
      } else {
        final gen = await _api.generateAndWait(MenuPrefs.instance.toRequestBody());
        final data = gen['data'] as Map<String, dynamic>?;
        if (data?['status'] != 'ready') {
          final err = (data?['error'] ?? '').toString();
          messenger.showSnackBar(SnackBar(
            content: Text(err.contains('401') ? 'Спочатку підключи Сільпо у Профілі' : 'Не готово: $err'),
            duration: const Duration(seconds: 4)));
          return;
        }
        PlanStore.instance.setFromPlan(data!);
        id = data['id'] as int;
      }
      final co = await _api.checkout(id);
      _recordPurchase(id); // подія для аналітики (fire-and-forget)
      final link = co['checkout_web'] as String?;
      if (link != null) {
        await launchUrl(Uri.parse(link), webOnlyWindowName: '_blank', mode: LaunchMode.externalApplication);
      } else {
        messenger.showSnackBar(const SnackBar(content: Text('Кошик зібрано, але лінку ще немає')));
      }
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(e.message.contains('кошик') ? 'Потрібен активний кошик у Сільпо' : 'Бекенд: ${e.message}'),
        duration: const Duration(seconds: 4)));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Бекенд недоступний — демо-режим')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Записати покупку в історію аналітики з поточного плану (не блокує UI).
  void _recordPurchase(int planId) {
    final plan = PlanStore.instance;
    if (!plan.hasPlan) return;
    final total = plan.optimizedTotal ?? plan.items.fold<int>(0, (s, i) => s + i.priceTotal);
    final saved = plan.items.fold<int>(0, (s, i) => s + i.saved); // сума знижок по позиціях
    _api.recordPurchase(
      total: total,
      saved: saved,
      mealPlanId: planId,
      items: [
        for (final it in plan.items)
          {
            'name': it.title.isNotEmpty ? it.title : it.ingredient,
            'qty': it.qty,
            'price': it.priceTotal,
            if (it.oldPrice != null) 'old_price': it.oldPrice! * it.qty,
            'saved': it.saved,
          },
      ],
    ).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: PlanStore.instance,
      builder: (context, _) =>
          PlanStore.instance.hasPlan ? _buildReal(context, PlanStore.instance) : _buildMock(context),
    );
  }

  /// Реальний кошик із BFF (після «Скласти меню»): справжні товари + економія.
  Widget _buildReal(BuildContext context, PlanStore plan) {
    final pay = plan.optimizedTotal ?? plan.items.fold<int>(0, (s, i) => s + i.priceTotal);
    final regular = plan.naiveTotal ?? pay;
    final saved = plan.savings ?? (regular - pay);
    final pct = regular > 0 ? (saved / regular * 100).round() : 0;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.bg,
      child: CustomScrollView(slivers: [
        const CupertinoSliverNavigationBar(backgroundColor: AppColors.bg, border: null, largeTitle: Text('Список')),
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(children: [
            _totalPill(pay),
            const Spacer(),
            Text('${plan.items.length} позицій · реальні ціни Сільпо', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ]),
        )),
        if (saved > 0) SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4), child: _savingsCard(regular, pay, saved, pct))),
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Row(children: [
            const Text('Кошик', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(width: 6),
            Text('(${plan.items.length})', style: const TextStyle(fontSize: 14, color: AppColors.muted, fontWeight: FontWeight.w600)),
          ]),
        )),
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.line)),
            child: Column(children: [
              for (int i = 0; i < plan.items.length; i++) ...[
                if (i > 0) const Divider(height: 1, thickness: 1, color: AppColors.line, indent: 56),
                _planItemRow(i, plan.items[i]),
              ],
            ]),
          ),
        )),
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
          child: SizedBox(width: double.infinity, child: CupertinoButton(
            color: AppColors.accent, borderRadius: BorderRadius.circular(14),
            onPressed: _busy ? null : () => _checkout(planId: plan.id),
            child: _busy
                ? const CupertinoActivityIndicator(color: AppColors.accentInk)
                : const Text('Замовити в Сільпо', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.accentInk)),
          )),
        )),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ]),
    );
  }

  Widget _buildMock(BuildContext context) {
    final byDept = shoppingListByDept();
    final items = byDept.values.expand((e) => e).toList();
    final pay = items.fold<int>(0, (s, i) => s + i.price);              // до сплати (з акціями)
    final regular = items.fold<int>(0, (s, i) => s + (i.oldPrice ?? i.price)); // без акцій
    final saved = regular - pay;
    final pct = regular > 0 ? (saved / regular * 100).round() : 0;
    final count = items.length;
    final store = StoreRegistry.instance.active.info;
    final canOrder = store.canOrder;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.bg,
      child: CustomScrollView(slivers: [
      const CupertinoSliverNavigationBar(
        backgroundColor: AppColors.bg, border: null, largeTitle: Text('Список')),
      SliverToBoxAdapter(child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.receipt_long, size: 16, color: AppColors.accent),
              const SizedBox(width: 6),
              Text('Разом: $pay ₴', style: const TextStyle(color: AppColors.accent, fontSize: 13.5, fontWeight: FontWeight.w800)),
            ]),
          ),
          const Spacer(),
          Text('$count позицій · ${_checked.length} куплено', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        ]),
      )),
      // Картка «доказова економія»
      if (saved > 0) SliverToBoxAdapter(child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
        child: _savingsCard(regular, pay, saved, pct),
      )),
      for (final entry in byDept.entries) ...[
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Row(children: [
            Text(entry.key, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(width: 6),
            Text('(${entry.value.length})', style: const TextStyle(fontSize: 14, color: AppColors.muted, fontWeight: FontWeight.w600)),
          ]),
        )),
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.line)),
            child: Column(children: [
              for (int i = 0; i < entry.value.length; i++) ...[
                if (i > 0) const Divider(height: 1, thickness: 1, color: AppColors.line, indent: 56),
                _itemRow(entry.key, i, entry.value[i]),
              ],
            ]),
          ),
        )),
      ],
      SliverToBoxAdapter(child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
        child: SizedBox(width: double.infinity, child: CupertinoButton(
          color: AppColors.accent, borderRadius: BorderRadius.circular(14),
          onPressed: _busy
              ? null
              : (canOrder
                  ? () => _checkout()
                  : () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Список готовий. Замовлення для «${store.name}» — скоро'),
                      duration: const Duration(seconds: 2)))),
          child: _busy
              ? const CupertinoActivityIndicator(color: AppColors.accentInk)
              : Text(canOrder ? 'Замовити в ${store.name}' : 'Згенерувати список',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.accentInk)),
        )),
      )),
      const SliverToBoxAdapter(child: SizedBox(height: 100)),
    ]));
  }

  Widget _totalPill(int total) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(CupertinoIcons.cart, size: 16, color: AppColors.accent),
      const SizedBox(width: 6),
      Text('Разом: $total ₴', style: const TextStyle(color: AppColors.accent, fontSize: 13.5, fontWeight: FontWeight.w800)),
    ]),
  );

  Widget _planItemRow(int i, PlanItem it) {
    final key = 'plan#$i';
    final done = _checked.contains(key);
    return InkWell(
      onTap: () => setState(() => done ? _checked.remove(key) : _checked.add(key)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(children: [
          Icon(done ? Icons.check_circle : Icons.circle_outlined, color: done ? AppColors.accent : AppColors.muted, size: 24),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(it.title.isEmpty ? it.ingredient : it.title, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                color: done ? AppColors.muted : AppColors.text, decoration: done ? TextDecoration.lineThrough : null)),
            const SizedBox(height: 2),
            Row(children: [
              Text('для: ${it.ingredient}', style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
              if (it.isPromo) ...[
                const SizedBox(width: 6),
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(6)),
                  child: const Text('Акція', style: TextStyle(fontSize: 10, color: AppColors.accent, fontWeight: FontWeight.w700))),
              ],
            ]),
          ])),
          Text('${it.priceTotal} ₴', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
            color: done ? AppColors.muted : AppColors.green, decoration: done ? TextDecoration.lineThrough : null)),
        ]),
      ),
    );
  }

  /// Доказова економія: сума + % + порівняння двох кошиків.
  Widget _savingsCard(int regular, int pay, int saved, int pct) {
    final frac = regular > 0 ? pay / regular : 1.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [AppColors.accentSoft, AppColors.surface]),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.savings_outlined, size: 18, color: AppColors.accent),
          const SizedBox(width: 8),
          const Text('З Mealize ви економите', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(20)),
            child: Text('−$pct%', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800))),
        ]),
        const SizedBox(height: 6),
        Text('−$saved ₴', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.accent, height: 1.1)),
        const SizedBox(height: 14),
        _bar('Звичайна ціна', regular, 1.0, AppColors.line, AppColors.muted, strike: true),
        const SizedBox(height: 8),
        _bar('З Mealize', pay, frac, AppColors.accent, AppColors.text),
        const SizedBox(height: 10),
        const Text('Проти звичайних цін у Сільпо — економія на акціях та уцінках',
          style: TextStyle(fontSize: 11, color: AppColors.muted)),
      ]),
    );
  }

  Widget _bar(String label, int amount, double frac, Color fill, Color amountColor, {bool strike = false}) {
    return Row(children: [
      SizedBox(width: 96, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600))),
      Expanded(child: Stack(children: [
        Container(height: 12, decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(6))),
        FractionallySizedBox(widthFactor: frac.clamp(0.05, 1.0),
          child: Container(height: 12, decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(6)))),
      ])),
      const SizedBox(width: 10),
      Text('$amount ₴', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: amountColor,
        decoration: strike ? TextDecoration.lineThrough : null)),
    ]);
  }

  Widget _itemRow(String dept, int i, Ingredient it) {
    final key = _key(dept, i);
    final done = _checked.contains(key);
    return InkWell(
      onTap: () => setState(() => done ? _checked.remove(key) : _checked.add(key)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(children: [
          Icon(done ? Icons.check_circle : Icons.circle_outlined,
            color: done ? AppColors.accent : AppColors.muted, size: 24),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(it.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
              color: done ? AppColors.muted : AppColors.text,
              decoration: done ? TextDecoration.lineThrough : null)),
            const SizedBox(height: 2),
            Row(children: [
              Text('${it.qty} · ${it.store}', style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
              if (it.onSale) ...[
                const SizedBox(width: 6),
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(6)),
                  child: Text('Акція −${it.saved} ₴', style: const TextStyle(fontSize: 10, color: AppColors.accent, fontWeight: FontWeight.w700))),
              ],
            ]),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (it.onSale)
              Text('${it.oldPrice} ₴', style: const TextStyle(fontSize: 11, color: AppColors.muted, decoration: TextDecoration.lineThrough)),
            Text('${it.price} ₴', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
              color: done ? AppColors.muted : AppColors.green,
              decoration: done ? TextDecoration.lineThrough : null)),
          ]),
        ]),
      ),
    );
  }
}
