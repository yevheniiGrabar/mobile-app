import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../format.dart';
import '../data/menu_prefs.dart';
import '../data/plan_store.dart';
import '../data/api/mealize_api.dart';
import '../widgets/silpo_connection_card.dart';
import 'diet_screen.dart';
import 'family_screen.dart';

/// Вкладка «Бюджет» — хаб налаштування та запуску меню:
/// бюджет + режим + к-сть днів + раціон + склад сім'ї + кнопка «Скласти меню».
/// [onGenerated] — перемкнути на Головну після готового меню.
class BudgetTabScreen extends StatefulWidget {
  const BudgetTabScreen({super.key, this.onGenerated});
  final VoidCallback? onGenerated;

  @override
  State<BudgetTabScreen> createState() => _BudgetTabScreenState();
}

class _BudgetTabScreenState extends State<BudgetTabScreen> {
  final _p = MenuPrefs.instance;
  bool _generating = false;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.bg,
      child: CustomScrollView(slivers: [
        const CupertinoSliverNavigationBar(backgroundColor: AppColors.bg, border: null, largeTitle: Text('Бюджет')),
        SliverToBoxAdapter(child: AnimatedBuilder(
          animation: _p,
          builder: (_, _) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SilpoConnectionCard(),
              const SizedBox(height: 16),

              // ── Бюджет ──
              _budgetCard(),
              const SizedBox(height: 12),

              // ── Режим ──
              _modeCard(),
              if (_p.mode == 'quality') ...[const SizedBox(height: 12), _flexCard()],
              const SizedBox(height: 12),

              // ── Днів у меню ──
              _daysCard(),
              const SizedBox(height: 12),

              // ── Раціон + сім'я ──
              _rowsCard(),
              const SizedBox(height: 20),

              // ── Скласти меню ──
              SizedBox(width: double.infinity, child: CupertinoButton(
                color: AppColors.accent, borderRadius: BorderRadius.circular(14),
                onPressed: _generating ? null : _openGenerateSheet,
                child: _generating
                    ? const CupertinoActivityIndicator(color: AppColors.accentInk)
                    : Text('Скласти меню на ${_p.days} ${dayWord(_p.days)}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.accentInk)),
              )),
              const SizedBox(height: 8),
              const Text('Зоряна складе меню за цими правилами. Готове меню — на Головній і у «Список».',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.muted)),
            ]),
          ),
        )),
      ]),
    );
  }

  Widget _budgetCard() => _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      const Text('Бюджет на тиждень', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      Text('${_p.budget.round()} ₴', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w800, fontSize: 18)),
    ]),
    const SizedBox(height: 8),
    CupertinoSlider(value: _p.budget, min: 800, max: 10000, divisions: 46, activeColor: AppColors.accent,
      onChanged: (v) => setState(() { _p.budget = v; _p.notify(); })),
    const Text('800 (Економ) · 5 000 (Оптимальний) · 10 000 (Преміум)',
      style: TextStyle(fontSize: 11, color: AppColors.muted)),
  ]));

  Widget _modeCard() => _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Режим', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
    const SizedBox(height: 12),
    SizedBox(width: double.infinity, child: CupertinoSlidingSegmentedControl<String>(
      groupValue: _p.mode,
      backgroundColor: AppColors.surface2,
      thumbColor: AppColors.accent,
      children: {'economy': _seg('Ціна', _p.mode == 'economy'), 'quality': _seg('Якість', _p.mode == 'quality')},
      onValueChanged: (v) => setState(() {
        _p.mode = v ?? 'economy';
        if (_p.mode == 'economy') _p.flexPct = 0;
        _p.notify();
      }),
    )),
    const SizedBox(height: 12),
    Row(children: [
      Icon(_p.mode == 'quality' ? CupertinoIcons.star_fill : CupertinoIcons.tag_fill, size: 15, color: AppColors.accent),
      const SizedBox(width: 8),
      Expanded(child: Text(
        _p.mode == 'quality'
            ? 'Зоряна обирає кращі продукти. Акції — приємний бонус.'
            : 'Зоряна тримається акцій і шукає найдешевше в межах бюджету.',
        style: const TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.3))),
    ]),
  ]));

  Widget _flexCard() => _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      const Text('Додатковий бюджет', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      Text(_p.flexPct == 0 ? 'вимкнено' : '+${_p.flexPct}%',
        style: TextStyle(color: _p.flexPct == 0 ? AppColors.muted : AppColors.accent, fontWeight: FontWeight.w800, fontSize: 16)),
    ]),
    const SizedBox(height: 4),
    const Text('Наскільки Зоряна може вийти за бюджет заради якості', style: TextStyle(fontSize: 12, color: AppColors.muted)),
    const SizedBox(height: 8),
    CupertinoSlider(value: _p.flexPct.toDouble(), min: 0, max: 50, divisions: 10, activeColor: AppColors.accent,
      onChanged: (v) => setState(() { _p.flexPct = v.round(); _p.notify(); })),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(12)),
      child: Text(_p.flexPct == 0
          ? 'Суворо в межах ${_p.budget.round()} ₴'
          : '+${_p.flexAmount} ₴ понад бюджет · разом до ${(_p.budget + _p.flexAmount).round()} ₴',
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.accent)),
    ),
  ]));

  Widget _daysCard() => _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Меню на', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
    const SizedBox(height: 12),
    Row(children: [
      for (final d in MenuPrefs.dayOptions)
        Expanded(child: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() { _p.days = d; _p.notify(); }),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _p.days == d ? AppColors.accent : AppColors.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _p.days == d ? AppColors.accent : AppColors.line)),
              child: Text('$d', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                color: _p.days == d ? AppColors.accentInk : AppColors.text)),
            ),
          ),
        )),
    ]),
  ]));

  Widget _rowsCard() => Container(
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
    child: Column(children: [
      _navRow(Icons.eco_outlined, 'Раціон і алергії', '${_p.filtersCount} фільтри',
        () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DietScreen()))),
      const Divider(height: 1, thickness: 1, color: AppColors.line, indent: 52),
      _navRow(Icons.groups_outlined, 'Склад сім\'ї', '${_p.people} ос.',
        () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FamilyScreen()))),
    ]),
  );

  Widget _navRow(IconData icon, String label, String value, VoidCallback onTap) => CupertinoListTile.notched(
    onTap: onTap,
    backgroundColor: AppColors.surface,
    leading: Icon(icon, size: 22, color: AppColors.text),
    title: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
    additionalInfo: Text(value, style: const TextStyle(fontSize: 14, color: AppColors.muted)),
    trailing: const CupertinoListTileChevron(),
  );

  Widget _seg(String label, bool active) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
      color: active ? AppColors.accentInk : AppColors.text)));

  Widget _card(Widget child) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
    child: child);

  void _openGenerateSheet() {
    final mode = _p.mode == 'quality' ? 'Якість${_p.flexPct > 0 ? ' +${_p.flexPct}%' : ''}' : 'Ціна';
    final summary = 'Меню на: ${_p.days} ${dayWord(_p.days)}\n'
        'Бюджет: ${_p.budget.round()} ₴/тиждень · $mode\n'
        'Раціон: ${_p.dietSystemLabel}${_p.filtersCount > 0 ? ' · ${_p.filtersCount} фільтрів' : ''}\n'
        'Осіб: ${_p.people}';
    showCupertinoDialog<void>(
      context: context,
      builder: (c) => CupertinoAlertDialog(
        title: Text('Скласти меню на ${_p.days} ${dayWord(_p.days)}'),
        content: Text('\n$summary'),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.of(c).pop(), child: const Text('Скасувати')),
          CupertinoDialogAction(isDefaultAction: true,
            onPressed: () { Navigator.of(c).pop(); _generate(); }, child: const Text('Скласти')),
        ],
      ),
    );
  }

  Future<void> _generate() async {
    setState(() => _generating = true);
    String title = 'Готово';
    String msg = '';
    bool ready = false;
    try {
      final result = await MealizeApi.instance.generateAndWait(_p.toRequestBody());
      final data = result['data'] as Map<String, dynamic>?;
      final status = data?['status'];
      if (status == 'ready') {
        PlanStore.instance.setFromPlan(data!);
        ready = true;
        final total = (data['optimized_total'] as num?)?.toInt() ?? 0;
        final budget = _p.budget.round();
        title = 'Меню готове 🎉';
        msg = total <= budget
            ? 'Кошик: $total ₴ — у межах бюджету ($budget ₴).\nДивись на Головній і у «Список».'
            : 'Кошик: $total ₴ — більше за бюджет ($budget ₴).\nЗбав дні або підніми бюджет.';
      } else if (status == 'generating' || status == 'pending') {
        title = 'Ще готуємо';
        msg = 'Меню генерується довше звичайного. Воно зʼявиться саме за хвилину.';
      } else {
        final err = (data?['error'] ?? '').toString();
        title = 'Не вдалося';
        msg = err.contains('401')
            ? 'Спочатку підключи Сільпо (кнопка вгорі).'
            : 'Помилка генерації: ${err.isEmpty ? "невідома" : err}';
      }
    } on ApiException catch (e) {
      title = 'Не вдалося';
      msg = 'Бекенд: ${e.message}';
    } catch (_) {
      title = 'Бекенд недоступний';
      msg = 'Сервер не відповідає. Спробуй ще раз.';
    } finally {
      if (mounted) setState(() => _generating = false);
    }
    if (!mounted) return;
    showCupertinoDialog<void>(context: context, builder: (c) => CupertinoAlertDialog(
      title: Text(title), content: Text('\n$msg'),
      actions: [CupertinoDialogAction(isDefaultAction: true,
        onPressed: () { Navigator.of(c).pop(); if (ready) widget.onGenerated?.call(); },
        child: Text(ready ? 'Дивитись' : 'OK'))],
    ));
  }
}
