import 'package:flutter/cupertino.dart';
import '../theme.dart';
import '../data/menu_prefs.dart';

/// Тижневий бюджет + режим генерації (Ціна/Якість) і — для якості —
/// дозволене перевищення бюджету (додатковий бюджет у %).
class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});
  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _p = MenuPrefs.instance;

  @override
  Widget build(BuildContext context) {
    final quality = _p.mode == 'quality';
    return CupertinoPageScaffold(
      backgroundColor: AppColors.bg,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Тижневий бюджет'), backgroundColor: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.line, width: 0.5))),
      child: SafeArea(child: ListView(padding: const EdgeInsets.all(16), children: [
        // ── Бюджет ──────────────────────────────────────────────
        _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Бюджет на тиждень', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            Text('${_p.budget.round()} ₴', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w800, fontSize: 18)),
          ]),
          const SizedBox(height: 8),
          CupertinoSlider(value: _p.budget, min: 800, max: 10000, divisions: 46, activeColor: AppColors.accent,
            onChanged: (v) => setState(() { _p.budget = v; _p.notify(); })),
          const Text('800 (Економ) · 5 000 (Оптимальний) · 10 000 (Преміум)',
            style: TextStyle(fontSize: 11, color: AppColors.muted)),
        ])),
        const SizedBox(height: 12),

        // ── Режим ───────────────────────────────────────────────
        _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Режим', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: CupertinoSlidingSegmentedControl<String>(
            groupValue: _p.mode,
            backgroundColor: AppColors.surface2,
            thumbColor: AppColors.accent,
            children: {
              'economy': _seg('Ціна', _p.mode == 'economy'),
              'quality': _seg('Якість', _p.mode == 'quality'),
            },
            onValueChanged: (v) => setState(() {
              _p.mode = v ?? 'economy';
              if (_p.mode == 'economy') _p.flexPct = 0; // строго в межах
              _p.notify();
            }),
          )),
          const SizedBox(height: 12),
          Row(children: [
            Icon(quality ? CupertinoIcons.star_fill : CupertinoIcons.tag_fill, size: 15, color: AppColors.accent),
            const SizedBox(width: 8),
            Expanded(child: Text(
              quality
                  ? 'Зоряна дивиться на склад і обирає кращі продукти. Акції — приємний бонус.'
                  : 'Зоряна тримається акцій і шукає найдешевше в межах бюджету.',
              style: const TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.3))),
          ]),
        ])),

        // ── Додатковий бюджет (лише для якості) ─────────────────
        if (quality) ...[
          const SizedBox(height: 12),
          _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Додатковий бюджет', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              Text(_p.flexPct == 0 ? 'вимкнено' : '+${_p.flexPct}%',
                style: TextStyle(color: _p.flexPct == 0 ? AppColors.muted : AppColors.accent, fontWeight: FontWeight.w800, fontSize: 16)),
            ]),
            const SizedBox(height: 4),
            const Text('Наскільки Зоряна може вийти за бюджет заради якості',
              style: TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 8),
            CupertinoSlider(value: _p.flexPct.toDouble(), min: 0, max: 50, divisions: 10, activeColor: AppColors.accent,
              onChanged: (v) => setState(() { _p.flexPct = v.round(); _p.notify(); })),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(CupertinoIcons.plus_circle_fill, size: 16, color: AppColors.accent),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  _p.flexPct == 0
                      ? 'Суворо в межах ${_p.budget.round()} ₴'
                      : '+${_p.flexAmount} ₴ понад бюджет · разом до ${(_p.budget + _p.flexAmount).round()} ₴',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.accent))),
              ]),
            ),
          ])),
        ],

        const SizedBox(height: 12),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('Зоряна складе меню за цими правилами, а на Головній ти бачитимеш, скільки вже витрачено.',
            style: TextStyle(fontSize: 12, color: AppColors.muted))),
      ])),
    );
  }

  Widget _seg(String label, bool active) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
      color: active ? AppColors.accentInk : AppColors.text)));

  Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
    child: child);
}
