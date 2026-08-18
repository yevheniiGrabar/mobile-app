import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';
import '../models.dart';
import '../data/stores.dart';
import '../data/api/mealize_api.dart';
import '../data/plan_store.dart';
import '../data/menu_prefs.dart';
import '../format.dart';

/// Список покупок (Stitch): згруповано по відділах, картки з чекбоксами,
/// куплене — закреслено. Зверху — доказова економія (проти звичайних цін).
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _api = MealizeApi.instance;
  bool _busy = false;
  bool _cleared = false; // список очищено вручну → показуємо порожній стан, не демо

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
        // MCP не віддає checkout-лінк: кошик зібрано в акаунті Сільпо,
        // оформлення/оплату користувач завершує в застосунку Сільпо.
        final added = (co['added'] as num?)?.toInt() ?? 0;
        final total = (co['total'] as num?)?.toDouble();
        final sum = total != null ? ' на ~${uah(total)} ₴' : '';
        messenger.showSnackBar(SnackBar(
          content: Text('✅ Кошик зібрано в Сільпо: $added товарів$sum.\nВідкрий застосунок Сільпо, щоб оформити.'),
          duration: const Duration(seconds: 5)));
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
    final total = plan.optimizedTotal ?? plan.items.fold<double>(0, (s, i) => s + i.priceTotal);
    final saved = plan.items.fold<double>(0, (s, i) => s + i.saved); // сума знижок по позиціях
    _api.recordPurchase(
      total: total.round(),
      saved: saved.round(),
      mealPlanId: planId,
      items: [
        for (final it in plan.items)
          {
            'name': it.title.isNotEmpty ? it.title : it.ingredient,
            'qty': it.qty,
            'price': it.priceTotal.round(),
            if (it.oldPrice != null) 'old_price': (it.oldPrice! * it.qty).round(),
            'saved': it.saved.round(),
          },
      ],
    ).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: PlanStore.instance,
      builder: (context, _) {
        final ps = PlanStore.instance;
        if (ps.hasPlan) return _buildReal(context, ps);
        return _cleared ? _buildEmpty(context) : _buildMock(context);
      },
    );
  }

  /// Порожній стан після очищення списку.
  Widget _buildEmpty(BuildContext context) => CupertinoPageScaffold(
    backgroundColor: AppColors.bg,
    child: CustomScrollView(slivers: [
      const CupertinoSliverNavigationBar(backgroundColor: AppColors.bg, border: null, largeTitle: Text('Список')),
      SliverFillRemaining(hasScrollBody: false, child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
          Icon(CupertinoIcons.cart, size: 44, color: AppColors.muted),
          SizedBox(height: 12),
          Text('Список порожній', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          SizedBox(height: 6),
          Text('Склади меню на Головній — і список зʼявиться тут.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.muted)),
        ]),
      )),
    ]),
  );

  /// Реальний кошик із BFF (після «Скласти меню»): справжні товари + економія.
  Widget _buildReal(BuildContext context, PlanStore plan) {
    final pay = plan.optimizedTotal ?? plan.items.fold<double>(0, (s, i) => s + i.priceTotal);
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
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
          child: Row(children: [
            const Text('Кошик', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(width: 6),
            Text('(${plan.items.length})', style: const TextStyle(fontSize: 14, color: AppColors.muted, fontWeight: FontWeight.w600)),
            const Spacer(),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _busy ? null : _clearAll,
              child: const Padding(padding: EdgeInsets.all(6), child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(CupertinoIcons.trash, size: 15, color: AppColors.muted),
                SizedBox(width: 4),
                Text('Очистити', style: TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w600)),
              ])),
            ),
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
          Text('$count позицій', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
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

  Widget _totalPill(num total) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(CupertinoIcons.cart, size: 16, color: AppColors.accent),
      const SizedBox(width: 6),
      Text('Разом: ${uah(total)} ₴', style: const TextStyle(color: AppColors.accent, fontSize: 13.5, fontWeight: FontWeight.w800)),
    ]),
  );

  Widget _planItemRow(int i, PlanItem it) {
    final out = !it.available; // немає в наявності
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(children: [
          _thumb(it),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(it.title.isEmpty ? it.ingredient : it.title, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                color: out ? AppColors.muted : AppColors.text)),
            const SizedBox(height: 2),
            if (out)
              const Text('Немає в наявності', style: TextStyle(fontSize: 12, color: AppColors.warn, fontWeight: FontWeight.w700))
            else ...[
              Row(children: [
                Flexible(child: Text('для: ${it.ingredient}', maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.muted))),
                if (it.qty > 1) ...[
                  const SizedBox(width: 6),
                  Text('×${it.qty} уп.', style: const TextStyle(fontSize: 11.5, color: AppColors.text, fontWeight: FontWeight.w700)),
                ],
              ]),
              if (it.reason != null && it.reason!.isNotEmpty) ...[
                const SizedBox(height: 3),
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(6)),
                  child: Text('💡 ${it.reason}', style: const TextStyle(fontSize: 10, color: AppColors.accent, fontWeight: FontWeight.w700))),
              ],
            ],
          ])),
          const SizedBox(width: 8),
          // Немає в наявності → кнопка «Замінити» (ціну не показуємо).
          // Є в наявності → лише ціна (без кнопки).
          if (out)
            _replaceButton(it)
          else
            Text('${uah(it.priceTotal)} ₴', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.green)),
        ]),
    );
  }

  /// Мініатюра товару (фото Сільпо); неактивна, якщо товару немає.
  Widget _thumb(PlanItem it) {
    final img = ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 46, height: 46, color: AppColors.surface2,
        child: it.image != null && it.image!.isNotEmpty
            ? Image.network(it.image!, fit: BoxFit.cover, gaplessPlayback: true,
                errorBuilder: (_, _, _) => const Icon(CupertinoIcons.cart, color: AppColors.muted, size: 20))
            : const Icon(CupertinoIcons.cart, color: AppColors.muted, size: 20),
      ),
    );
    return it.available ? img : Opacity(opacity: 0.35, child: img);
  }

  /// Кнопка «Замінити» — лише для відсутніх товарів (свап на альтернативу).
  Widget _replaceButton(PlanItem it) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: (_busy || it.swapSku == null) ? null : () => _swapItem(it),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.accent, borderRadius: BorderRadius.circular(20)),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(CupertinoIcons.arrow_2_circlepath, size: 14, color: AppColors.accentInk),
        SizedBox(width: 5),
        Text('Замінити', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.accentInk)),
      ]),
    ),
  );

  Future<void> _clearAll() async {
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (c) => CupertinoAlertDialog(
        title: const Text('Очистити список?'),
        content: const Text('\nУсі товари буде видалено зі списку.'),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.of(c).pop(false), child: const Text('Скасувати')),
          CupertinoDialogAction(isDestructiveAction: true, onPressed: () => Navigator.of(c).pop(true), child: const Text('Очистити')),
        ],
      ),
    );
    if (ok == true) {
      setState(() => _cleared = true);
      PlanStore.instance.clear();
    }
  }

  Future<void> _swapItem(PlanItem it) async {
    if (it.swapSku == null) return;
    setState(() => _busy = true);
    try {
      final json = await _api.swap(PlanStore.instance.id!, it.id, it.swapSku!);
      final data = json['data'] as Map<String, dynamic>?;
      if (data != null) PlanStore.instance.setFromPlan(data);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Доказова економія: сума + % + порівняння двох кошиків.
  Widget _savingsCard(num regular, num pay, num saved, int pct) {
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
        Text('−${uah(saved)} ₴', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.accent, height: 1.1)),
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

  Widget _bar(String label, num amount, double frac, Color fill, Color amountColor, {bool strike = false}) {
    return Row(children: [
      SizedBox(width: 96, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600))),
      Expanded(child: Stack(children: [
        Container(height: 12, decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(6))),
        FractionallySizedBox(widthFactor: frac.clamp(0.05, 1.0),
          child: Container(height: 12, decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(6)))),
      ])),
      const SizedBox(width: 10),
      Text('${uah(amount)} ₴', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: amountColor,
        decoration: strike ? TextDecoration.lineThrough : null)),
    ]);
  }

  Widget _itemRow(String dept, int i, Ingredient it) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(children: [
          const Icon(CupertinoIcons.cart, color: AppColors.accent, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(it.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
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
            Text('${it.price} ₴', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.green)),
          ]),
        ]),
    );
  }
}
