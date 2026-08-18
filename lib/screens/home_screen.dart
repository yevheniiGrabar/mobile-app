import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../models.dart';
import '../data/diary.dart';
import '../data/menu_prefs.dart';
import '../data/plan_store.dart';
import '../widgets/meal_card.dart';
import '../format.dart';
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
        const SizedBox(height: 10),
        // Кільця «Активність» (як Apple Watch): вуглеводи → жири → білки.
        _ActivityRings(
          size: 196, stroke: 13,
          rings: [
            _RingData('Вуглеводи', carbs, cGoal, AppColors.carbs),  // зовнішнє
            _RingData('Жири', fat, fGoal, AppColors.amber),         // середнє
            _RingData('Білки', protein, pGoal, AppColors.accent),   // внутрішнє
          ],
          centerBuilder: (active, rings) {
            if (active == null) {
              return Column(mainAxisSize: MainAxisSize.min, children: [
                Text('$kcal', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, height: 1.0)),
                const SizedBox(height: 3),
                Text('з $kcalGoal ккал', style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600)),
              ]);
            }
            final r = rings[active];
            return Column(mainAxisSize: MainAxisSize.min, children: [
              Text('${r.value}', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, height: 1.0, color: r.color)),
              Text('/ ${r.goal} г', style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(r.label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: r.color)),
            ]);
          },
        ),
        const SizedBox(height: 16),
        _legendRow('Білки', protein, pGoal, AppColors.accent),
        _legendRow('Жири', fat, fGoal, AppColors.amber),
        _legendRow('Вуглеводи', carbs, cGoal, AppColors.carbs),
      ]),
    );
  }

  Widget _legendRow(String label, int val, int goal, Color color) {
    final pct = ((val / goal) * 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 9),
        Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
        const Spacer(),
        Text('$val / $goal г', style: TextStyle(fontSize: 12.5, color: color, fontWeight: FontWeight.w800)),
        const SizedBox(width: 6),
        Text('$pct%', style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

/// Дані одного кільця: назва макросу, з'їдено/ціль (г) та колір.
class _RingData {
  final String label;
  final int value, goal;
  final Color color;
  const _RingData(this.label, this.value, this.goal, this.color);
  double get pct => goal > 0 ? value / goal : 0.0;
}

/// Концентричні кільця прогресу як Apple Watch «Активність».
/// Наведення мишею (веб) або тап (телефон) підсвічує кільце, збільшує його
/// й показує відповідний макрос у центрі.
class _ActivityRings extends StatefulWidget {
  final double size, stroke;
  final List<_RingData> rings; // від зовнішнього до внутрішнього
  final Widget Function(int? active, List<_RingData> rings) centerBuilder;
  const _ActivityRings({required this.size, required this.stroke, required this.rings, required this.centerBuilder});
  @override
  State<_ActivityRings> createState() => _ActivityRingsState();
}

class _ActivityRingsState extends State<_ActivityRings> with TickerProviderStateMixin {
  static const _gap = 6.0;
  late final AnimationController _fill =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  late final AnimationController _pop =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
  int? _active;

  @override
  void dispose() { _fill.dispose(); _pop.dispose(); super.dispose(); }

  double get _maxStroke => widget.stroke * 1.55;
  double get _rOuter => widget.size / 2 - _maxStroke / 2;

  /// Яке кільце під точкою (за відстанню від центру).
  int? _hitTest(Offset local) {
    final c = Offset(widget.size / 2, widget.size / 2);
    final d = (local - c).distance;
    for (int i = 0; i < widget.rings.length; i++) {
      final radius = _rOuter - i * (widget.stroke + _gap);
      if ((d - radius).abs() <= widget.stroke / 2 + _gap / 2) return i;
    }
    return null;
  }

  void _setActive(int? i) {
    if (i == _active) return;
    setState(() => _active = i);
    i != null ? _pop.forward() : _pop.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _fill, curve: Curves.easeOutCubic);
    return MouseRegion(
      onHover: (e) => _setActive(_hitTest(e.localPosition)),
      onExit: (_) => _setActive(null),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) { final i = _hitTest(d.localPosition); _setActive(i == _active ? null : i); },
        child: SizedBox(
          width: widget.size, height: widget.size,
          child: AnimatedBuilder(
            animation: Listenable.merge([_fill, _pop]),
            builder: (_, _) => CustomPaint(
              painter: _RingsPainter(
                rings: widget.rings, stroke: widget.stroke, gap: _gap,
                rOuter: _rOuter, fillT: curved.value, active: _active, pop: _pop.value),
              child: Center(child: widget.centerBuilder(_active, widget.rings)),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  final List<_RingData> rings;
  final double stroke, gap, rOuter, fillT, pop;
  final int? active;
  _RingsPainter({required this.rings, required this.stroke, required this.gap,
    required this.rOuter, required this.fillT, required this.active, required this.pop});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    for (int i = 0; i < rings.length; i++) {
      final radius = rOuter - i * (stroke + gap);
      if (radius <= 0) continue;
      final ring = rings[i];
      final isActive = i == active;
      final dim = active != null && !isActive;
      final w = isActive ? stroke + stroke * 0.55 * pop : stroke; // активне кільце товщає
      final rect = Rect.fromCircle(center: c, radius: radius);
      const start = -math.pi / 2;

      // Доріжка (фон кільця).
      canvas.drawArc(rect, 0, 2 * math.pi, false, Paint()
        ..style = PaintingStyle.stroke..strokeWidth = w..strokeCap = StrokeCap.round
        ..color = ring.color.withValues(alpha: isActive ? 0.22 : 0.15));

      final sweep = 2 * math.pi * ring.pct.clamp(0.0, 2.0) * fillT; // до 200% → другий круг
      if (sweep <= 0) continue;
      final over = sweep > 2 * math.pi;
      final fg = dim ? ring.color.withValues(alpha: 0.45) : ring.color;

      // Аура під активним кільцем.
      if (isActive && pop > 0) {
        canvas.drawArc(rect, start, over ? 2 * math.pi : sweep, false, Paint()
          ..style = PaintingStyle.stroke..strokeWidth = w..strokeCap = StrokeCap.round
          ..color = ring.color.withValues(alpha: 0.35 * pop)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 * pop));
      }

      final fgPaint = Paint()
        ..style = PaintingStyle.stroke..strokeWidth = w..strokeCap = StrokeCap.round..color = fg;
      if (over) {
        // Перше коло заповнене повністю…
        canvas.drawArc(rect, start, 2 * math.pi, false, fgPaint);
        final extra = sweep - 2 * math.pi; // …і надлишок понад 100% зверху.
        final leadAngle = start + extra;
        final tip = Offset(c.dx + radius * math.cos(leadAngle), c.dy + radius * math.sin(leadAngle));
        // Тінь від кінчика, що лягає на «хвіст» (глибина, як у Apple Watch).
        canvas.drawCircle(tip, w * 0.72, Paint()
          ..color = const Color(0xFF000000).withValues(alpha: 0.20)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.5));
        canvas.drawArc(rect, start, extra, false, fgPaint);
      } else {
        canvas.drawArc(rect, start, sweep, false, fgPaint);
      }

      // Свічення на кінчику дуги.
      if (!dim) {
        final leadAngle = start + sweep;
        final tip = Offset(c.dx + radius * math.cos(leadAngle), c.dy + radius * math.sin(leadAngle));
        canvas.drawCircle(tip, w * 0.95, Paint()
          ..color = ring.color.withValues(alpha: isActive ? 0.70 : 0.50)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.7));
        canvas.drawCircle(tip, w * 0.22, Paint()
          ..color = Color.lerp(ring.color, const Color(0xFFFFFFFF), 0.55)!);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter o) =>
      o.fillT != fillT || o.pop != pop || o.active != active || o.rings != rings || o.stroke != stroke;
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
