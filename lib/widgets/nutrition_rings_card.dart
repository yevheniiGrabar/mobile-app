import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';
import '../data/diary.dart';

/// Картка «Сьогодні зʼїдено» — кільця «Активність» (вуглеводи/жири/білки) +
/// центр із калоріями + легенда. Живе оновлення від DiaryStore.
class NutritionRingsCard extends StatelessWidget {
  const NutritionRingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: DiaryStore.instance,
      builder: (context, _) {
        final ds = DiaryStore.instance;
        return _card(
          kcal: ds.kcal, kcalGoal: DiaryStore.goalKcal,
          protein: ds.protein, pGoal: DiaryStore.goalProtein,
          fat: ds.fat, fGoal: DiaryStore.goalFat,
          carbs: ds.carbs, cGoal: DiaryStore.goalCarbs,
        );
      },
    );
  }

  Widget _card({required int kcal, required int kcalGoal, required int protein, required int pGoal,
      required int fat, required int fGoal, required int carbs, required int cGoal}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line)),
      child: Column(children: [
        const Align(alignment: Alignment.centerLeft,
          child: Text('Сьогодні зʼїдено', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700))),
        const SizedBox(height: 10),
        _ActivityRings(
          size: 196, stroke: 13,
          rings: [
            _RingData('Вуглеводи', carbs, cGoal, AppColors.carbs),
            _RingData('Жири', fat, fGoal, AppColors.amber),
            _RingData('Білки', protein, pGoal, AppColors.accent),
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
    final pct = goal > 0 ? ((val / goal) * 100).round() : 0;
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

/// Дані одного кільця: назва макросу, зʼїдено/ціль (г) та колір.
class _RingData {
  final String label;
  final int value, goal;
  final Color color;
  const _RingData(this.label, this.value, this.goal, this.color);
  double get pct => goal > 0 ? value / goal : 0.0;
}

/// Концентричні кільця прогресу як Apple Watch «Активність».
class _ActivityRings extends StatefulWidget {
  final double size, stroke;
  final List<_RingData> rings;
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
      final w = isActive ? stroke + stroke * 0.55 * pop : stroke;
      final rect = Rect.fromCircle(center: c, radius: radius);
      const start = -math.pi / 2;

      canvas.drawArc(rect, 0, 2 * math.pi, false, Paint()
        ..style = PaintingStyle.stroke..strokeWidth = w..strokeCap = StrokeCap.round
        ..color = ring.color.withValues(alpha: isActive ? 0.22 : 0.15));

      final sweep = 2 * math.pi * ring.pct.clamp(0.0, 2.0) * fillT;
      if (sweep <= 0) continue;
      final over = sweep > 2 * math.pi;
      final fg = dim ? ring.color.withValues(alpha: 0.45) : ring.color;

      if (isActive && pop > 0) {
        canvas.drawArc(rect, start, over ? 2 * math.pi : sweep, false, Paint()
          ..style = PaintingStyle.stroke..strokeWidth = w..strokeCap = StrokeCap.round
          ..color = ring.color.withValues(alpha: 0.35 * pop)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 * pop));
      }

      final fgPaint = Paint()
        ..style = PaintingStyle.stroke..strokeWidth = w..strokeCap = StrokeCap.round..color = fg;
      if (over) {
        canvas.drawArc(rect, start, 2 * math.pi, false, fgPaint);
        final extra = sweep - 2 * math.pi;
        final leadAngle = start + extra;
        final tip = Offset(c.dx + radius * math.cos(leadAngle), c.dy + radius * math.sin(leadAngle));
        canvas.drawCircle(tip, w * 0.72, Paint()
          ..color = const Color(0xFF000000).withValues(alpha: 0.20)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.5));
        canvas.drawArc(rect, start, extra, false, fgPaint);
      } else {
        canvas.drawArc(rect, start, sweep, false, fgPaint);
      }

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
