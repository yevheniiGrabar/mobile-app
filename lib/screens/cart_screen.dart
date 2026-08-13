import 'package:flutter/material.dart';
import '../theme.dart';
import '../models.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final byDept = shoppingListByDept();
    final total = byDept.values.expand((e) => e).fold<int>(0, (s, i) => s + i.price);
    final count = byDept.values.fold<int>(0, (s, e) => s + e.length);

    return CustomScrollView(slivers: [
      SliverAppBar(pinned: true, backgroundColor: AppColors.bg,
        title: const Text('Розумний список', style: TextStyle(fontWeight: FontWeight.w800))),
      SliverToBoxAdapter(child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Загальна вартість кошика', style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('$total ₴', style: const TextStyle(color: AppColors.green, fontSize: 30, fontWeight: FontWeight.w900)),
              Text('$count позицій', style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
            ]),
            const SizedBox(height: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.accentInk, borderRadius: BorderRadius.circular(8)),
              child: const Text('Зекономлено ≈ 214 ₴ на акціях', style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w600))),
            const SizedBox(height: 14),
            SizedBox(width: double.infinity, child: FilledButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Оформлення в Сільпо — checkout-лінк підключимо через MCP'), duration: Duration(seconds: 2))),
              style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: AppColors.accentInk, padding: const EdgeInsets.symmetric(vertical: 14)),
              icon: const Icon(Icons.local_shipping_outlined),
              label: const Text('Оформити в Сільпо', style: TextStyle(fontWeight: FontWeight.w700)),
            )),
          ]),
        ),
      )),
      for (final entry in byDept.entries) ...[
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text('${entry.key}  (${entry.value.length})', style: const TextStyle(fontWeight: FontWeight.w700)),
        )),
        SliverList(delegate: SliverChildBuilderDelegate((c, i) {
          final it = entry.value[i];
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
              child: Row(children: [
                const Icon(Icons.check_box_outline_blank, color: AppColors.muted, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(it.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  Text('${it.qty} · ${it.store}', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                ])),
                Text('${it.price} ₴', style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w700)),
              ]),
            ),
          );
        }, childCount: entry.value.length)),
      ],
      const SliverToBoxAdapter(child: SizedBox(height: 90)),
    ]);
  }
}
