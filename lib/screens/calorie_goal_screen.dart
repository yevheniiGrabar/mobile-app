import 'package:flutter/cupertino.dart';
import '../theme.dart';
import '../data/diary.dart';

/// Ціль калорій (iOS-native, Cupertino): вага/зріст/вік/стать/активність/ціль →
/// денна норма за формулою Міффліна-Сан-Жеора. Оновлює кільце на Головній.
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

  int get _target {
    final bmr = _male
        ? (10 * _weight + 6.25 * _height - 5 * _age + 5)
        : (10 * _weight + 6.25 * _height - 5 * _age - 161);
    final tdee = bmr * (_activityFactors[_activity] ?? 1.55);
    return ((tdee * (_goalFactors[_goal] ?? 1.0)) / 10).round() * 10;
  }

  int _macro(double share, double perGram) => (_target * share / perGram).round();

  @override
  Widget build(BuildContext context) {
    final kcal = _target;
    return CupertinoPageScaffold(
      backgroundColor: AppColors.bg,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Ціль калорій'),
        backgroundColor: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.line, width: 0.5)),
      ),
      child: SafeArea(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          // Результат
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.accentSoft, AppColors.surface]),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
            ),
            child: Column(children: [
              const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(CupertinoIcons.sparkles, size: 15, color: AppColors.accent),
                SizedBox(width: 6),
                Text('Зоряна рахує норму', style: TextStyle(fontSize: 12.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 8),
              Text('$kcal', style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: AppColors.accent, height: 1)),
              const Text('ккал / день', style: TextStyle(fontSize: 13, color: AppColors.muted)),
              const SizedBox(height: 14),
              Row(children: [
                _macroChip('Білки', '${_macro(0.30, 4)} г', AppColors.blue),
                _macroChip('Жири', '${_macro(0.30, 9)} г', AppColors.amber),
                _macroChip('Вуглеводи', '${_macro(0.40, 4)} г', AppColors.carbs),
              ]),
            ]),
          ),
          const SizedBox(height: 18),

          _section('СТАТЬ', _segmented<bool>(_male, {true: 'Чоловік', false: 'Жінка'}, (v) => setState(() => _male = v))),
          _slider('Вага', _weight, 40, 160, 'кг', (v) => setState(() => _weight = v)),
          _slider('Зріст', _height, 140, 210, 'см', (v) => setState(() => _height = v)),
          _slider('Вік', _age, 14, 90, 'р.', (v) => setState(() => _age = v)),
          _section('АКТИВНІСТЬ', _segmented<String>(_activity, {'low': 'Низька', 'moderate': 'Середня', 'high': 'Висока'}, (v) => setState(() => _activity = v))),
          _section('ЦІЛЬ', _segmented<String>(_goal, {'lose': 'Схуднення', 'maintain': 'Підтримка', 'gain': 'Набір'}, (v) => setState(() => _goal = v))),

          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: CupertinoButton(
            color: AppColors.accent, borderRadius: BorderRadius.circular(14),
            onPressed: () {
              DiaryStore.instance.applyGoal(
                weightKg: _weight, heightCm: _height, age: _age, isMale: _male,
                activity: _activity, goalMode: _goal, kcal: kcal,
              );
              showCupertinoDialog(
                context: context,
                builder: (c) => CupertinoAlertDialog(
                  title: const Text('Готово'),
                  content: Text('Денна ціль: $kcal ккал'),
                  actions: [CupertinoDialogAction(
                    isDefaultAction: true,
                    onPressed: () { Navigator.of(c).pop(); Navigator.of(context).pop(); },
                    child: const Text('OK'))],
                ),
              );
            },
            child: const Text('Зберегти ціль', style: TextStyle(fontWeight: FontWeight.w700)),
          )),
          const SizedBox(height: 8),
          const Center(child: Text('Формула Міффліна-Сан-Жеора · рекомендація, не медична порада',
            style: TextStyle(fontSize: 10.5, color: AppColors.muted))),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _section(String title, Widget child) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(title, style: const TextStyle(fontSize: 12, letterSpacing: 0.5, color: AppColors.muted, fontWeight: FontWeight.w600))),
      child,
    ]),
  );

  Widget _segmented<T extends Object>(T value, Map<T, String> options, ValueChanged<T> onChanged) {
    return SizedBox(width: double.infinity, child: CupertinoSlidingSegmentedControl<T>(
      groupValue: value,
      backgroundColor: AppColors.surface2,
      thumbColor: AppColors.surface,
      children: {
        for (final e in options.entries)
          e.key: Padding(padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(e.value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
      },
      onValueChanged: (v) { if (v != null) onChanged(v); },
    ));
  }

  Widget _slider(String label, int val, int min, int max, String unit, ValueChanged<int> onChanged) => Container(
    margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.line)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        Text('$val $unit', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 16)),
      ]),
      CupertinoSlider(value: val.toDouble(), min: min.toDouble(), max: max.toDouble(),
        divisions: max - min, activeColor: AppColors.accent,
        onChanged: (v) => onChanged(v.round())),
    ]),
  );

  Widget _macroChip(String l, String v, Color c) => Expanded(child: Column(children: [
    Text(v, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: c)),
    const SizedBox(height: 2),
    Text(l, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
  ]));
}
