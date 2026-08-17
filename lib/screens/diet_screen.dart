import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import '../theme.dart';
import '../data/menu_prefs.dart';

/// Раціон і алергії — система харчування, кухні, здорові фільтри,
/// алергії/виключення та кухонна техніка. Усе враховує Зоряна при генерації.
class DietScreen extends StatefulWidget {
  const DietScreen({super.key});
  @override
  State<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends State<DietScreen> {
  final _p = MenuPrefs.instance;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.bg,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Раціон і алергії'), backgroundColor: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.line, width: 0.5))),
      child: SafeArea(child: ListView(padding: const EdgeInsets.all(16), children: [
        _dietSystemCard(),
        _multiCard('Кухні', MenuPrefs.allCuisines, _p.cuisines),
        _multiCard('Здорові фільтри', MenuPrefs.allHealthFilters, _p.healthFilters),
        _multiCard('Алергії та виключення', MenuPrefs.allAllergies, _p.allergies, warn: true),
        _multiCard('Кухонне обладнання', MenuPrefs.allEquipment, _p.equipment, ok: true),
        const SizedBox(height: 4),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('Зоряна врахує це при складанні меню. Система харчування та алергії — '
            'жорсткі правила, кухні й фільтри — побажання.',
            style: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.3))),
      ])),
    );
  }

  /// Система харчування — вибір ОДНОГО (radio-чіпи).
  Widget _dietSystemCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Система харчування', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 4),
        const Text('Обери одну — це жорстке правило для меню', style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final e in MenuPrefs.dietSystems.entries)
            _chip(e.value, _p.dietSystem == e.key,
              onTap: () => setState(() { _p.dietSystem = e.key; _p.notify(); }),
              fill: AppColors.accent, fg: Colors.white),
        ]),
      ]),
    );
  }

  /// Мультивибір чіпів (кухні / фільтри / алергії / техніка).
  Widget _multiCard(String title, List<String> all, Set<String> sel, {bool warn = false, bool ok = false}) {
    final fill = warn ? AppColors.warn.withValues(alpha: 0.16)
        : ok ? AppColors.accent.withValues(alpha: 0.16) : AppColors.accent;
    final border = warn ? AppColors.warn : AppColors.accent;
    final fg = (warn || ok) ? AppColors.text : Colors.white;
    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final t in all)
            _chip(t, sel.contains(t),
              onTap: () => setState(() { sel.contains(t) ? sel.remove(t) : sel.add(t); _p.notify(); }),
              fill: fill, fg: fg, border: border),
        ]),
      ]),
    );
  }

  Widget _chip(String label, bool active, {required VoidCallback onTap, required Color fill, required Color fg, Color? border}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active ? fill : AppColors.surface2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? (border ?? fill) : AppColors.line)),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
          color: active ? fg : AppColors.text)),
      ),
    );
  }
}
