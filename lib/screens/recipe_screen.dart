import 'dart:async';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../models.dart';
import '../widgets/swap_sheet.dart';

/// Екран рецепта (Stitch #16): велике фото, БЖУ, інгредієнти, кроки + таймер.
class RecipeScreen extends StatefulWidget {
  final Meal meal;
  const RecipeScreen({super.key, required this.meal});
  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  Timer? _timer;
  late int _remaining; // секунди
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.meal.minutes * 60;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
    } else {
      setState(() => _running = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_remaining <= 1) {
          t.cancel();
          setState(() { _remaining = 0; _running = false; });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('⏰ Готово! Смачного 🍽️'), duration: Duration(seconds: 3)));
        } else {
          setState(() => _remaining--);
        }
      });
    }
  }

  void _reset() {
    _timer?.cancel();
    setState(() { _remaining = widget.meal.minutes * 60; _running = false; });
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.meal;
    final mm = (_remaining ~/ 60).toString().padLeft(2, '0');
    final ss = (_remaining % 60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 240, pinned: true, backgroundColor: AppColors.bg,
          foregroundColor: Colors.white,
          leading: const BackButton(color: Colors.white),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(fit: StackFit.expand, children: [
              Image.network(m.imageUrl, fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(color: AppColors.accentSoft,
                  child: const Icon(Icons.ramen_dining, size: 60, color: AppColors.accent))),
              const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
                begin: Alignment.center, end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black54]))),
            ]),
          ),
        ),
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.type.toUpperCase(), style: const TextStyle(fontSize: 11, letterSpacing: 1, color: AppColors.accent, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(m.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, height: 1.15)),
            const SizedBox(height: 12),
            // Метрики
            Row(children: [
              _metric(Icons.local_fire_department, '${m.kcal}', 'ккал', AppColors.amber),
              _metric(Icons.timer_outlined, '${m.minutes}', 'хв', AppColors.accent),
              _metric(Icons.payments_outlined, '${m.price}', '₴', AppColors.green),
              _metric(Icons.kitchen, m.equipment, '', AppColors.muted),
            ]),
            const SizedBox(height: 14),
            // БЖУ
            _macroRow(m),
            const SizedBox(height: 20),
            _timerCard(mm, ss),
            const SizedBox(height: 20),
            const Text('Інгредієнти', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            if (m.ingredients.isEmpty)
              const Text('Список підтягнеться з меню', style: TextStyle(color: AppColors.muted, fontSize: 13))
            else
              ...m.ingredients.map((i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(children: [
                  const Icon(Icons.fiber_manual_record, size: 8, color: AppColors.accent),
                  const SizedBox(width: 10),
                  Expanded(child: Text('${i.name} · ${i.qty}', style: const TextStyle(fontSize: 13.5))),
                  Text('${i.price} ₴', style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w700, fontSize: 13)),
                ]),
              )),
            const SizedBox(height: 20),
            const Text('Приготування', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            ...m.cookSteps.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 26, height: 26, alignment: Alignment.center,
                  decoration: const BoxDecoration(color: AppColors.accentSoft, shape: BoxShape.circle),
                  child: Text('${e.key + 1}', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w800, fontSize: 13))),
                const SizedBox(width: 12),
                Expanded(child: Padding(padding: const EdgeInsets.only(top: 3),
                  child: Text(e.value, style: const TextStyle(fontSize: 14, height: 1.35)))),
              ]),
            )),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: OutlinedButton.icon(
              onPressed: () => showSwapSheet(context, m),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent), padding: const EdgeInsets.symmetric(vertical: 13)),
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Замінити страву', style: TextStyle(fontWeight: FontWeight.w700)),
            )),
            const SizedBox(height: 24),
          ]),
        )),
      ]),
    );
  }

  Widget _metric(IconData i, String v, String u, Color c) => Expanded(child: Column(children: [
    Icon(i, color: c, size: 20),
    const SizedBox(height: 4),
    Text(v, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
    if (u.isNotEmpty) Text(u, style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
  ]));

  Widget _macroRow(Meal m) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
    child: Row(children: [
      _macro('Білки', '${m.protein} г', AppColors.blue),
      _macro('Жири', '${m.fat} г', AppColors.amber),
      _macro('Вуглеводи', '${m.carbs} г', AppColors.carbs),
    ]),
  );

  Widget _macro(String l, String v, Color c) => Expanded(child: Column(children: [
    Text(v, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: c)),
    const SizedBox(height: 2),
    Text(l, style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
  ]));

  Widget _timerCard(String mm, String ss) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: const LinearGradient(colors: [AppColors.accentSoft, AppColors.surface]),
      border: Border.all(color: AppColors.line)),
    child: Row(children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Таймер приготування', style: TextStyle(fontSize: 12.5, color: AppColors.muted)),
        const SizedBox(height: 2),
        Text('$mm:$ss', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, height: 1.1, fontFeatures: [FontFeature.tabularFigures()])),
      ]),
      const Spacer(),
      IconButton(onPressed: _reset, icon: const Icon(Icons.restart_alt), color: AppColors.muted),
      const SizedBox(width: 4),
      FilledButton.icon(
        onPressed: _toggle,
        style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: AppColors.accentInk, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
        icon: Icon(_running ? Icons.pause : Icons.play_arrow),
        label: Text(_running ? 'Пауза' : 'Старт', style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    ]),
  );
}
