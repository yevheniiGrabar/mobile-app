import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../models.dart';

/// AI-заміна страви (Stitch #06): пропозиції на основі бюджету та КБЖУ.
void showSwapSheet(BuildContext context, Meal meal) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _SwapSheet(meal: meal),
  );
}

class _SwapOption {
  final String tag, title;
  final int kcal, price, minutes;
  final Color tagColor;
  const _SwapOption(this.tag, this.title, this.kcal, this.price, this.minutes, this.tagColor);
}

class _SwapSheet extends StatelessWidget {
  final Meal meal;
  const _SwapSheet({required this.meal});

  @override
  Widget build(BuildContext context) {
    // Мок-пропозиції; реально генерує агент під бюджет/КБЖУ через Silpo MCP.
    final options = <_SwapOption>[
      _SwapOption('Дешевше', 'Гречана каша з грибами', meal.kcal - 40, (meal.price * 0.7).round(), meal.minutes, AppColors.green),
      _SwapOption('Більше білка', 'Омлет із куркою та овочами', meal.kcal + 30, meal.price + 8, 15, AppColors.blue),
      _SwapOption('Швидше', 'Тост з авокадо та яйцем', meal.kcal - 10, meal.price + 4, 8, AppColors.amber),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(4)))),
        const SizedBox(height: 16),
        Row(children: [
          const Icon(Icons.auto_awesome, color: AppColors.accent, size: 20),
          const SizedBox(width: 8),
          const Text('AI Пропозиції', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 2),
        Text('Замість «${meal.title}» — під твій бюджет та КБЖУ',
          style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
        const SizedBox(height: 16),
        ...options.map((o) => _optionCard(context, o)),
        const SizedBox(height: 4),
        Center(child: Text('Зоряна підбирає з реальних цін Сільпо',
          style: TextStyle(fontSize: 10.5, color: AppColors.muted))),
      ]),
    );
  }

  Widget _optionCard(BuildContext context, _SwapOption o) {
    final cheaper = o.price < meal.price;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(color: o.tagColor.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(8)),
            child: Text(o.tag, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: o.tagColor))),
          const Spacer(),
          Text('${o.price} ₴', style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w800, fontSize: 15)),
          if (cheaper) Padding(padding: const EdgeInsets.only(left: 6),
            child: Text('−${meal.price - o.price} ₴', style: const TextStyle(color: AppColors.green, fontSize: 11, fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 8),
        Text(o.title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Row(children: [
          _tag(Icons.local_fire_department, '${o.kcal} ккал', AppColors.amber),
          const SizedBox(width: 14),
          _tag(Icons.timer_outlined, '${o.minutes} хв', AppColors.muted),
          const Spacer(),
          CupertinoButton(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(20),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            minimumSize: Size.zero,
            onPressed: () {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              messenger.showSnackBar(SnackBar(
                content: Text('Замінено на «${o.title}» ✓'), duration: const Duration(seconds: 2)));
            },
            child: const Text('Обрати', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
          ),
        ]),
      ]),
    );
  }

  Widget _tag(IconData i, String t, Color c) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(i, size: 14, color: c), const SizedBox(width: 4),
    Text(t, style: TextStyle(fontSize: 12, color: c)),
  ]);
}
