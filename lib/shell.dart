import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/menu_screen.dart';
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
  final pages = const [MenuScreen(), CartScreen(), ProfileScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: index, children: pages),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAssistant(context),
        backgroundColor: AppColors.accent,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.mic, color: AppColors.accentInk, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: AppColors.surface,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        height: 76,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(icon: Icons.restaurant_menu, label: 'Меню', selected: index == 0, onTap: () => setState(() => index = 0)),
            _NavItem(icon: Icons.shopping_cart_outlined, label: 'Кошик', selected: index == 1, onTap: () => setState(() => index = 1)),
            const SizedBox(width: 48), // місце під FAB (Зоряна)
            _NavItem(icon: Icons.tune, label: 'Профіль', selected: index == 2, onTap: () => setState(() => index = 2)),
            const _NavItem(icon: Icons.auto_awesome, label: 'Зоряна', selected: false, onTap: null),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon; final String label; final bool selected; final VoidCallback? onTap;
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.accent : AppColors.muted;
    return InkWell(
      onTap: onTap ?? () {
        // «Зоряна» у барі теж відкриває асистента
        showAssistant(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}
