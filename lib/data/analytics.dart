/// Типізована відповідь GET /api/analytics (маппінг 1:1 з AnalyticsService).
class AnalyticsData {
  final int spendCurrent, spendTrend;
  final List<({String label, int amount})> monthly;
  final List<({String name, int amount, int pct})> categories;
  final int savedTotal, savedRate;
  final List<({String name, int amount})> topSaved;
  final int kcalAvg, kcalGoal, streak, adhWithin, adhTotal;
  final List<int> weekly;
  final List<({String name, int count})> topItems;
  final PatternData? pattern;

  const AnalyticsData({
    required this.spendCurrent, required this.spendTrend, required this.monthly,
    required this.categories, required this.savedTotal, required this.savedRate,
    required this.topSaved, required this.kcalAvg, required this.kcalGoal,
    required this.streak, required this.adhWithin, required this.adhTotal,
    required this.weekly, required this.topItems, required this.pattern,
  });

  factory AnalyticsData.fromJson(Map<String, dynamic> j) {
    final spend = (j['spend'] as Map?)?.cast<String, dynamic>() ?? {};
    final savings = (j['savings'] as Map?)?.cast<String, dynamic>() ?? {};
    final cal = (j['calories'] as Map?)?.cast<String, dynamic>() ?? {};
    final adh = (cal['adherence'] as Map?)?.cast<String, dynamic>() ?? {};

    List<Map<String, dynamic>> list(dynamic v) =>
        ((v as List?) ?? const []).map((e) => (e as Map).cast<String, dynamic>()).toList();
    int i(dynamic v) => (v as num?)?.round() ?? 0;

    return AnalyticsData(
      spendCurrent: i(spend['current_month']),
      spendTrend: i(spend['trend_pct']),
      monthly: list(spend['monthly']).map((e) => (label: '${e['label']}', amount: i(e['amount']))).toList(),
      categories: list(j['categories']).map((e) => (name: '${e['name']}', amount: i(e['amount']), pct: i(e['pct']))).toList(),
      savedTotal: i(savings['total']),
      savedRate: i(savings['rate_pct']),
      topSaved: list(savings['top']).map((e) => (name: '${e['name']}', amount: i(e['amount']))).toList(),
      kcalAvg: i(cal['avg_per_day']),
      kcalGoal: i(cal['goal']) == 0 ? 1900 : i(cal['goal']),
      streak: i(cal['streak']),
      adhWithin: i(adh['within']),
      adhTotal: i(adh['total']),
      weekly: ((cal['weekly'] as List?) ?? const []).map((e) => i(e)).toList(),
      topItems: list(j['top_items']).map((e) => (name: '${e['name']}', count: i(e['count']))).toList(),
      pattern: j['pattern'] is Map ? PatternData.fromJson((j['pattern'] as Map).cast<String, dynamic>()) : null,
    );
  }
}

/// Патерн від Зоряни: день тижня → товари (з оцінкою ціни/калорій).
class PatternData {
  final String weekday;
  final List<String> items;
  final int occurrences, estPrice, estKcal;

  const PatternData({required this.weekday, required this.items,
    required this.occurrences, required this.estPrice, required this.estKcal});

  factory PatternData.fromJson(Map<String, dynamic> j) => PatternData(
        weekday: '${j['weekday'] ?? ''}',
        items: ((j['items'] as List?) ?? const []).map((e) => '$e').toList(),
        occurrences: (j['occurrences'] as num?)?.round() ?? 0,
        estPrice: (j['est_price'] as num?)?.round() ?? 0,
        estKcal: (j['est_kcal'] as num?)?.round() ?? 0,
      );
}
