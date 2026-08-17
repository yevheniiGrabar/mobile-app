import 'package:flutter/cupertino.dart';
import '../theme.dart';
import '../data/menu_prefs.dart';

/// Тижневий бюджет — скільки готові витратити на продукти за тиждень.
/// Використовується при складанні меню та для контролю витрат на Головній.
class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});
  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _p = MenuPrefs.instance;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.bg,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Тижневий бюджет'), backgroundColor: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.line, width: 0.5))),
      child: SafeArea(child: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Бюджет на тиждень', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              Text('${_p.budget.round()} ₴', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w800, fontSize: 18)),
            ]),
            const SizedBox(height: 8),
            CupertinoSlider(value: _p.budget, min: 800, max: 10000, divisions: 46, activeColor: AppColors.accent,
              onChanged: (v) => setState(() { _p.budget = v; _p.notify(); })),
            const Text('800 (Економ) · 5 000 (Оптимальний) · 10 000 (Преміум)',
              style: TextStyle(fontSize: 11, color: AppColors.muted)),
          ]),
        ),
        const SizedBox(height: 12),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('Зоряна складе меню в межах бюджету, а на Головній ти бачитимеш, скільки вже витрачено.',
            style: TextStyle(fontSize: 12, color: AppColors.muted))),
      ])),
    );
  }
}
