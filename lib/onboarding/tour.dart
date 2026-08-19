import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';

/// Онбординг-тур (перший запуск): підсвічує елементи Головної та вкладки
/// таб-бару й пояснює, що за що. Власний оверлей (без сторонніх пакетів —
/// надійно рендериться на web). Ключі навішуються у home_screen/shell.
class Tour {
  Tour._();

  static final calendar = GlobalKey();
  static final budget = GlobalKey();
  static final mealCard = GlobalKey();
  static final tabBudget = GlobalKey();
  static final tabList = GlobalKey();
  static final tabDiary = GlobalKey();
  static final tabZoryana = GlobalKey();

  static const _seenKey = 'tour_seen_v1';

  static Future<void> maybeShow(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_seenKey) == true) return;
    if (!context.mounted) return;
    show(context, onDone: () => prefs.setBool(_seenKey, true));
  }

  static void show(BuildContext context, {VoidCallback? onDone}) {
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!context.mounted) return;
      final steps = _steps().where((s) => s.key.currentContext != null).toList();
      if (steps.isEmpty) { onDone?.call(); return; }
      final overlay = Overlay.of(context, rootOverlay: true);
      late OverlayEntry entry;
      entry = OverlayEntry(builder: (_) => _TourOverlay(
        steps: steps,
        onClose: () { entry.remove(); onDone?.call(); },
      ));
      overlay.insert(entry);
    });
  }

  static List<TourStep> _steps() => [
    TourStep(calendar, 'Твій тиждень', 'Обери день — і побачиш меню та скільки зʼїдено саме на нього.'),
    TourStep(budget, 'Бюджет тижня', 'Скільки вже витрачено з твого бюджету на продукти.'),
    TourStep(mealCard, 'Страви на день', 'Фото, калорії й ціна. Кругла кнопка на фото — замінити страву на іншу.'),
    TourStep(tabBudget, 'Бюджет — тут складаєш меню', 'Бюджет, режим (Ціна/Якість) і на скільки днів → кнопка «Скласти меню».'),
    TourStep(tabList, 'Список покупок', 'Реальні товари й ціни Сільпо, наявність і «Замовити в Сільпо».'),
    TourStep(tabDiary, 'Щоденник', 'Кільця калорій + додавай зʼїдене по прийомах (сніданок/обід/вечеря).'),
    TourStep(tabZoryana, 'Зоряна — твій помічник', 'Попроси скласти меню, замінити страву чи порахувати калорії.'),
  ];
}

class TourStep {
  final GlobalKey key;
  final String title, desc;
  TourStep(this.key, this.title, this.desc);
}

class _TourOverlay extends StatefulWidget {
  final List<TourStep> steps;
  final VoidCallback onClose;
  const _TourOverlay({required this.steps, required this.onClose});
  @override
  State<_TourOverlay> createState() => _TourOverlayState();
}

class _TourOverlayState extends State<_TourOverlay> {
  int i = 0;

  Rect? _rect(GlobalKey k) {
    final ctx = k.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  void _next() { if (i < widget.steps.length - 1) { setState(() => i++); } else { widget.onClose(); } }
  void _back() { if (i > 0) setState(() => i--); }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final step = widget.steps[i];
    final target = _rect(step.key) ?? Rect.fromLTWH(16, 80, size.width - 32, 60);
    final hole = target.inflate(6);
    final below = hole.center.dy < size.height * 0.5; // картка нижче цілі, якщо ціль угорі

    return Stack(children: [
      // Скрим із «діркою» на цілі + рамка.
      Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _ScrimPainter(hole)))),
      // Картка з поясненням.
      Positioned(
        left: 16, right: 16,
        top: below ? (hole.bottom + 14).clamp(0, size.height - 240) : null,
        bottom: below ? null : (size.height - hole.top + 14).clamp(0, size.height - 240),
        child: Center(child: _card(step)),
      ),
    ]);
  }

  Widget _card(TourStep step) {
    final total = widget.steps.length;
    final isFirst = i == 0, isLast = i == total - 1;
    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: const Color(0xFF14231A), borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 8))]),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('ГАЙД · ${i + 1}/$total', style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
          const Spacer(),
          GestureDetector(onTap: widget.onClose, child: const Icon(Icons.close, size: 18, color: Colors.white54)),
        ]),
        const SizedBox(height: 8),
        Text(step.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(step.desc, style: const TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.35)),
        const SizedBox(height: 14),
        Row(children: [
          for (var d = 0; d < total; d++)
            Container(width: d == i ? 18 : 7, height: 7, margin: const EdgeInsets.only(right: 5),
              decoration: BoxDecoration(color: d == i ? AppColors.accent : Colors.white24, borderRadius: BorderRadius.circular(4))),
          const Spacer(),
          if (isFirst)
            GestureDetector(onTap: widget.onClose, child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Text('Пропустити', style: TextStyle(color: Colors.white54, fontSize: 13.5, fontWeight: FontWeight.w600))))
          else
            GestureDetector(onTap: _back, child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Text('Назад', style: TextStyle(color: Colors.white70, fontSize: 13.5, fontWeight: FontWeight.w600)))),
          const SizedBox(width: 4),
          GestureDetector(onTap: _next, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(isLast ? 'Готово' : 'Далі', style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w800)),
              if (!isLast) ...[const SizedBox(width: 5), const Icon(Icons.arrow_forward, size: 15, color: Colors.white)],
            ]))),
        ]),
      ]),
    );
  }
}

class _ScrimPainter extends CustomPainter {
  final Rect hole;
  _ScrimPainter(this.hole);
  @override
  void paint(Canvas canvas, Size size) {
    final full = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(hole, const Radius.circular(14));
    canvas.saveLayer(full, Paint());
    canvas.drawRect(full, Paint()..color = const Color(0xFF0B1B12).withValues(alpha: 0.82));
    canvas.drawRRect(rrect, Paint()..blendMode = BlendMode.clear);
    canvas.restore();
    canvas.drawRRect(rrect, Paint()
      ..style = PaintingStyle.stroke..strokeWidth = 2..color = AppColors.accent);
  }

  @override
  bool shouldRepaint(covariant _ScrimPainter o) => o.hole != hole;
}
