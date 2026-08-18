import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../data/diary.dart';
import '../widgets/nutrition_rings_card.dart';
import 'recipes_screen.dart';

/// Щоденник харчування (сьогодні): кільця калорій + записи, згруповані
/// за прийомами їжі (Сніданок / Обід / Вечеря / Перекус) з «+ додати» у кожному.
class DiaryScreen extends StatelessWidget {
  const DiaryScreen({super.key});

  static const _order = ['Сніданок', 'Обід', 'Вечеря', 'Перекус'];

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.bg,
      child: CustomScrollView(slivers: [
        const CupertinoSliverNavigationBar(
          backgroundColor: AppColors.bg, border: null, largeTitle: Text('Щоденник')),
        SliverToBoxAdapter(child: AnimatedBuilder(
          animation: DiaryStore.instance,
          builder: (context, _) {
            final ds = DiaryStore.instance;
            return Padding(padding: const EdgeInsets.all(16), child: Column(children: [
              const NutritionRingsCard(),
              const SizedBox(height: 8),
              ..._mealSections(context, ds),
              const SizedBox(height: 90),
            ]));
          },
        )),
      ]),
    );
  }

  /// Усі прийоми (навіть порожні) з підсумком, записами та «+ додати».
  List<Widget> _mealSections(BuildContext context, DiaryStore ds) {
    final groups = <String, List<(int, DiaryEntry)>>{};
    for (var i = 0; i < ds.today.length; i++) {
      final e = ds.today[i];
      groups.putIfAbsent(e.meal, () => []).add((i, e));
    }
    final meals = [
      ..._order,
      ...groups.keys.where((m) => !_order.contains(m)),
    ];

    final out = <Widget>[];
    for (final meal in meals) {
      final items = groups[meal] ?? const [];
      final kcal = items.fold<int>(0, (s, x) => s + x.$2.kcal);
      out.add(_mealHeader(meal, kcal));
      for (final (idx, e) in items) {
        out.add(_entryRow(context, ds, idx, e));
      }
      out.add(_addButton(context, meal));
      out.add(const SizedBox(height: 14));
    }
    return out;
  }

  Widget _mealHeader(String meal, int kcal) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
    child: Row(children: [
      Icon(_mealIcon(meal), size: 16, color: AppColors.accent),
      const SizedBox(width: 6),
      Text(meal, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
      const Spacer(),
      if (kcal > 0) Text('$kcal ккал', style: const TextStyle(fontSize: 12.5, color: AppColors.muted, fontWeight: FontWeight.w700)),
    ]),
  );

  IconData _mealIcon(String meal) => switch (meal) {
    'Сніданок' => Icons.wb_sunny_outlined,
    'Обід' => Icons.restaurant,
    'Вечеря' => Icons.nightlight_outlined,
    _ => Icons.cookie_outlined,
  };

  Widget _addButton(BuildContext context, String meal) => Padding(
    padding: const EdgeInsets.only(top: 2),
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openAdd(context, meal),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.accentSoft, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.3))),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(CupertinoIcons.add, size: 16, color: AppColors.accent),
          SizedBox(width: 6),
          Text('Додати', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.accent)),
        ]),
      ),
    ),
  );

  Future<void> _openAdd(BuildContext context, String meal) async {
    final entry = await showModalBottomSheet<DiaryEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddEntrySheet(meal: meal),
    );
    if (entry != null) DiaryStore.instance.add(entry);
  }

  Widget _entryRow(BuildContext context, DiaryStore ds, int i, DiaryEntry e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.line)),
      child: Row(children: [
        Container(width: 40, height: 40, alignment: Alignment.center,
          decoration: const BoxDecoration(color: AppColors.accentSoft, shape: BoxShape.circle),
          child: const Icon(Icons.restaurant, size: 18, color: AppColors.accent)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(e.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text('${e.grams} г · Б ${e.protein} · Ж ${e.fat} · В ${e.carbs}', style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
        ])),
        Text('${e.kcal} ккал', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.accent)),
        IconButton(
          onPressed: () => ds.removeAt(i),
          icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.muted),
          visualDensity: VisualDensity.compact,
        ),
      ]),
    );
  }
}

/// Швидке додавання порції: ручний ввід або перехід до рецептів.
class _AddEntrySheet extends StatefulWidget {
  final String meal;
  const _AddEntrySheet({required this.meal});
  @override
  State<_AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<_AddEntrySheet> {
  final _title = TextEditingController();
  final _kcal = TextEditingController();
  final _grams = TextEditingController();
  final _p = TextEditingController();
  final _f = TextEditingController();
  final _c = TextEditingController();

  @override
  void dispose() {
    for (final ctl in [_title, _kcal, _grams, _p, _f, _c]) {
      ctl.dispose();
    }
    super.dispose();
  }

  bool get _valid => _title.text.trim().isNotEmpty && (int.tryParse(_kcal.text) ?? 0) > 0;

  void _save() {
    if (!_valid) return;
    Navigator.of(context).pop(DiaryEntry(
      _title.text.trim(),
      int.tryParse(_grams.text) ?? 0,
      int.tryParse(_kcal.text) ?? 0,
      int.tryParse(_p.text) ?? 0,
      int.tryParse(_f.text) ?? 0,
      int.tryParse(_c.text) ?? 0,
      meal: widget.meal,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(color: AppColors.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2)))),
          Text('Додати · ${widget.meal}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          _field(_title, 'Назва страви', keyboard: TextInputType.text),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _field(_kcal, 'Ккал', keyboard: TextInputType.number)),
            const SizedBox(width: 10),
            Expanded(child: _field(_grams, 'Грами', keyboard: TextInputType.number)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _field(_p, 'Білки, г', keyboard: TextInputType.number)),
            const SizedBox(width: 8),
            Expanded(child: _field(_f, 'Жири, г', keyboard: TextInputType.number)),
            const SizedBox(width: 8),
            Expanded(child: _field(_c, 'Вугл., г', keyboard: TextInputType.number)),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: CupertinoButton(
              color: AppColors.surface2, borderRadius: BorderRadius.circular(12), padding: const EdgeInsets.symmetric(vertical: 12),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RecipesScreen()));
              },
              child: const Text('З рецептів', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
            )),
            const SizedBox(width: 10),
            Expanded(child: AnimatedBuilder(
              animation: Listenable.merge([_title, _kcal]),
              builder: (_, _) => CupertinoButton(
                color: AppColors.accent, borderRadius: BorderRadius.circular(12), padding: const EdgeInsets.symmetric(vertical: 12),
                onPressed: _valid ? _save : null,
                child: const Text('Додати', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accentInk)),
              ),
            )),
          ]),
        ]),
      ),
    );
  }

  Widget _field(TextEditingController ctl, String hint, {required TextInputType keyboard}) => CupertinoTextField(
    controller: ctl,
    placeholder: hint,
    keyboardType: keyboard,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
  );
}
