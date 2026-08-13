import 'package:flutter/material.dart';
import '../theme.dart';
import '../models.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(slivers: [
      SliverAppBar(
        pinned: true,
        backgroundColor: AppColors.bg,
        title: const Text('Меню на тиждень', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: const [
          Padding(padding: EdgeInsets.only(right: 16), child: Center(
            child: _Pill(text: '1 460 / 1 500 ₴', color: AppColors.accent))),
        ],
      ),
      SliverList(delegate: SliverChildBuilderDelegate((c, i) {
        final day = mockWeek[i];
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(day.day, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                Text('За день: ${day.total} ₴  ·  ${day.kcal} ккал',
                  style: const TextStyle(color: AppColors.green, fontSize: 12.5, fontWeight: FontWeight.w600)),
              ]),
            ),
            for (final m in day.meals) _MealCard(meal: m),
            const SizedBox(height: 8),
          ]),
        );
      }, childCount: mockWeek.length)),
      const SliverToBoxAdapter(child: SizedBox(height: 90)),
    ]);
  }
}

class _MealCard extends StatelessWidget {
  final Meal meal;
  const _MealCard({required this.meal});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Pill(text: meal.type, color: AppColors.surface2, textColor: AppColors.muted),
        const SizedBox(height: 8),
        Text(meal.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Row(children: [
          _MiniTag(icon: Icons.local_fire_department, text: '${meal.kcal} ккал', color: AppColors.amber),
          const SizedBox(width: 10),
          _MiniTag(icon: Icons.kitchen, text: meal.equipment, color: AppColors.green),
          const SizedBox(width: 10),
          _MiniTag(icon: Icons.timer_outlined, text: '${meal.minutes} хв', color: AppColors.muted),
        ]),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${meal.price} ₴', style: const TextStyle(color: AppColors.green, fontSize: 18, fontWeight: FontWeight.w800)),
          OutlinedButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Заміна «${meal.title}» — підключимо через агента'), duration: const Duration(seconds: 2))),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.accent, side: const BorderSide(color: AppColors.accent)),
            icon: const Icon(Icons.swap_horiz, size: 18),
            label: const Text('Замінити'),
          ),
        ]),
      ]),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final IconData icon; final String text; final Color color;
  const _MiniTag({required this.icon, required this.text, required this.color});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 14, color: color),
    const SizedBox(width: 4),
    Text(text, style: TextStyle(fontSize: 12, color: color)),
  ]);
}

class _Pill extends StatelessWidget {
  final String text; final Color color; final Color? textColor;
  const _Pill({required this.text, required this.color, this.textColor});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
    child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textColor ?? AppColors.accentInk)),
  );
}
