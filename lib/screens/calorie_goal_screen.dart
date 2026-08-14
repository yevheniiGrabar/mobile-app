import 'package:flutter/material.dart';
import '../theme.dart';
import '../data/diary.dart';

/// Ціль калорій: вага/зріст/вік/стать/активність/ціль → денна норма
/// (формула Міффліна-Сан-Жеора). Оновлює кільце калорій на Головній.
class CalorieGoalScreen extends StatefulWidget {
  const CalorieGoalScreen({super.key});
  @override
  State<CalorieGoalScreen> createState() => _CalorieGoalScreenState();
}

class _CalorieGoalScreenState extends State<CalorieGoalScreen> {
  late bool _male = DiaryStore.isMale;
  late int _weight = DiaryStore.weightKg;
  late int _height = DiaryStore.heightCm;
  late int _age = DiaryStore.age;
  late String _activity = DiaryStore.activity;
  late String _goal = DiaryStore.goalMode;

  static const _activityFactors = {'low': 1.375, 'moderate': 1.55, 'high': 1.725};
  static const _goalFactors = {'lose': 0.85, 'maintain': 1.0, 'gain': 1.12};

  /// Mifflin-St Jeor → BMR → TDEE → ціль (округлення до 10 ккал).
  int get _target {
    final bmr = _male
        ? (10 * _weight + 6.25 * _height - 5 * _age + 5)
        : (10 * _weight + 6.25 * _height - 5 * _age - 161);
    final tdee = bmr * (_activityFactors[_activity] ?? 1.55);
    final target = tdee * (_goalFactors[_goal] ?? 1.0);
    return (target / 10).round() * 10;
  }

  int _macro(double share, double perGram) => (_target * share / perGram).round();

  @override
  Widget build(BuildContext context) {
    final kcal = _target;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(backgroundColor: AppColors.bg, elevation: 0, leading: const BackButton(),
        title: const Text('Ціль калорій', style: TextStyle(fontWeight: FontWeight.w800))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // Результат
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.accentSoft, AppColors.surface]),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.3))),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.auto_awesome, size: 16, color: AppColors.accent),
              const SizedBox(width: 6),
              const Text('Зоряна рахує норму', style: TextStyle(fontSize: 12.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 8),
            Text('$kcal', style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: AppColors.accent, height: 1)),
            const Text('ккал / день', style: TextStyle(fontSize: 13, color: AppColors.muted)),
            const SizedBox(height: 14),
            Row(children: [
              _macroChip('Білки', '${_macro(0.30, 4)} г', AppColors.blue),
              _macroChip('Жири', '${_macro(0.30, 9)} г', AppColors.amber),
              _macroChip('Вуглеводи', '${_macro(0.40, 4)} г', AppColors.carbs),
            ]),
          ]),
        ),
        const SizedBox(height: 16),

        _card(child: _segmented('Стать', {'Чоловік': true, 'Жінка': false}, _male, (v) => setState(() => _male = v))),
        _slider('Вага', _weight, 40, 160, 'кг', (v) => setState(() => _weight = v)),
        _slider('Зріст', _height, 140, 210, 'см', (v) => setState(() => _height = v)),
        _slider('Вік', _age, 14, 90, 'р.', (v) => setState(() => _age = v)),
        _card(child: _segmented('Активність', {'Низька': 'low', 'Середня': 'moderate', 'Висока': 'high'}, _activity, (v) => setState(() => _activity = v))),
        _card(child: _segmented('Ціль', {'Схуднення': 'lose', 'Підтримка': 'maintain', 'Набір': 'gain'}, _goal, (v) => setState(() => _goal = v))),

        const SizedBox(height: 8),
        SizedBox(width: double.infinity, child: FilledButton.icon(
          onPressed: () {
            DiaryStore.instance.applyGoal(
              weightKg: _weight, heightCm: _height, age: _age, isMale: _male,
              activity: _activity, goalMode: _goal, kcal: kcal,
            );
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Ціль збережено: $kcal ккал/день'), duration: const Duration(seconds: 2)));
            Navigator.of(context).pop();
          },
          style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: AppColors.accentInk, padding: const EdgeInsets.symmetric(vertical: 15)),
          icon: const Icon(Icons.check),
          label: const Text('Зберегти ціль', style: TextStyle(fontWeight: FontWeight.w800)),
        )),
        const SizedBox(height: 8),
        const Center(child: Text('Формула Міффліна-Сан-Жеора · рекомендація, не медична порада',
          style: TextStyle(fontSize: 10.5, color: AppColors.muted))),
        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _card({required Widget child}) => Container(
    margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
    child: child);

  Widget _slider(String label, int val, int min, int max, String unit, ValueChanged<int> onChanged) => _card(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        Text('$val $unit', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w800, fontSize: 16)),
      ]),
      Slider(value: val.toDouble(), min: min.toDouble(), max: max.toDouble(),
        divisions: max - min, activeColor: AppColors.accent,
        onChanged: (v) => onChanged(v.round())),
    ]),
  );

  Widget _segmented<T>(String title, Map<String, T> options, T selected, ValueChanged<T> onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      Row(children: [
        for (final e in options.entries) ...[
          Expanded(child: GestureDetector(
            onTap: () => onChanged(e.value),
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(vertical: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected == e.value ? AppColors.accent : AppColors.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selected == e.value ? AppColors.accent : AppColors.line)),
              child: Text(e.key, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700,
                color: selected == e.value ? AppColors.accentInk : AppColors.text)),
            ),
          )),
        ],
      ]),
    ]);
  }

  Widget _macroChip(String l, String v, Color c) => Expanded(child: Column(children: [
    Text(v, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: c)),
    const SizedBox(height: 2),
    Text(l, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
  ]));
}
