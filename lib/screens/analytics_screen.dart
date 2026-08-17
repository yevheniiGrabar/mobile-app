import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme.dart';
import '../data/analytics.dart';
import '../data/api/mealize_api.dart';

/// Аналітика — живі дані з GET /api/analytics (гроші · їжа · патерни Зоряни).
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _api = MealizeApi();
  AnalyticsData? _data;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final json = await _api.analytics();
      if (mounted) setState(() { _data = AnalyticsData.fromJson(json); _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Не вдалося завантажити аналітику'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.bg,
      child: CustomScrollView(slivers: [
        const CupertinoSliverNavigationBar(
          backgroundColor: AppColors.bg, border: null, largeTitle: Text('Аналітика')),
        if (_loading)
          const SliverFillRemaining(hasScrollBody: false, child: Center(child: CupertinoActivityIndicator(radius: 14)))
        else if (_error != null)
          SliverFillRemaining(hasScrollBody: false, child: _errorView())
        else
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            child: _content(_data!),
          )),
      ]),
    );
  }

  Widget _errorView() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(CupertinoIcons.wifi_slash, size: 40, color: AppColors.muted),
    const SizedBox(height: 12),
    Text(_error!, style: const TextStyle(color: AppColors.muted)),
    const SizedBox(height: 16),
    CupertinoButton(color: AppColors.accent, borderRadius: BorderRadius.circular(12),
      onPressed: _load, child: const Text('Спробувати ще', style: TextStyle(color: AppColors.accentInk, fontWeight: FontWeight.w700))),
  ]));

  Widget _content(AnalyticsData d) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    if (d.pattern != null) ...[_zoryanaPattern(context, d.pattern!), const SizedBox(height: 20)],
    _sectionTitle('ГРОШІ'),
    _spendCard(d),
    const SizedBox(height: 12),
    if (d.categories.isNotEmpty) ...[_categoryCard(d), const SizedBox(height: 12)],
    _savingsCard(d),
    const SizedBox(height: 20),
    _sectionTitle('ЇЖА'),
    _kcalCard(d),
    if (d.topItems.isNotEmpty) ...[
      const SizedBox(height: 20),
      _sectionTitle('ТВОЇ ПОСТІЙНІ'),
      _topItemsCard(context, d),
    ],
  ]);

  // ── Патерн від Зоряни ────────────────────────────────────────────────
  Widget _zoryanaPattern(BuildContext context, PatternData p) {
    final items = p.items.isEmpty ? 'частування' : p.items.join(' + ');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.45)),
        gradient: const LinearGradient(
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
        Text('Схоже, ${p.weekday} у тебе — $items 🍺\nЗамовити як завжди?',
          style: const TextStyle(fontSize: 14, height: 1.35)),
        const SizedBox(height: 6),
        Text('≈ ${p.estPrice} ₴ · +${p.estKcal} ккал · ${p.occurrences}× за 3 міс',
          style: const TextStyle(fontSize: 12.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _patternBtn(context, 'Як завжди', AppColors.accent, AppColors.accentInk,
            'Додано «$items» до списку 🍺')),
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
  Widget _spendCard(AnalyticsData d) {
    final maxV = d.monthly.isEmpty ? 1.0 : d.monthly.map((e) => e.amount).reduce((a, b) => a > b ? a : b).toDouble();
    final down = d.spendTrend <= 0;
    return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('${d.spendCurrent} ₴', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
        const SizedBox(width: 8),
        const Padding(padding: EdgeInsets.only(bottom: 4),
          child: Text('цього місяця', style: TextStyle(fontSize: 12.5, color: AppColors.muted, fontWeight: FontWeight.w600))),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: (down ? AppColors.accent : AppColors.warn).withValues(alpha: 0.14), borderRadius: BorderRadius.circular(8)),
          child: Text('${down ? '▼' : '▲'} ${d.spendTrend.abs()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: down ? AppColors.accent : AppColors.warn))),
      ]),
      const SizedBox(height: 4),
      Text(down ? 'Менше за минулий місяць 👍' : 'Більше за минулий місяць',
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
              child: Text(v.toInt() >= 0 && v.toInt() < d.monthly.length ? d.monthly[v.toInt()].label : '',
                style: const TextStyle(fontSize: 10, color: AppColors.muted))))),
        ),
        barGroups: [
          for (int i = 0; i < d.monthly.length; i++)
            BarChartGroupData(x: i, barRods: [BarChartRodData(
              toY: d.monthly[i].amount.toDouble(), width: 16,
              borderRadius: BorderRadius.circular(6),
              color: i == d.monthly.length - 1 ? AppColors.accent : AppColors.accent.withValues(alpha: 0.32))]),
        ],
      ))),
    ]));
  }

  // ── Категорії ────────────────────────────────────────────────────────
  Widget _categoryCard(AnalyticsData d) {
    const palette = [AppColors.carbs, AppColors.green, AppColors.blue, AppColors.amber, Color(0xFFAF52DE), Color(0xFF5AC8FA)];
    final maxV = d.categories.map((c) => c.amount).reduce((a, b) => a > b ? a : b);
    return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Куди йдуть гроші', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
      const SizedBox(height: 14),
      for (int i = 0; i < d.categories.length; i++) Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 9, height: 9, decoration: BoxDecoration(color: palette[i % palette.length], shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(child: Text(d.categories[i].name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
            Text('${d.categories[i].amount} ₴', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
            const SizedBox(width: 6),
            Text('${d.categories[i].pct}%', style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: maxV == 0 ? 0 : d.categories[i].amount / maxV, minHeight: 7,
              backgroundColor: AppColors.surface2, valueColor: AlwaysStoppedAnimation(palette[i % palette.length]))),
        ]),
      ),
    ]));
  }

  // ── Економія ─────────────────────────────────────────────────────────
  Widget _savingsCard(AnalyticsData d) {
    return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(CupertinoIcons.tag_fill, color: AppColors.accent, size: 18),
        const SizedBox(width: 8),
        const Text('Заощаджено', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        const Spacer(),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(8)),
          child: Text('${d.savedRate}% від витрат', style: const TextStyle(fontSize: 11.5, color: AppColors.accent, fontWeight: FontWeight.w700))),
      ]),
      const SizedBox(height: 10),
      Text('${d.savedTotal} ₴', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.accent)),
      const Text('за цей місяць — знижки + оптимізатор Зоряни', style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
      if (d.topSaved.isNotEmpty) ...[
        const SizedBox(height: 14),
        const Divider(height: 1, color: AppColors.line),
        const SizedBox(height: 12),
        const Text('Топ економії', style: TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
        const SizedBox(height: 8),
        for (final s in d.topSaved) Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            Expanded(child: Text(s.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600))),
            Text('−${s.amount} ₴', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.accent)),
          ]),
        ),
      ],
    ]));
  }

  // ── Калорії-тренд ────────────────────────────────────────────────────
  Widget _kcalCard(AnalyticsData d) {
    final maxV = ([...d.weekly, d.kcalGoal].fold<int>(1, (a, b) => a > b ? a : b)) * 1.15;
    return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('${d.kcalAvg}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
        const SizedBox(width: 6),
        const Padding(padding: EdgeInsets.only(bottom: 4),
          child: Text('сер. ккал/день', style: TextStyle(fontSize: 12.5, color: AppColors.muted, fontWeight: FontWeight.w600))),
        const Spacer(),
        if (d.streak > 0) _chip('🔥 ${d.streak} днів поспіль', AppColors.amber),
      ]),
      const SizedBox(height: 6),
      Row(children: [
        _chip('${d.adhWithin}/${d.adhTotal} у межах цілі', AppColors.accent),
        const SizedBox(width: 8),
        Text('ціль ${d.kcalGoal}', style: const TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
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
          HorizontalLine(y: d.kcalGoal.toDouble(), color: AppColors.muted.withValues(alpha: 0.5), strokeWidth: 1, dashArray: [5, 4]),
        ]),
        lineBarsData: [LineChartBarData(
          spots: [for (int i = 0; i < d.weekly.length; i++) FlSpot(i.toDouble(), d.weekly[i].toDouble())],
          isCurved: true, curveSmoothness: 0.35, color: AppColors.amber, barWidth: 3, isStrokeCapRound: true,
          dotData: FlDotData(show: true, getDotPainter: (s, p, b, i) =>
            FlDotCirclePainter(radius: 3.5, color: AppColors.amber, strokeWidth: 2, strokeColor: AppColors.surface)),
          belowBarData: BarAreaData(show: true, color: AppColors.amber.withValues(alpha: 0.10)),
        )],
      ))),
    ]));
  }

  // ── Топ-товари (реордер) ─────────────────────────────────────────────
  Widget _topItemsCard(BuildContext context, AnalyticsData d) {
    final maxN = d.topItems.first.count;
    return _card(child: Column(children: [
      for (int i = 0; i < d.topItems.length; i++) ...[
        Row(children: [
          SizedBox(width: 22, child: Text('${i + 1}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.muted))),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d.topItems[i].name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 5),
            ClipRRect(borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(value: maxN == 0 ? 0 : d.topItems[i].count / maxN, minHeight: 5,
                backgroundColor: AppColors.surface2, valueColor: const AlwaysStoppedAnimation(AppColors.accent))),
          ])),
          const SizedBox(width: 10),
          Text('×${d.topItems[i].count}', style: const TextStyle(fontSize: 12.5, color: AppColors.muted, fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _toast(context, 'Додано «${d.topItems[i].name}» до списку'),
            child: Container(width: 30, height: 30, alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(10)),
              child: const Icon(CupertinoIcons.add, size: 17, color: AppColors.accent))),
        ]),
        if (i < d.topItems.length - 1) const Padding(padding: EdgeInsets.symmetric(vertical: 10),
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
