import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../models.dart';
import '../screens/recipe_screen.dart';
import 'dish_image.dart';
import 'swap_sheet.dart';

/// Картка страви: велике фото зверху («AI verified» + тип приймання на фото,
/// кнопка-оновлення), під ним — назва, короткий акцент і ккал·ціна.
class MealCard extends StatelessWidget {
  final Meal meal;
  const MealCard({super.key, required this.meal});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RecipeScreen(meal: meal))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.surface, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.line),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Фото + оверлеї.
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Stack(children: [
              SizedBox(height: 150, width: double.infinity, child: DishImage(meal: meal)),
              // Скрим знизу для читабельності білого тексту.
              Positioned(left: 0, right: 0, bottom: 0, child: Container(height: 64,
                decoration: BoxDecoration(gradient: LinearGradient(
                  begin: Alignment.bottomCenter, end: Alignment.topCenter,
                  colors: [Colors.black.withValues(alpha: 0.45), Colors.transparent])))),
              // AI verified (зліва зверху).
              const Positioned(top: 10, left: 10, child: _AiBadge()),
              // Кнопка-оновлення / заміна страви (справа зверху).
              Positioned(top: 8, right: 8, child: _RefreshButton(onTap: () => showSwapSheet(context, meal))),
              // Тип приймання (зліва знизу).
              Positioned(left: 12, bottom: 10, child: Text(meal.type.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 12, letterSpacing: 0.6,
                  fontWeight: FontWeight.w700))),
            ]),
          ),
          // Тіло: назва + акцент ліворуч, ккал + ціна праворуч.
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(meal.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.2)),
                const SizedBox(height: 4),
                Text(meal.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
              ])),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${meal.kcal}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text)),
                const Text('ккал', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                if (meal.price > 0) ...[
                  const SizedBox(height: 6),
                  Text('${meal.price} ₴', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.green)),
                ],
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Бейдж «AI verified» — білий напівпрозорий чіп із зеленою галочкою.
class _AiBadge extends StatelessWidget {
  const _AiBadge();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(20)),
    child: const Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.verified, size: 13, color: AppColors.accent),
      SizedBox(width: 4),
      Text('AI verified', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.accent)),
    ]),
  );
}

/// Кнопка «оновити/замінити страву» — дві кругові стрілки.
class _RefreshButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RefreshButton({required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Container(
      width: 34, height: 34,
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.92), shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 6, offset: const Offset(0, 2))]),
      child: const Icon(CupertinoIcons.arrow_2_circlepath, size: 18, color: AppColors.accent),
    ),
  );
}
