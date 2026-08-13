import 'package:flutter/material.dart';
import '../theme.dart';
import '../models.dart';
import '../data/stores.dart';

/// Список покупок (Stitch): згруповано по відділах, картки з чекбоксами,
/// куплене — закреслено. Оформлення через активний магазин (регіон-aware).
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _checked = <String>{}; // ключі куплених позицій

  String _key(String dept, int i) => '$dept#$i';

  @override
  Widget build(BuildContext context) {
    final byDept = shoppingListByDept();
    final total = byDept.values.expand((e) => e).fold<int>(0, (s, i) => s + i.price);
    final count = byDept.values.fold<int>(0, (s, e) => s + e.length);
    final store = StoreRegistry.instance.active.info;
    final canOrder = store.canOrder;

    return CustomScrollView(slivers: [
      SliverAppBar(pinned: true, backgroundColor: AppColors.bg, elevation: 0, titleSpacing: 16,
        title: const Text('Список покупок', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22))),
      SliverToBoxAdapter(child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.receipt_long, size: 16, color: AppColors.accent),
              const SizedBox(width: 6),
              Text('Разом: $total ₴', style: const TextStyle(color: AppColors.accent, fontSize: 13.5, fontWeight: FontWeight.w800)),
            ]),
          ),
          const Spacer(),
          Text('$count позицій · ${_checked.length} куплено', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        ]),
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
        child: SizedBox(width: double.infinity, child: FilledButton.icon(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(canOrder
              ? 'Оформлення в ${store.name} — checkout-лінк підключимо через MCP'
              : 'Список готовий. Замовлення для «${store.name}» — скоро'),
            duration: const Duration(seconds: 2))),
          style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: AppColors.accentInk, padding: const EdgeInsets.symmetric(vertical: 16)),
          icon: Icon(canOrder ? Icons.shopping_bag_outlined : Icons.list_alt),
          label: Text(canOrder ? 'Замовити в ${store.name}' : 'Згенерувати список',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        )),
      )),
      const SliverToBoxAdapter(child: SizedBox(height: 100)),
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
            Text('${it.qty} · ${it.store}', style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
          ])),
          Text('${it.price} ₴', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
            color: done ? AppColors.muted : AppColors.green,
            decoration: done ? TextDecoration.lineThrough : null)),
        ]),
      ),
    );
  }
}
