import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import '../theme.dart';
import '../data/menu_prefs.dart';

/// Раціон і алергії — стиль харчування, виключення продуктів, кухонна техніка.
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
        _card('Харчові вподобання', MenuPrefs.allPrefs, _p.prefs),
        _card('Алергії та виключення', MenuPrefs.allAllergies, _p.allergies, warn: true),
        _card('Кухонне обладнання', MenuPrefs.allEquipment, _p.equipment, ok: true),
        const SizedBox(height: 4),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('Зоряна врахує це при складанні меню.', style: TextStyle(fontSize: 12, color: AppColors.muted))),
      ])),
    );
  }

  Widget _card(String title, List<String> all, Set<String> sel, {bool warn = false, bool ok = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final t in all)
            GestureDetector(
              onTap: () => setState(() { sel.contains(t) ? sel.remove(t) : sel.add(t); _p.notify(); }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: sel.contains(t)
                      ? (warn ? AppColors.warn.withValues(alpha: 0.16) : (ok ? AppColors.accent.withValues(alpha: 0.16) : AppColors.accent))
                      : AppColors.surface2,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sel.contains(t) ? (warn ? AppColors.warn : AppColors.accent) : AppColors.line)),
                child: Text(t, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: sel.contains(t) ? (warn || ok ? AppColors.text : Colors.white) : AppColors.text)),
              ),
            ),
        ]),
      ]),
    );
  }
}
