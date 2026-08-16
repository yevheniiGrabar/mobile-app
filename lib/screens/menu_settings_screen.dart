import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../data/stores.dart';
import '../data/api/mealize_api.dart';

/// Налаштування меню (бюджет / склад сім'ї / раціон / алергії / техніка / магазин).
/// Відкривається як під-екран із вкладки «Профіль».
class MenuSettingsScreen extends StatefulWidget {
  const MenuSettingsScreen({super.key});
  @override
  State<MenuSettingsScreen> createState() => _MenuSettingsScreenState();
}

class _MenuSettingsScreenState extends State<MenuSettingsScreen> {
  double budget = 2000;
  int people = 2;
  final prefs = {'ПП', 'Білкове', 'Овочі', 'Бюджетно', 'Здивуй мене'};
  final selectedPrefs = <String>{'ПП'};
  final allergies = {'Горіхи', 'Лактоза', 'Глютен', 'Морепродукти', 'Яйця', 'Соя', 'Цитрусові'};
  final selectedAllergies = <String>{};
  final equipment = {'Плита', 'Духовка', 'Мікрохвильовка', 'Мультиварка', 'Аерогриль', 'Блендер'};
  final selectedEquip = <String>{'Плита', 'Духовка'};

  final _api = MealizeApi();
  bool _generating = false;

  /// Реальна генерація меню через BFF (agent → matching → optimizer).
  Future<void> _generate() async {
    setState(() => _generating = true);
    String title = 'Готово';
    String msg = '';
    try {
      final result = await _api.generateAndWait({
        'budget': budget.round(),
        'mode': 'economy',
        'people': people,
        'diet_style': 'pp',
        'appliances': selectedEquip.toList(),
        'allergies': selectedAllergies.toList(),
        // branch_id не шлемо — бекенд підставить реальну філію Сільпо.
      });
      final data = result['data'] as Map<String, dynamic>?;
      if (data?['status'] == 'ready') {
        msg = 'Меню на тиждень готове 🎉\nЕкономія ${data?['savings'] ?? 0} ₴ проти звичайних цін.';
      } else {
        final err = (data?['error'] ?? '').toString();
        title = 'Не вдалося';
        msg = err.contains('401')
            ? 'Спочатку підключи Сільпо: Профіль → «Підключити Сільпо» (телефон + код). Без цього Зоряна не бачить акцій.'
            : 'Помилка генерації: ${err.isEmpty ? "невідома" : err}';
      }
    } on ApiException catch (e) {
      title = 'Не вдалося';
      msg = 'Бекенд: ${e.message}';
    } catch (_) {
      title = 'Бекенд недоступний';
      msg = 'Сервер не відповідає. Запусти BFF (php artisan serve) і спробуй ще раз.';
    } finally {
      if (mounted) setState(() => _generating = false);
    }
    if (mounted) _showResult(title, msg);
  }

  void _showResult(String title, String msg) {
    showCupertinoDialog(
      context: context,
      builder: (c) => CupertinoAlertDialog(
        title: Text(title),
        content: Text('\n$msg'),
        actions: [CupertinoDialogAction(isDefaultAction: true, onPressed: () => Navigator.of(c).pop(), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.bg,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Налаштування меню'), backgroundColor: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.line, width: 0.5))),
      child: SafeArea(child: ListView(padding: const EdgeInsets.all(16), children: [
        _storeSelector(),
        _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Бюджет на тиждень', style: TextStyle(fontWeight: FontWeight.w700)),
            Text('${budget.round()} ₴', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w800, fontSize: 16)),
          ]),
          CupertinoSlider(value: budget, min: 800, max: 10000, divisions: 46, activeColor: AppColors.accent,
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
        SizedBox(width: double.infinity, child: CupertinoButton(
          color: AppColors.accent, borderRadius: BorderRadius.circular(14),
          onPressed: _generating ? null : _generate,
          child: _generating
              ? const CupertinoActivityIndicator(color: AppColors.accentInk)
              : const Text('Скласти меню на тиждень', style: TextStyle(fontWeight: FontWeight.w700)),
        )),
        const SizedBox(height: 24),
      ])),
    );
  }

  /// Селектор ринку + магазину (мультиринкова основа: Сільпо/Instacart/…).
  Widget _storeSelector() {
    final reg = StoreRegistry.instance;
    final stores = reg.providersFor(reg.activeMarket).map((p) => p.info).toList();
    return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: const [
        Icon(Icons.storefront_outlined, size: 18, color: AppColors.accent),
        SizedBox(width: 8),
        Text('Магазин та ринок', style: TextStyle(fontWeight: FontWeight.w700)),
      ]),
      const SizedBox(height: 4),
      const Text('Замовляй у своєму магазині — Україна, США, Європа',
        style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
      const SizedBox(height: 12),
      Row(children: [
        for (final m in Market.values) ...[
          Expanded(child: GestureDetector(
            onTap: () => setState(() {
              reg.activeMarket = m;
              final first = reg.providersFor(m).where((p) => p.info.enabled);
              if (first.isNotEmpty) reg.activeStoreId = first.first.info.id;
            }),
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(vertical: 9),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: reg.activeMarket == m ? AppColors.accent : AppColors.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: reg.activeMarket == m ? AppColors.accent : AppColors.line)),
              child: Text(m.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                color: reg.activeMarket == m ? AppColors.accentInk : AppColors.text)),
            ),
          )),
        ],
      ]),
      const SizedBox(height: 12),
      Column(children: [
        for (final s in stores) _storeRow(reg, s),
      ]),
    ]));
  }

  Widget _storeRow(StoreRegistry reg, StoreInfo s) {
    final active = reg.activeStoreId == s.id;
    return Opacity(
      opacity: s.enabled ? 1 : 0.55,
      child: GestureDetector(
        onTap: s.enabled ? () => setState(() => reg.select(s.id)) : null,
        child: Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: active ? AppColors.accentSoft : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? AppColors.accent : AppColors.line)),
          child: Row(children: [
            Text(s.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
              Text(s.note, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            ])),
            if (!s.enabled)
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(8)),
                child: const Text('Скоро', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.muted)))
            else if (active)
              const Icon(Icons.check_circle, color: AppColors.accent, size: 20)
            else
              const Icon(Icons.circle_outlined, color: AppColors.muted, size: 20),
          ]),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
    margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
    child: child);

  Widget _round(IconData i, VoidCallback f) => GestureDetector(onTap: f, child: Container(
    width: 34, height: 34, decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(9)),
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
                color: sel.contains(t) ? (warn ? AppColors.warn.withValues(alpha: 0.18) : (ok ? AppColors.green.withValues(alpha: 0.18) : AppColors.accent)) : AppColors.surface2,
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
