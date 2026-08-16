import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme.dart';
import '../models.dart';
import '../data/diary.dart';
import '../widgets/meal_card.dart';
import 'subscription_screen.dart';
import 'diary_screen.dart';

/// Головна (Stitch): бюджет → КБЖУ → «Цей тиждень» → «Меню на сьогодні».
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Нд'];
  static const _dates = [23, 24, 25, 26, 27, 28, 29];
  static const _todayIndex = 0; // сьогодні = Понеділок (демо-дані)
  int _selected = 0;

  DayMenu? get _day => _selected < mockWeek.length ? mockWeek[_selected] : null;

  @override
  Widget build(BuildContext context) {
    final d = _day;
    final spent = mockWeek.fold<int>(0, (s, x) => s + x.total);
    final daysLeft = (_days.length - _todayIndex - 1).clamp(0, 7);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.bg,
      child: CustomScrollView(slivers: [
      CupertinoSliverNavigationBar(
        backgroundColor: AppColors.bg,
        border: null,
        largeTitle: const Text('Mealize'),
        trailing: GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const SubscriptionScreen(), fullscreenDialog: true)),
          child: const Icon(CupertinoIcons.star_circle_fill, color: AppColors.accent, size: 26),
        ),
      ),
      SliverToBoxAdapter(child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: _BudgetCard(spent: spent, limit: 2000, daysLeft: daysLeft),
      )),
      SliverToBoxAdapter(child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: AnimatedBuilder(
          animation: DiaryStore.instance,
          builder: (context, _) {
            final ds = DiaryStore.instance;
            return _NutritionCard(
              kcal: ds.kcal, kcalGoal: DiaryStore.goalKcal,
              protein: ds.protein, pGoal: DiaryStore.goalProtein,
              fat: ds.fat, fGoal: DiaryStore.goalFat,
              carbs: ds.carbs, cGoal: DiaryStore.goalCarbs,
              entries: ds.today.length,
              onDiary: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DiaryScreen())),
            );
          },
        ),
      )),
      // Цей тиждень
      SliverToBoxAdapter(child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Цей тиждень', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          Text('Усього: $spent ₴', style: const TextStyle(fontSize: 12.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
        ]),
      )),
      SliverToBoxAdapter(child: _WeekStrip(
        days: _days, dates: _dates, selected: _selected, today: _todayIndex,
        hasPlan: (i) => i < mockWeek.length,
        onTap: (i) => setState(() => _selected = i),
      )),
      // Меню на сьогодні / на день
      SliverToBoxAdapter(child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: Text(_selected == _todayIndex ? 'Меню на сьогодні' : 'Меню · ${_dayNameFull(_selected)}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      )),
      if (d == null)
        SliverToBoxAdapter(child: _EmptyDay())
      else
        SliverList(delegate: SliverChildBuilderDelegate((c, i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: MealCard(meal: d.meals[i]),
        ), childCount: d.meals.length)),
      const SliverToBoxAdapter(child: SizedBox(height: 100)),
    ]));
  }

  String _dayNameFull(int i) => const ['Понеділок','Вівторок','Середа','Четвер','П\'ятниця','Субота','Неділя'][i.clamp(0, 6)];
}

class _EmptyDay extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
    child: Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.line)),
      child: const Column(children: [
        Icon(Icons.auto_awesome, color: AppColors.accent, size: 28),
        SizedBox(height: 8),
        Text('На цей день меню ще не складено', style: TextStyle(fontWeight: FontWeight.w700)),
        SizedBox(height: 4),
        Text('Попроси Зоряну скласти меню під твій бюджет', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.5, color: AppColors.muted)),
      ]),
    ),
  );
}

class _BudgetCard extends StatelessWidget {
  final int spent, limit, daysLeft;
  const _BudgetCard({required this.spent, required this.limit, required this.daysLeft});
  @override
  Widget build(BuildContext context) {
    final pct = (spent / limit).clamp(0.0, 1.0);
    final within = spent <= limit;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Тижневий бюджет', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
          RichText(text: TextSpan(children: [
            TextSpan(text: '$spent ₴ ', style: const TextStyle(color: AppColors.green, fontSize: 15, fontWeight: FontWeight.w900)),
            TextSpan(text: '/ $limit ₴', style: const TextStyle(color: AppColors.muted, fontSize: 13, fontWeight: FontWeight.w600)),
          ])),
        ]),
        const SizedBox(height: 12),
        ClipRRect(borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(value: pct, minHeight: 8, backgroundColor: AppColors.surface2,
            valueColor: AlwaysStoppedAnimation(within ? AppColors.accent : AppColors.warn))),
        const SizedBox(height: 8),
        Row(children: [
          Icon(within ? Icons.check_circle : Icons.error_outline, size: 14, color: within ? AppColors.accent : AppColors.warn),
          const SizedBox(width: 5),
          Text(within ? 'В межах · залишилося на $daysLeft днів' : 'Бюджет перевищено',
            style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }
}

class _NutritionCard extends StatelessWidget {
  final int kcal, kcalGoal, protein, pGoal, fat, fGoal, carbs, cGoal, entries;
  final VoidCallback onDiary;
  const _NutritionCard({required this.kcal, required this.kcalGoal, required this.protein,
    required this.pGoal, required this.fat, required this.fGoal, required this.carbs, required this.cGoal,
    required this.entries, required this.onDiary});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line)),
      child: Column(children: [
        Row(children: [
          const Text('Сьогодні зʼїдено', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
          const Spacer(),
          InkWell(onTap: onDiary, borderRadius: BorderRadius.circular(8), child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(children: [
              Text('Щоденник ($entries)', style: const TextStyle(fontSize: 12.5, color: AppColors.accent, fontWeight: FontWeight.w700)),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.accent),
            ]),
          )),
        ]),
        const SizedBox(height: 8),
        SizedBox(width: 150, height: 150, child: Stack(alignment: Alignment.center, children: [
          PieChart(PieChartData(startDegreeOffset: -90, sectionsSpace: 0, centerSpaceRadius: 56, sections: [
            PieChartSectionData(value: kcal.toDouble(), color: AppColors.accent, radius: 13, showTitle: false),
            PieChartSectionData(value: (kcalGoal - kcal).clamp(0, kcalGoal).toDouble() == 0 ? 1 : (kcalGoal - kcal).clamp(0, kcalGoal).toDouble(),
              color: AppColors.line, radius: 13, showTitle: false),
          ])),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text('$kcal', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, height: 1)),
            const Text('ккал', style: TextStyle(fontSize: 11, color: AppColors.muted)),
            Text('з $kcalGoal', style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
          ]),
        ])),
        const SizedBox(height: 16),
        _MacroBar(label: 'Білки', val: protein, goal: pGoal, color: AppColors.accent),
        const SizedBox(height: 12),
        _MacroBar(label: 'Жири', val: fat, goal: fGoal, color: AppColors.amber),
        const SizedBox(height: 12),
        _MacroBar(label: 'Вуглеводи', val: carbs, goal: cGoal, color: AppColors.carbs),
      ]),
    );
  }
}

class _MacroBar extends StatelessWidget {
  final String label; final int val, goal; final Color color;
  const _MacroBar({required this.label, required this.val, required this.goal, required this.color});
  @override
  Widget build(BuildContext context) {
    final pct = (val / goal).clamp(0.0, 1.0);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
        Text('$val / $goal г', style: TextStyle(fontSize: 12.5, color: color, fontWeight: FontWeight.w700)),
      ]),
      const SizedBox(height: 5),
      ClipRRect(borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(value: pct, minHeight: 7, backgroundColor: AppColors.surface2, valueColor: AlwaysStoppedAnimation(color))),
    ]);
  }
}

class _WeekStrip extends StatelessWidget {
  final List<String> days; final List<int> dates;
  final int selected, today;
  final bool Function(int) hasPlan;
  final void Function(int) onTap;
  const _WeekStrip({required this.days, required this.dates, required this.selected,
    required this.today, required this.hasPlan, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 76, child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: days.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (c, i) {
        final sel = i == selected;
        return GestureDetector(
          onTap: () => onTap(i),
          child: Container(
            width: 48,
            decoration: BoxDecoration(
              color: sel ? AppColors.accent : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: sel ? AppColors.accent : AppColors.line)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(days[i], style: TextStyle(fontSize: 11, color: sel ? AppColors.accentInk : AppColors.muted)),
              const SizedBox(height: 4),
              Text('${dates[i]}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: sel ? AppColors.accentInk : AppColors.text)),
              const SizedBox(height: 5),
              Container(width: 5, height: 5, decoration: BoxDecoration(shape: BoxShape.circle,
                color: hasPlan(i) ? (sel ? AppColors.accentInk : AppColors.accent) : Colors.transparent)),
            ]),
          ),
        );
      },
    ));
  }
}
