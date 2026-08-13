import 'package:flutter/material.dart';
import '../theme.dart';
import '../models.dart';
import '../widgets/meal_card.dart';

/// Рецепти (Stitch): перегляд усіх страв з фільтрами. Тап → екран рецепта.
class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});
  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  static const _filters = ['Усі', 'Сніданок', 'Обід', 'Вечеря', 'До 20 хв'];
  String _active = 'Усі';

  List<Meal> get _all {
    final seen = <String>{};
    final list = <Meal>[];
    for (final d in mockWeek) {
      for (final m in d.meals) {
        if (seen.add(m.title)) list.add(m);
      }
    }
    return list;
  }

  List<Meal> get _filtered {
    switch (_active) {
      case 'До 20 хв':
        return _all.where((m) => m.minutes <= 20).toList();
      case 'Усі':
        return _all;
      default:
        return _all.where((m) => m.type == _active).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final meals = _filtered;
    return CustomScrollView(slivers: [
      SliverAppBar(pinned: true, backgroundColor: AppColors.bg, elevation: 0, titleSpacing: 16,
        title: const Text('Рецепти', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22))),
      SliverToBoxAdapter(child: SizedBox(height: 48, child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: _filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (c, i) {
          final f = _filters[i];
          final sel = f == _active;
          return GestureDetector(
            onTap: () => setState(() => _active = f),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: sel ? AppColors.accent : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sel ? AppColors.accent : AppColors.line)),
              child: Text(f, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                color: sel ? AppColors.accentInk : AppColors.text)),
            ),
          );
        },
      ))),
      const SliverToBoxAdapter(child: SizedBox(height: 8)),
      SliverList(delegate: SliverChildBuilderDelegate((c, i) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: MealCard(meal: meals[i]),
      ), childCount: meals.length)),
      const SliverToBoxAdapter(child: SizedBox(height: 100)),
    ]);
  }
}
