import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../data/diary.dart';
import '../data/menu_prefs.dart';
import '../widgets/silpo_connection_card.dart';
import 'calorie_goal_screen.dart';
import 'analytics_screen.dart';
import 'budget_screen.dart';
import 'family_screen.dart';
import 'diet_screen.dart';
import 'subscription_screen.dart';

/// Профіль: акаунт + групи налаштувань (кожна настройка — в одному місці).
/// Генерація меню — кнопкою на Головній.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.bg,
      child: CustomScrollView(slivers: [
      const CupertinoSliverNavigationBar(
        backgroundColor: AppColors.bg, border: null, largeTitle: Text('Профіль')),
      SliverToBoxAdapter(child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: Column(children: [
          _accountCard(context),
          const SizedBox(height: 12),
          const SilpoConnectionCard(),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: MenuPrefs.instance,
            builder: (_, _) => _group('НАЛАШТУВАННЯ', [
              _row(context, Icons.insights, 'Аналітика', '',
                () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AnalyticsScreen()))),
              _row(context, Icons.track_changes, 'Цілі калорій', '${DiaryStore.goalKcal} ккал',
                () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CalorieGoalScreen()))),
              _row(context, Icons.account_balance_wallet_outlined, 'Тижневий бюджет', '${MenuPrefs.instance.budget.round()} ₴',
                () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BudgetScreen()))),
              _row(context, Icons.groups_outlined, 'Склад сім\'ї', '${MenuPrefs.instance.people} ос.',
                () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FamilyScreen()))),
              _row(context, Icons.eco_outlined, 'Раціон і алергії', '${MenuPrefs.instance.filtersCount} фільтри',
                () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DietScreen()))),
            ]),
          ),
          const SizedBox(height: 16),
          _group('ЗАМОВЛЕННЯ', [
            // «Магазин та ринок» приховано — поки лише Сільпо (ринки US/EU — після хакатону).
            _row(context, Icons.location_on_outlined, 'Адреси доставки', '2', () => _soon(context)),
            _row(context, Icons.credit_card, 'Спосіб оплати', 'Apple Pay', () => _soon(context)),
            _row(context, Icons.history, 'Історія замовлень', '14', () => _soon(context)),
          ]),
          const SizedBox(height: 16),
          _group('ІНШЕ', [
            _row(context, Icons.workspace_premium, 'Mealize Pro', 'Спробувати', () =>
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SubscriptionScreen(), fullscreenDialog: true)), accent: true),
            _row(context, Icons.notifications_none, 'Сповіщення', '', () => _soon(context)),
            _row(context, Icons.help_outline, 'Підтримка', '', () => _soon(context)),
          ]),
          const SizedBox(height: 100),
        ]),
      )),
    ]));
  }

  void _soon(BuildContext c) => ScaffoldMessenger.of(c).showSnackBar(
      const SnackBar(content: Text('Розділ у розробці'), duration: Duration(seconds: 2)));

  Widget _accountCard(BuildContext context) => GestureDetector(
    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FamilyScreen())),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.line)),
      child: Row(children: [
        Container(width: 52, height: 52,
          decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: const RadialGradient(center: Alignment(-0.3, -0.3), radius: 0.9, colors: [Color(0xFF4FD08A), AppColors.accent])),
          child: const Icon(Icons.person, color: Colors.white, size: 26)),
        const SizedBox(width: 14),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Євгеній Грабар', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          SizedBox(height: 2),
          Text('Сім\'я — 2 особи', style: TextStyle(fontSize: 12.5, color: AppColors.muted)),
        ])),
        const Icon(Icons.chevron_right, color: AppColors.muted),
      ]),
    ),
  );

  /// Нативна iOS-група (як у Налаштуваннях): inset-grouped список.
  Widget _group(String title, List<Widget> rows) => CupertinoListSection.insetGrouped(
    header: Text(title, style: const TextStyle(fontSize: 12, letterSpacing: 0.3, color: AppColors.muted, fontWeight: FontWeight.w500)),
    backgroundColor: AppColors.bg,
    margin: const EdgeInsets.only(bottom: 8),
    dividerMargin: 52,
    children: rows,
  );

  Widget _row(BuildContext context, IconData icon, String label, String value, VoidCallback onTap, {bool accent = false}) =>
    CupertinoListTile.notched(
      onTap: onTap,
      backgroundColor: AppColors.surface,
      leading: Icon(icon, size: 22, color: accent ? AppColors.accent : AppColors.text),
      title: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500,
        color: accent ? AppColors.accent : AppColors.text)),
      additionalInfo: value.isNotEmpty
          ? Text(value, style: const TextStyle(fontSize: 14, color: AppColors.muted))
          : null,
      trailing: const CupertinoListTileChevron(),
    );
}
