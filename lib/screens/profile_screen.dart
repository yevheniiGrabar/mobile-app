import 'package:flutter/material.dart';
import '../theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  double budget = 2000;
  int people = 2;
  final prefs = {'ПП', 'Білкове', 'Овочі', 'Бюджетно', 'Здивуй мене'};
  final selectedPrefs = <String>{'ПП'};
  final allergies = {'Горіхи', 'Лактоза', 'Глютен', 'Морепродукти', 'Яйця', 'Соя', 'Цитрусові'};
  final selectedAllergies = <String>{};
  final equipment = {'Плита', 'Духовка', 'Мікрохвильовка', 'Мультиварка', 'Аерогриль', 'Блендер'};
  final selectedEquip = <String>{'Плита', 'Духовка'};

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(slivers: [
      SliverAppBar(pinned: true, backgroundColor: AppColors.bg,
        title: const Text('Налаштування меню', style: TextStyle(fontWeight: FontWeight.w800))),
      SliverToBoxAdapter(child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Бюджет на тиждень', style: TextStyle(fontWeight: FontWeight.w700)),
              Text('${budget.round()} ₴', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w800, fontSize: 16)),
            ]),
            Slider(value: budget, min: 800, max: 10000, divisions: 46, activeColor: AppColors.accent,
              onChanged: (v) => setState(() => budget = v)),
            const Text('800 (Економ) · 5 000 (Оптимальний) · 10 000 (Преміум)', style: TextStyle(fontSize: 11, color: AppColors.muted)),
          ])),
          _card(child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Кількість осіб', style: TextStyle(fontWeight: FontWeight.w700)),
              Text('Розрахунок порцій', style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
            ]),
            Row(children: [
              _round(Icons.remove, () => setState(() { if (people > 1) people--; })),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Text('$people', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
              _round(Icons.add, () => setState(() => people++)),
            ]),
          ])),
          _chips('Харчові вподобання', prefs, selectedPrefs),
          _chips('Алергії та виключення', allergies, selectedAllergies, warn: true),
          _chips('Кухонне обладнання', equipment, selectedEquip, ok: true),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, child: FilledButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('✨ Генерація меню — підключимо агента + Silpo MCP'), duration: Duration(seconds: 2))),
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: AppColors.accentInk, padding: const EdgeInsets.symmetric(vertical: 15)),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Скласти меню на тиждень', style: TextStyle(fontWeight: FontWeight.w800)),
          )),
          const SizedBox(height: 90),
        ]),
      )),
    ]);
  }

  Widget _card({required Widget child}) => Container(
    margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
    child: child);

  Widget _round(IconData i, VoidCallback f) => GestureDetector(onTap: f, child: Container(
    width: 34, height: 34, decoration: BoxDecoration(color: AppColors.accentInk, borderRadius: BorderRadius.circular(9)),
    child: Icon(i, color: AppColors.accent, size: 20)));

  Widget _chips(String title, Set<String> all, Set<String> sel, {bool warn = false, bool ok = false}) {
    return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final t in all)
          GestureDetector(
            onTap: () => setState(() => sel.contains(t) ? sel.remove(t) : sel.add(t)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: sel.contains(t) ? (warn ? AppColors.warn.withOpacity(0.18) : (ok ? AppColors.green.withOpacity(0.18) : AppColors.accent)) : AppColors.surface2,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sel.contains(t) ? (warn ? AppColors.warn : (ok ? AppColors.green : AppColors.accent)) : AppColors.line),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (sel.contains(t) && ok) const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.check, size: 14, color: AppColors.green)),
                Text(t, style: TextStyle(fontSize: 12.5, color: sel.contains(t) && !warn && !ok ? AppColors.accentInk : AppColors.text, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
      ]),
    ]));
  }
}
