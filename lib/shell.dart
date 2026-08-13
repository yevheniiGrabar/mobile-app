import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/home_screen.dart';
import 'screens/recipes_screen.dart';
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
  final pages = const [HomeScreen(), RecipesScreen(), CartScreen(), ProfileScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: index, children: pages),
      // Центральна кнопка «Зоряна» — голосовий асистент.
      floatingActionButton: GestureDetector(
        onTap: () => showAssistant(context),
        child: Container(
          width: 58, height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(center: Alignment(-0.3, -0.3), radius: 0.9,
              colors: [Color(0xFF4FD08A), AppColors.accent]),
            boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.4), blurRadius: 16, spreadRadius: 1)],
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 26),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: AppColors.surface,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        height: 74,
        padding: EdgeInsets.zero,
        child: Row(children: [
          Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _NavItem(icon: Icons.home_outlined, label: 'Головна', selected: index == 0, onTap: () => setState(() => index = 0)),
            _NavItem(icon: Icons.menu_book_outlined, label: 'Рецепти', selected: index == 1, onTap: () => setState(() => index = 1)),
          ])),
          const SizedBox(width: 64), // місце під центральну «Зоряну»
          Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _NavItem(icon: Icons.receipt_long_outlined, label: 'Список', selected: index == 2, onTap: () => setState(() => index = 2)),
            _NavItem(icon: Icons.person_outline, label: 'Профіль', selected: index == 3, onTap: () => setState(() => index = 3)),
          ])),
        ]),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon; final String label; final bool selected; final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.accent : AppColors.muted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 10.5, color: color, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}
