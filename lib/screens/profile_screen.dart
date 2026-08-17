import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme.dart';
import '../data/stores.dart';
import '../data/diary.dart';
import '../data/menu_prefs.dart';
import '../widgets/silpo_connection_card.dart';
import 'calorie_goal_screen.dart';
import 'family_screen.dart';
import 'diet_screen.dart';
import 'menu_settings_screen.dart';
import 'subscription_screen.dart';

/// Профіль (Stitch): акаунт + статистика тижня + групи налаштувань.
/// «Налаштування меню» (бюджет/раціон/магазин) відкривається під-екраном.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Демо-статистика тижня (підключимо реальні дані пізніше).
  static const _spend = [216, 264, 204, 230, 260, 240, 190]; // ₴/день
  static const _dayLabels = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'НД'];

  @override
  Widget build(BuildContext context) {
    final store = StoreRegistry.instance.active.info;
    final totalSpend = _spend.fold<int>(0, (s, x) => s + x);
    const totalKcal = 13720;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.bg,
      child: CustomScrollView(slivers: [
      const CupertinoSliverNavigationBar(
        backgroundColor: AppColors.bg, border: null, largeTitle: Text('Профіль')),
      SliverToBoxAdapter(child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: Column(children: [
          _accountCard(context),
          const SizedBox(height: 12),
          const SilpoConnectionCard(),
          _statsCard(totalKcal, totalSpend),
          const SizedBox(height: 20),
          _group('НАЛАШТУВАННЯ', [
            _row(context, Icons.track_changes, 'Цілі калорій', '${DiaryStore.goalKcal} ккал',
              () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CalorieGoalScreen()))),
            _row(context, Icons.groups_outlined, 'Склад сім\'ї', '${MenuPrefs.instance.people} ос.',
              () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FamilyScreen()))),
            _row(context, Icons.eco_outlined, 'Раціон і алергії', '${MenuPrefs.instance.filtersCount} фільтри',
              () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DietScreen()))),
          ]),
          const SizedBox(height: 16),
          _group('ЗАМОВЛЕННЯ', [
            _row(context, Icons.storefront_outlined, 'Магазин та ринок', store.name, () => _openSettings(context)),
            _row(context, Icons.location_on_outlined, 'Адреси доставки', '2', () => _soon(context)),
            _row(context, Icons.credit_card, 'Спосіб оплати', 'Apple Pay', () => _soon(context)),
            _row(context, Icons.history, 'Історія замовлень', '14', () => _soon(context)),
          ]),
          const SizedBox(height: 16),
          _group('ІНШЕ', [
            _row(context, Icons.workspace_premium, 'Mealize Pro', 'Спробувати', () =>
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SubscriptionScreen(), fullscreenDialog: true)), accent: true),
            _row(context, Icons.notifications_none, 'Сповіщення', '', () => _soon(context)),
            _row(context, Icons.help_outline, 'Підтримка', '', () => _soon(context)),
          ]),
          const SizedBox(height: 100),
        ]),
      )),
    ]));
  }

  void _openSettings(BuildContext c) =>
      Navigator.of(c).push(MaterialPageRoute(builder: (_) => const MenuSettingsScreen()));
  void _soon(BuildContext c) => ScaffoldMessenger.of(c).showSnackBar(
      const SnackBar(content: Text('Розділ у розробці'), duration: Duration(seconds: 2)));

  Widget _accountCard(BuildContext context) => GestureDetector(
    onTap: () => _openSettings(context),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.line)),
      child: Row(children: [
        Container(width: 52, height: 52,
          decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: const RadialGradient(center: Alignment(-0.3, -0.3), radius: 0.9, colors: [Color(0xFF4FD08A), AppColors.accent])),
          child: const Icon(Icons.person, color: Colors.white, size: 26)),
        const SizedBox(width: 14),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Євгеній Грабар', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          SizedBox(height: 2),
          Text('Сім\'я — 2 особи', style: TextStyle(fontSize: 12.5, color: AppColors.muted)),
        ])),
        const Icon(Icons.chevron_right, color: AppColors.muted),
      ]),
    ),
  );

  Widget _statsCard(int kcal, int spend) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.line)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('ТИЖДЕНЬ', style: TextStyle(fontSize: 11, letterSpacing: 1, color: AppColors.muted, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          RichText(text: TextSpan(children: [
            TextSpan(text: _fmt(kcal), style: const TextStyle(color: AppColors.text, fontSize: 22, fontWeight: FontWeight.w900)),
            const TextSpan(text: '  ккал', style: TextStyle(color: AppColors.muted, fontSize: 12.5, fontWeight: FontWeight.w600)),
          ])),
          const SizedBox(height: 2),
          const Text('разом', style: TextStyle(fontSize: 12, color: AppColors.muted)),
        ])),
        Container(width: 1, height: 36, color: AppColors.line),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('$spend ₴', style: const TextStyle(color: AppColors.green, fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          const Text('витрати', style: TextStyle(fontSize: 12, color: AppColors.muted)),
        ]),
      ]),
      const SizedBox(height: 18),
      SizedBox(height: 96, child: _chart()),
    ]),
  );

  Widget _chart() {
    final spots = [for (int i = 0; i < _spend.length; i++) FlSpot(i.toDouble(), _spend[i].toDouble())];
    final maxY = (_spend.reduce((a, b) => a > b ? a : b) * 1.25);
    return LineChart(LineChartData(
      minY: 0, maxY: maxY,
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 22, interval: 1,
          getTitlesWidget: (v, m) {
            final i = v.toInt();
            if (i < 0 || i >= _dayLabels.length) return const SizedBox.shrink();
            return Padding(padding: const EdgeInsets.only(top: 6),
              child: Text(_dayLabels[i], style: const TextStyle(fontSize: 10, color: AppColors.muted)));
          })),
      ),
      lineTouchData: const LineTouchData(enabled: false),
      lineBarsData: [LineChartBarData(
        spots: spots, isCurved: true, curveSmoothness: 0.35,
        color: AppColors.carbs, barWidth: 3, isStrokeCapRound: true,
        dotData: FlDotData(show: true, getDotPainter: (s, p, b, i) =>
          FlDotCirclePainter(radius: 3.5, color: AppColors.carbs, strokeWidth: 2, strokeColor: AppColors.surface)),
        belowBarData: BarAreaData(show: true, color: AppColors.carbs.withValues(alpha: 0.10)),
      )],
    ));
  }

  /// Нативна iOS-група (як у Налаштуваннях): inset-grouped список.
  Widget _group(String title, List<Widget> rows) => CupertinoListSection.insetGrouped(
    header: Text(title, style: const TextStyle(fontSize: 12, letterSpacing: 0.3, color: AppColors.muted, fontWeight: FontWeight.w500)),
    backgroundColor: AppColors.bg,
    margin: const EdgeInsets.only(bottom: 8),
    dividerMargin: 52,
    children: rows,
  );

  Widget _row(BuildContext context, IconData icon, String label, String value, VoidCallback onTap, {bool accent = false}) =>
    CupertinoListTile.notched(
      onTap: onTap,
      backgroundColor: AppColors.surface,
      leading: Icon(icon, size: 22, color: accent ? AppColors.accent : AppColors.text),
      title: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500,
        color: accent ? AppColors.accent : AppColors.text)),
      additionalInfo: value.isNotEmpty
          ? Text(value, style: const TextStyle(fontSize: 14, color: AppColors.muted))
          : null,
      trailing: const CupertinoListTileChevron(),
    );

  String _fmt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
