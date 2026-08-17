import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme.dart';

/// Аналітика — демо на засіяних даних (гроші · їжа · патерни від Зоряни).
/// Реальні дані підключимо, коли назбирається історія замовлень + щоденника.
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  // ── Засіяні демо-дані ────────────────────────────────────────────────
  static const _months = ['Бер', 'Кві', 'Тра', 'Чер', 'Лип', 'Сер'];
  static const _monthSpend = [2140, 1980, 2260, 2050, 2380, 2076]; // ₴/міс
  static const _categories = [
    ('М\'ясо і риба', 706, AppColors.carbs),
    ('Овочі та фрукти', 456, AppColors.green),
    ('Молочне і яйця', 332, AppColors.blue),
    ('Крупи, бакалія', 249, AppColors.amber),
    ('Солодке', 187, Color(0xFFAF52DE)),
    ('Напої', 146, Color(0xFF5AC8FA)),
  ];
  static const _totalSaved = 1240; // ₴ цього місяця
  static const _topSaved = [
    ('Куряче філе', 180), ('Олія соняшникова', 96), ('Гречка', 74), ('Молоко 2.5%', 52),
  ];
  static const _topItems = [
    ('Молоко 2.5%', 12), ('Куряче філе', 9), ('Банани', 8),
    ('Яйця С1', 7), ('Вівсянка', 6), ('Хліб цільнозерновий', 6),
  ];
  static const _kcalWeekly = [1980, 2050, 1890, 1820]; // сер. ккал/день по тижнях
  static const _kcalGoal = 1900;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.bg,
      child: CustomScrollView(slivers: [
        const CupertinoSliverNavigationBar(
          backgroundColor: AppColors.bg, border: null, largeTitle: Text('Аналітика')),
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _zoryanaPattern(context),
            const SizedBox(height: 20),
            _sectionTitle('ГРОШІ'),
            _spendCard(),
            const SizedBox(height: 12),
            _categoryCard(),
            const SizedBox(height: 12),
            _savingsCard(),
            const SizedBox(height: 20),
            _sectionTitle('ЇЖА'),
            _kcalCard(),
            const SizedBox(height: 20),
            _sectionTitle('ТВОЇ ПОСТІЙНІ'),
            _topItemsCard(context),
          ]),
        )),
      ]),
    );
  }

  // ── Патерн від Зоряни ────────────────────────────────────────────────
  Widget _zoryanaPattern(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.45)),
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [AppColors.accentSoft, AppColors.surface]),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _orb(),
          const SizedBox(width: 10),
          const Text('Зоряна помітила патерн', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        ]),
        const SizedBox(height: 12),
        const Text('Схоже, п’ятниця у тебе — пиво + чіпси 🍺\nЗамовити як завжди?',
          style: TextStyle(fontSize: 14, height: 1.35)),
        const SizedBox(height: 6),
        const Text('≈ 240 ₴ · +900 ккал', style: TextStyle(fontSize: 12.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _patternBtn(context, 'Як завжди', AppColors.accent, AppColors.accentInk,
            'Додано «пиво + чіпси» до списку 🍺')),
          const SizedBox(width: 8),
          Expanded(child: _patternBtn(context, 'Легша версія', AppColors.surface2, AppColors.text,
            'Зоряна підібрала легшу заміну: −400 ккал 🥨')),
        ]),
        const SizedBox(height: 8),
        Center(child: GestureDetector(
          onTap: () => _toast(context, 'Гаразд, не пропонуватиму сьогодні'),
          child: const Text('Не сьогодні', style: TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w600)))),
      ]),
    );
  }

  Widget _patternBtn(BuildContext c, String label, Color bg, Color fg, String toast) => GestureDetector(
    onTap: () => _toast(c, toast),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 11), alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: fg))),
  );

  Widget _orb() => Container(
    width: 30, height: 30,
    decoration: const BoxDecoration(shape: BoxShape.circle,
      gradient: RadialGradient(center: Alignment(-0.3, -0.3), radius: 0.9, colors: [Color(0xFF4FD08A), AppColors.accent])),
    child: const Icon(CupertinoIcons.sparkles, color: Colors.white, size: 16));

  // ── Витрати ──────────────────────────────────────────────────────────
  Widget _spendCard() {
    final maxV = _monthSpend.reduce((a, b) => a > b ? a : b).toDouble();
    final cur = _monthSpend.last, prev = _monthSpend[_monthSpend.length - 2];
    final trend = ((cur - prev) / prev * 100).round();
    final down = trend <= 0;
    return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('$cur ₴', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
        const SizedBox(width: 8),
        const Padding(padding: EdgeInsets.only(bottom: 4),
          child: Text('цього місяця', style: TextStyle(fontSize: 12.5, color: AppColors.muted, fontWeight: FontWeight.w600))),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: (down ? AppColors.accent : AppColors.warn).withValues(alpha: 0.14), borderRadius: BorderRadius.circular(8)),
          child: Text('${down ? '▼' : '▲'} ${trend.abs()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: down ? AppColors.accent : AppColors.warn))),
      ]),
      const SizedBox(height: 4),
      Text(down ? 'Менше, ніж торік місяць 👍' : 'Більше за минулий місяць',
        style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
      const SizedBox(height: 16),
      SizedBox(height: 120, child: BarChart(BarChartData(
        alignment: BarChartAlignment.spaceAround, maxY: maxV * 1.25,
        gridData: const FlGridData(show: false), borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 20,
            getTitlesWidget: (v, m) => Padding(padding: const EdgeInsets.only(top: 6),
              child: Text(_months[v.toInt().clamp(0, _months.length - 1)], style: const TextStyle(fontSize: 10, color: AppColors.muted))))),
        ),
        barGroups: [
          for (int i = 0; i < _monthSpend.length; i++)
            BarChartGroupData(x: i, barRods: [BarChartRodData(
              toY: _monthSpend[i].toDouble(), width: 16,
              borderRadius: BorderRadius.circular(6),
              color: i == _monthSpend.length - 1 ? AppColors.accent : AppColors.accent.withValues(alpha: 0.32))]),
        ],
      ))),
    ]));
  }

  // ── Категорії ────────────────────────────────────────────────────────
  Widget _categoryCard() {
    final total = _categories.fold<int>(0, (s, c) => s + c.$2);
    final maxV = _categories.map((c) => c.$2).reduce((a, b) => a > b ? a : b);
    return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Куди йдуть гроші', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
      const SizedBox(height: 14),
      for (final c in _categories) Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 9, height: 9, decoration: BoxDecoration(color: c.$3, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(c.$1, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('${c.$2} ₴', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
            const SizedBox(width: 6),
            Text('${(c.$2 / total * 100).round()}%', style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: c.$2 / maxV, minHeight: 7,
              backgroundColor: AppColors.surface2, valueColor: AlwaysStoppedAnimation(c.$3))),
        ]),
      ),
    ]));
  }

  // ── Економія ─────────────────────────────────────────────────────────
  Widget _savingsCard() {
    return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(CupertinoIcons.tag_fill, color: AppColors.accent, size: 18),
        const SizedBox(width: 8),
        const Text('Заощаджено', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        const Spacer(),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(8)),
          child: const Text('15% від витрат', style: TextStyle(fontSize: 11.5, color: AppColors.accent, fontWeight: FontWeight.w700))),
      ]),
      const SizedBox(height: 10),
      Text('$_totalSaved ₴', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.accent)),
      const Text('за цей місяць — знижки + оптимізатор Зоряни', style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
      const SizedBox(height: 14),
      const Divider(height: 1, color: AppColors.line),
      const SizedBox(height: 12),
      const Text('Топ економії', style: TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
      const SizedBox(height: 8),
      for (final s in _topSaved) Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Text(s.$1, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('−${s.$2} ₴', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.accent)),
        ]),
      ),
    ]));
  }

  // ── Калорії-тренд ────────────────────────────────────────────────────
  Widget _kcalCard() {
    final avg = (_kcalWeekly.reduce((a, b) => a + b) / _kcalWeekly.length).round();
    final maxV = ([..._kcalWeekly, _kcalGoal].reduce((a, b) => a > b ? a : b)) * 1.15;
    return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('$avg', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
        const SizedBox(width: 6),
        const Padding(padding: EdgeInsets.only(bottom: 4),
          child: Text('сер. ккал/день', style: TextStyle(fontSize: 12.5, color: AppColors.muted, fontWeight: FontWeight.w600))),
        const Spacer(),
        _chip('🔥 5 днів поспіль', AppColors.amber),
      ]),
      const SizedBox(height: 6),
      Row(children: [
        _chip('18/28 у межах цілі', AppColors.accent),
        const SizedBox(width: 8),
        Text('ціль $_kcalGoal', style: const TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 16),
      SizedBox(height: 110, child: LineChart(LineChartData(
        minY: 0, maxY: maxV,
        gridData: const FlGridData(show: false), borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 20, interval: 1,
            getTitlesWidget: (v, m) => Padding(padding: const EdgeInsets.only(top: 6),
              child: Text('Т${v.toInt() + 1}', style: const TextStyle(fontSize: 10, color: AppColors.muted))))),
        ),
        extraLinesData: ExtraLinesData(horizontalLines: [
          HorizontalLine(y: _kcalGoal.toDouble(), color: AppColors.muted.withValues(alpha: 0.5), strokeWidth: 1, dashArray: [5, 4]),
        ]),
        lineBarsData: [LineChartBarData(
          spots: [for (int i = 0; i < _kcalWeekly.length; i++) FlSpot(i.toDouble(), _kcalWeekly[i].toDouble())],
          isCurved: true, curveSmoothness: 0.35, color: AppColors.amber, barWidth: 3, isStrokeCapRound: true,
          dotData: FlDotData(show: true, getDotPainter: (s, p, b, i) =>
            FlDotCirclePainter(radius: 3.5, color: AppColors.amber, strokeWidth: 2, strokeColor: AppColors.surface)),
          belowBarData: BarAreaData(show: true, color: AppColors.amber.withValues(alpha: 0.10)),
        )],
      ))),
    ]));
  }

  // ── Топ-товари (реордер) ─────────────────────────────────────────────
  Widget _topItemsCard(BuildContext context) {
    final maxN = _topItems.first.$2;
    return _card(child: Column(children: [
      for (int i = 0; i < _topItems.length; i++) ...[
        Row(children: [
          SizedBox(width: 22, child: Text('${i + 1}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.muted))),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_topItems[i].$1, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 5),
            ClipRRect(borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(value: _topItems[i].$2 / maxN, minHeight: 5,
                backgroundColor: AppColors.surface2, valueColor: const AlwaysStoppedAnimation(AppColors.accent))),
          ])),
          const SizedBox(width: 10),
          Text('×${_topItems[i].$2}', style: const TextStyle(fontSize: 12.5, color: AppColors.muted, fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _toast(context, 'Додано «${_topItems[i].$1}» до списку'),
            child: Container(width: 30, height: 30, alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(10)),
              child: const Icon(CupertinoIcons.add, size: 17, color: AppColors.accent))),
        ]),
        if (i < _topItems.length - 1) const Padding(padding: EdgeInsets.symmetric(vertical: 10),
          child: Divider(height: 1, color: AppColors.line)),
      ],
    ]));
  }

  // ── helpers ──────────────────────────────────────────────────────────
  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(t, style: const TextStyle(fontSize: 12, letterSpacing: 0.3, color: AppColors.muted, fontWeight: FontWeight.w700)));

  Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.line)),
    child: child);

  Widget _chip(String t, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(color: c.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(8)),
    child: Text(t, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: c)));

  void _toast(BuildContext c, String msg) => ScaffoldMessenger.of(c).showSnackBar(
    SnackBar(content: Text(msg), duration: const Duration(seconds: 2), behavior: SnackBarBehavior.floating));
}
