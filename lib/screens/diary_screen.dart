import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../data/diary.dart';
import '../widgets/nutrition_rings_card.dart';

/// Щоденник харчування (сьогодні): кільця калорій + записи, згруповані
/// за прийомами їжі (Сніданок / Обід / Вечеря / Перекус).
class DiaryScreen extends StatelessWidget {
  const DiaryScreen({super.key});

  /// Порядок прийомів у списку (перекуси — останні; далі зʼявляться інші).
  static const _order = ['Сніданок', 'Обід', 'Вечеря', 'Перекус'];

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.bg,
      child: CustomScrollView(slivers: [
        const CupertinoSliverNavigationBar(
          backgroundColor: AppColors.bg, border: null, largeTitle: Text('Щоденник')),
        SliverToBoxAdapter(child: AnimatedBuilder(
          animation: DiaryStore.instance,
          builder: (context, _) {
            final ds = DiaryStore.instance;
            return Padding(padding: const EdgeInsets.all(16), child: Column(children: [
              const NutritionRingsCard(),
              const SizedBox(height: 16),
              if (ds.today.isEmpty)
                const Padding(padding: EdgeInsets.only(top: 40),
                  child: Center(child: Text('Ще нічого не записано.\nЗапиши порцію з екрана страви.',
                    textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted))))
              else
                ..._groupedByMeal(context, ds),
              const SizedBox(height: 90),
            ]));
          },
        )),
      ]),
    );
  }

  /// Записи, згруповані за прийомом їжі, у фіксованому порядку.
  List<Widget> _groupedByMeal(BuildContext context, DiaryStore ds) {
    // meal → список (оригінальний індекс, запис) для коректного видалення.
    final groups = <String, List<(int, DiaryEntry)>>{};
    for (var i = 0; i < ds.today.length; i++) {
      final e = ds.today[i];
      groups.putIfAbsent(e.meal, () => []).add((i, e));
    }
    // Порядок: спершу відомі прийоми, потім будь-які інші.
    final meals = [
      ..._order.where(groups.containsKey),
      ...groups.keys.where((m) => !_order.contains(m)),
    ];

    final out = <Widget>[];
    for (final meal in meals) {
      final items = groups[meal]!;
      final kcal = items.fold<int>(0, (s, x) => s + x.$2.kcal);
      out.add(_mealHeader(meal, kcal));
      for (final (idx, e) in items) {
        out.add(_entryRow(context, ds, idx, e));
      }
    }
    return out;
  }

  Widget _mealHeader(String meal, int kcal) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
    child: Row(children: [
      Icon(_mealIcon(meal), size: 16, color: AppColors.accent),
      const SizedBox(width: 6),
      Text(meal, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
      const Spacer(),
      Text('$kcal ккал', style: const TextStyle(fontSize: 12.5, color: AppColors.muted, fontWeight: FontWeight.w700)),
    ]),
  );

  IconData _mealIcon(String meal) => switch (meal) {
    'Сніданок' => Icons.wb_sunny_outlined,
    'Обід' => Icons.restaurant,
    'Вечеря' => Icons.nightlight_outlined,
    _ => Icons.cookie_outlined, // перекус
  };

  Widget _entryRow(BuildContext context, DiaryStore ds, int i, DiaryEntry e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.line)),
      child: Row(children: [
        Container(width: 40, height: 40, alignment: Alignment.center,
          decoration: const BoxDecoration(color: AppColors.accentSoft, shape: BoxShape.circle),
          child: const Icon(Icons.restaurant, size: 18, color: AppColors.accent)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(e.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text('${e.grams} г · Б ${e.protein} · Ж ${e.fat} · В ${e.carbs}', style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
        ])),
        Text('${e.kcal} ккал', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.accent)),
        IconButton(
          onPressed: () => ds.removeAt(i),
          icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.muted),
          visualDensity: VisualDensity.compact,
        ),
      ]),
    );
  }
}
