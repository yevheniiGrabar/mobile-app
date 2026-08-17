import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/home_screen.dart';
import 'screens/diary_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/assistant_sheet.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;
  final pages = const [HomeScreen(), DiaryScreen(), CartScreen(), ProfileScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: IndexedStack(index: index, children: pages),
      // iOS tab bar: пласка, волосяна лінія зверху, без FAB.
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.line, width: 0.5)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 52,
            child: Row(children: [
              _tab(CupertinoIcons.house_fill, 'Головна', 0),
              _tab(CupertinoIcons.book_fill, 'Щоденник', 1),
              _zoryanaTab(),
              _tab(CupertinoIcons.list_bullet, 'Список', 2),
              _tab(CupertinoIcons.person_fill, 'Профіль', 3),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _tab(IconData icon, String label, int i) {
    final color = index == i ? AppColors.accent : AppColors.muted;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => index = i),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 10.5, color: color, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  /// Зоряна — теж пункт таб-бару (без плаваючого FAB), з фірмовим зеленим орбом.
  Widget _zoryanaTab() {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => showAssistant(context),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 30, height: 30,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(center: Alignment(-0.3, -0.3), radius: 0.9, colors: [Color(0xFF4FD08A), AppColors.accent]),
            ),
            child: const Icon(CupertinoIcons.sparkles, color: Colors.white, size: 17),
          ),
          const SizedBox(height: 3),
          const Text('Зоряна', style: TextStyle(fontSize: 10.5, color: AppColors.accent, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}
