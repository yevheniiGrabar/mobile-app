import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme.dart';
import '../models.dart';

/// Дашборд-шапка у стилі преміальних food-апів:
/// недельна стрічка + кільце калорій + бари Б/Ж/В.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final today = mockWeek.isNotEmpty ? mockWeek[0] : null;
    final eaten = today?.kcal ?? 0;
    const goal = 2000;
    // Макроси поки мокові (Б/Ж/В у грамах) — підключимо з меню/агента.
    const protein = (val: 95, goal: 120, color: Color(0xFF6FA8FF));
    const fat = (val: 68, goal: 80, color: AppColors.amber);
    const carbs = (val: 180, goal: 230, color: AppColors.green);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
        gradient: const RadialGradient(
          center: Alignment(-0.9, -1.0), radius: 1.4,
          colors: [Color(0xFF241C3A), AppColors.surface],
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _WeekStrip(),
        const SizedBox(height: 16),
        Row(children: [
          _CalorieRing(eaten: eaten, goal: goal),
          const SizedBox(width: 18),
          Expanded(child: Column(children: [
            _MacroBar(label: 'Білки', val: protein.val, goal: protein.goal, color: protein.color),
            const SizedBox(height: 12),
            _MacroBar(label: 'Жири', val: fat.val, goal: fat.goal, color: fat.color),
            const SizedBox(height: 12),
            _MacroBar(label: 'Вуглеводи', val: carbs.val, goal: carbs.goal, color: carbs.color),
          ])),
        ]),
      ]),
    );
  }
}

class _CalorieRing extends StatelessWidget {
  final int eaten;
  final int goal;
  const _CalorieRing({required this.eaten, required this.goal});
  @override
  Widget build(BuildContext context) {
    final left = (goal - eaten).clamp(0, goal).toDouble();
    return SizedBox(
      width: 128, height: 128,
      child: Stack(alignment: Alignment.center, children: [
        PieChart(PieChartData(
          startDegreeOffset: -90,
          sectionsSpace: 0,
          centerSpaceRadius: 48,
          sections: [
            PieChartSectionData(value: eaten.toDouble(), color: AppColors.accent, radius: 12, showTitle: false),
            PieChartSectionData(value: left == 0 ? 1 : left, color: AppColors.line, radius: 12, showTitle: false),
          ],
        )),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$eaten', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, height: 1)),
          const Text('ккал', style: TextStyle(fontSize: 11, color: AppColors.muted)),
          const SizedBox(height: 2),
          Text('з $goal', style: const TextStyle(fontSize: 10, color: AppColors.muted)),
        ]),
      ]),
    );
  }
}

class _MacroBar extends StatelessWidget {
  final String label;
  final int val;
  final int goal;
  final Color color;
  const _MacroBar({required this.label, required this.val, required this.goal, required this.color});
  @override
  Widget build(BuildContext context) {
    final pct = (val / goal).clamp(0.0, 1.0);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600)),
        Text('$val / $goal г', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700)),
      ]),
      const SizedBox(height: 5),
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(value: pct, minHeight: 7,
          backgroundColor: AppColors.line, valueColor: AlwaysStoppedAnimation(color)),
      ),
    ]);
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip();
  @override
  Widget build(BuildContext context) {
    const days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Нд'];
    const dates = [23, 24, 25, 26, 27, 28, 29];
    const statuses = [AppColors.green, AppColors.green, AppColors.amber, AppColors.green, Color(0xFF6FA8FF), AppColors.green, AppColors.muted];
    const todayIndex = 2;
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      for (int i = 0; i < days.length; i++)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: i == todayIndex ? AppColors.surface2 : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: i == todayIndex ? Border.all(color: AppColors.line) : null,
          ),
          child: Column(children: [
            Text(days[i], style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            const SizedBox(height: 4),
            Text('${dates[i]}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
              color: i == todayIndex ? AppColors.text : AppColors.muted)),
            const SizedBox(height: 5),
            Container(width: 16, height: 3, decoration: BoxDecoration(color: statuses[i], borderRadius: BorderRadius.circular(3))),
          ]),
        ),
    ]);
  }
}
