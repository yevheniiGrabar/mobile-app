import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme.dart';
import 'app_mark.dart';
import '../screens/recipes_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/diary_screen.dart';
import '../screens/subscription_screen.dart';

/// Бічне меню (зліва, кнопка «три смужки» на Головній).
/// Каталог + трекінг + корисне — усе, що не є основними вкладками таб-бару.
class AppMenuDrawer extends StatelessWidget {
  const AppMenuDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.bg,
      width: MediaQuery.of(context).size.width * 0.82,
      child: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _header(),
          Expanded(child: ListView(padding: const EdgeInsets.only(top: 4, bottom: 24), children: [
            _section('КАТАЛОГ'),
            _item(context, Icons.menu_book_outlined, 'Рецепти', 'усі страви',
                () => const RecipesScreen()),
            _item(context, Icons.local_offer_outlined, 'Акції Сільпо', 'знижки тижня', null),
            _section('ТРЕКІНГ'),
            _item(context, Icons.book_outlined, 'Щоденник', 'що з’їдено',
                () => const DiaryScreen()),
            _item(context, Icons.insights_outlined, 'Аналітика', 'витрати · економія · калорії',
                () => const AnalyticsScreen()),
            _item(context, Icons.auto_awesome_outlined, 'Історія меню', 'минулі плани', null),
            _section('КОРИСНЕ'),
            _proItem(context),
            _item(context, Icons.new_releases_outlined, 'Що нового', '', null),
            _item(context, Icons.help_outline, 'Підтримка', '', null),
            _item(context, Icons.info_outline, 'Про застосунок', 'v1.0', null),
          ])),
        ]),
      ),
    );
  }

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
        child: Row(children: [
          const AppMark(size: 46),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Mealize', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.accent)),
            Text('Розумна тарілка', style: TextStyle(fontSize: 12.5, color: AppColors.muted)),
          ])),
        ]),
      );

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
        child: Text(t, style: const TextStyle(fontSize: 12, letterSpacing: 0.3, color: AppColors.muted, fontWeight: FontWeight.w600)),
      );

  Widget _item(BuildContext context, IconData icon, String label, String sub, Widget Function()? page) =>
      ListTile(
        leading: Icon(icon, color: AppColors.text, size: 22),
        title: Text(label, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600)),
        subtitle: sub.isEmpty ? null : Text(sub, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        trailing: const Icon(CupertinoIcons.chevron_right, size: 16, color: AppColors.muted),
        onTap: () {
          Navigator.of(context).pop(); // закрити меню
          if (page == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Розділ у розробці'), duration: Duration(seconds: 2)));
          } else {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => page()));
          }
        },
      );

  Widget _proItem(BuildContext context) => ListTile(
        leading: const Icon(Icons.workspace_premium, color: AppColors.accent, size: 22),
        title: const Text('Mealize Pro', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: AppColors.accent)),
        subtitle: const Text('безлімітні меню від Зоряни', style: TextStyle(fontSize: 12, color: AppColors.muted)),
        trailing: const Icon(CupertinoIcons.chevron_right, size: 16, color: AppColors.muted),
        onTap: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const SubscriptionScreen(), fullscreenDialog: true));
        },
      );
}
