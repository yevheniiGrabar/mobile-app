import 'package:flutter/material.dart';
import '../theme.dart';
import '../data/diary.dart';

/// Щоденник харчування (сьогодні): що зʼїдено + КБЖУ, з можливістю видалити.
class DiaryScreen extends StatelessWidget {
  const DiaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(backgroundColor: AppColors.bg, elevation: 0, leading: const BackButton(),
        title: const Text('Щоденник · сьогодні', style: TextStyle(fontWeight: FontWeight.w800))),
      body: AnimatedBuilder(
        animation: DiaryStore.instance,
        builder: (context, _) {
          final ds = DiaryStore.instance;
          return ListView(padding: const EdgeInsets.all(16), children: [
            _summary(ds),
            const SizedBox(height: 16),
            if (ds.today.isEmpty)
              const Padding(padding: EdgeInsets.only(top: 40),
                child: Center(child: Text('Ще нічого не записано.\nЗапиши порцію з екрана страви.',
                  textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted))))
            else
              ...List.generate(ds.today.length, (i) => _entryRow(context, ds, i)),
          ]);
        },
      ),
    );
  }

  Widget _summary(DiaryStore ds) {
    final pct = (ds.kcal / DiaryStore.goalKcal).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end, children: [
          RichText(text: TextSpan(children: [
            TextSpan(text: '${ds.kcal} ', style: const TextStyle(color: AppColors.text, fontSize: 26, fontWeight: FontWeight.w900)),
            TextSpan(text: '/ ${DiaryStore.goalKcal} ккал', style: const TextStyle(color: AppColors.muted, fontSize: 14, fontWeight: FontWeight.w600)),
          ])),
          Text('лишилось ${ds.remaining}', style: const TextStyle(fontSize: 12.5, color: AppColors.accent, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 10),
        ClipRRect(borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(value: pct, minHeight: 8, backgroundColor: AppColors.surface2, valueColor: const AlwaysStoppedAnimation(AppColors.accent))),
        const SizedBox(height: 12),
        Row(children: [
          _macro('Білки', ds.protein, DiaryStore.goalProtein, AppColors.blue),
          _macro('Жири', ds.fat, DiaryStore.goalFat, AppColors.amber),
          _macro('Вуглеводи', ds.carbs, DiaryStore.goalCarbs, AppColors.carbs),
        ]),
      ]),
    );
  }

  Widget _macro(String l, int v, int g, Color c) => Expanded(child: Column(children: [
    Text('$v / $g г', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: c)),
    const SizedBox(height: 2),
    Text(l, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
  ]));

  Widget _entryRow(BuildContext context, DiaryStore ds, int i) {
    final e = ds.today[i];
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
