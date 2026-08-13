import 'package:flutter/material.dart';
import '../theme.dart';

/// Пейвол Pro (Stitch #18): Базовий 0₴ / Pro + 7 днів безкоштовно.
/// Реальна оплата — через IAP (Apple/Google) / RevenueCat. Тут лише UI.
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});
  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  int plan = 1; // 0 = місяць, 1 = рік (герой)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(backgroundColor: AppColors.bg, elevation: 0,
        leading: const CloseButton(), title: const Text('Mealize Pro', style: TextStyle(fontWeight: FontWeight.w800))),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 24), children: [
        Center(child: Container(
          width: 72, height: 72,
          decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: const RadialGradient(center: Alignment(-0.3, -0.3), radius: 0.9, colors: [Color(0xFF4FD08A), AppColors.accent]),
            boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.35), blurRadius: 20, spreadRadius: 2)]),
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 34),
        )),
        const SizedBox(height: 16),
        const Text('Готуй розумніше з Pro', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text('Зоряна без обмежень, повні КБЖУ та історія меню',
          textAlign: TextAlign.center, style: TextStyle(fontSize: 13.5, color: AppColors.muted)),
        const SizedBox(height: 20),
        _feature('Необмежені меню на тиждень'),
        _feature('Повні калорії та БЖУ на кожну страву'),
        _feature('Зоряна (голос) без лімітів'),
        _feature('Безлімітна заміна страв під бюджет'),
        _feature('Історія та «повторити тиждень»'),
        _feature('Розклад і нагадування'),
        const SizedBox(height: 22),
        _planCard(1, 'Річний', '990 ₴ / рік', '≈ 82 ₴/міс · економія 45%', badge: 'ВИГІДНО'),
        const SizedBox(height: 10),
        _planCard(0, 'Місячний', '149 ₴ / міс', 'Гнучко, скасувати будь-коли'),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: FilledButton(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Оформлення підписки — через App Store / Google Play (IAP)'), duration: Duration(seconds: 3))),
          style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: AppColors.accentInk, padding: const EdgeInsets.symmetric(vertical: 16)),
          child: const Text('Спробувати 7 днів безкоштовно', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        )),
        const SizedBox(height: 8),
        Center(child: Text(plan == 1 ? 'Далі 990 ₴/рік · скасувати будь-коли' : 'Далі 149 ₴/міс · скасувати будь-коли',
          style: const TextStyle(fontSize: 11.5, color: AppColors.muted))),
        const SizedBox(height: 12),
        const Center(child: Text('Базовий план назавжди безкоштовний',
          style: TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600))),
      ]),
    );
  }

  Widget _feature(String t) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Container(width: 22, height: 22, decoration: const BoxDecoration(color: AppColors.accentSoft, shape: BoxShape.circle),
        child: const Icon(Icons.check, size: 14, color: AppColors.accent)),
      const SizedBox(width: 12),
      Expanded(child: Text(t, style: const TextStyle(fontSize: 14))),
    ]),
  );

  Widget _planCard(int idx, String title, String price, String sub, {String? badge}) {
    final sel = plan == idx;
    return GestureDetector(
      onTap: () => setState(() => plan = idx),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: sel ? AppColors.accentSoft : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: sel ? AppColors.accent : AppColors.line, width: sel ? 2 : 1)),
        child: Row(children: [
          Icon(sel ? Icons.radio_button_checked : Icons.radio_button_off, color: sel ? AppColors.accent : AppColors.muted),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              if (badge != null) Padding(padding: const EdgeInsets.only(left: 8),
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(8)),
                  child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)))),
            ]),
            const SizedBox(height: 3),
            Text(sub, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ])),
          Text(price, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
        ]),
      ),
    );
  }
}
