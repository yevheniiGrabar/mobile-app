import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../models.dart';
import '../data/menu_prefs.dart';
import '../data/plan_store.dart';
import '../widgets/meal_card.dart';
import '../format.dart';

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

  @override
  void initState() {
    super.initState();
    // Перемалювати, коли меню згенерували на іншому екрані.
    PlanStore.instance.addListener(_onPlan);
  }

  @override
  void dispose() {
    PlanStore.instance.removeListener(_onPlan);
    super.dispose();
  }

  void _onPlan() { if (mounted) setState(() {}); }

  /// Реальне згенероване меню, якщо є; інакше — демо.
  List<DayMenu> get _week => PlanStore.instance.hasMenu ? PlanStore.instance.days : mockWeek;

  @override
  Widget build(BuildContext context) {
    final week = _week;
    final d = _selected < week.length ? week[_selected] : null;
    final spent = PlanStore.instance.hasMenu
        ? (PlanStore.instance.optimizedTotal ?? 0)
        : mockWeek.fold<int>(0, (s, x) => s + x.total);
    final daysLeft = (_days.length - _todayIndex - 1).clamp(0, 7);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.bg,
      child: CustomScrollView(slivers: [
      // Календар тижня (мінімал: пігулка на вибраному дні) — над бюджетом.
      SliverToBoxAdapter(child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
        child: _WeekStrip(
          days: _days, dates: _dates, selected: _selected, today: _todayIndex,
          hasPlan: (i) => i < week.length && week[i].meals.isNotEmpty,
          onTap: (i) => setState(() => _selected = i),
        ),
      )),
      SliverToBoxAdapter(child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: AnimatedBuilder(
          animation: MenuPrefs.instance,
          builder: (_, _) => _BudgetCard(spent: spent, limit: MenuPrefs.instance.budget.round(), daysLeft: daysLeft),
        ),
      )),
      // Цей тиждень
      SliverToBoxAdapter(child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Цей тиждень', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          Text('Усього: ${uah(spent)} ₴', style: const TextStyle(fontSize: 12.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
        ]),
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
  final num spent;
  final int limit, daysLeft;
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
            TextSpan(text: '${uah(spent)} ₴ ', style: const TextStyle(color: AppColors.green, fontSize: 15, fontWeight: FontWeight.w900)),
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

class _WeekStrip extends StatelessWidget {
  final List<String> days; final List<int> dates;
  final int selected, today;
  final bool Function(int) hasPlan;
  final void Function(int) onTap;
  const _WeekStrip({required this.days, required this.dates, required this.selected,
    required this.today, required this.hasPlan, required this.onTap});
  @override
  Widget build(BuildContext context) {
    // Мінімал: тиждень на всю ширину, без карток; вибраний день — зелена пігулка.
    return Row(children: List.generate(days.length, (i) {
      final sel = i == selected;
      return Expanded(child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(i),
        child: Column(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 10),
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: sel ? AppColors.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(children: [
              Text(days[i].toUpperCase(), style: TextStyle(
                fontSize: 11.5, letterSpacing: 0.4, fontWeight: FontWeight.w600,
                color: sel ? AppColors.accentInk : AppColors.muted)),
              const SizedBox(height: 6),
              Text('${dates[i]}', style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700,
                color: sel ? AppColors.accentInk : AppColors.text)),
            ]),
          ),
          const SizedBox(height: 5),
          // Ненав'язлива крапка — лише для днів із меню (крім вибраного).
          Container(width: 5, height: 5, decoration: BoxDecoration(shape: BoxShape.circle,
            color: hasPlan(i) && !sel ? AppColors.accent : Colors.transparent)),
        ]),
      ));
    }));
  }
}
