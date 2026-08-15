import 'package:flutter/material.dart';
import '../theme.dart';
import '../models.dart';
import '../screens/recipe_screen.dart';
import 'dish_image.dart';
import 'swap_sheet.dart';

/// Картка страви у стилі Stitch: фото зліва, тип+ціна зверху,
/// назва, ккал·час, кнопка «Замінити» праворуч.
class MealCard extends StatelessWidget {
  final Meal meal;
  const MealCard({super.key, required this.meal});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RecipeScreen(meal: meal))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface, borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _DishImage(meal: meal),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _Pill(text: meal.type.toUpperCase(), color: AppColors.surface2, textColor: AppColors.muted),
              const Spacer(),
              Text('${meal.price} ₴', style: const TextStyle(color: AppColors.green, fontSize: 16, fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 6),
            Text(meal.title, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, height: 1.2)),
            const SizedBox(height: 8),
            Row(children: [
              _MiniTag(icon: Icons.local_fire_department, text: '${meal.kcal} ккал', color: AppColors.amber),
              const SizedBox(width: 14),
              _MiniTag(icon: Icons.timer_outlined, text: '${meal.minutes} хв', color: AppColors.muted),
            ]),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () => showSwapSheet(context, meal),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent, side: const BorderSide(color: AppColors.accent),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                icon: const Icon(Icons.swap_horiz, size: 16),
                label: const Text('Замінити', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
              ),
            ),
          ])),
        ]),
      ),
    );
  }
}

/// Мініатюра страви.
class _DishImage extends StatelessWidget {
  final Meal meal;
  const _DishImage({required this.meal});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(width: 92, height: 92, child: DishImage(meal: meal)),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final IconData icon; final String text; final Color color;
  const _MiniTag({required this.icon, required this.text, required this.color});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 14, color: color),
    const SizedBox(width: 4),
    Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
  ]);
}

class _Pill extends StatelessWidget {
  final String text; final Color color; final Color? textColor;
  const _Pill({required this.text, required this.color, this.textColor});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
    child: Text(text, style: TextStyle(fontSize: 10.5, letterSpacing: 0.5, fontWeight: FontWeight.w700, color: textColor ?? AppColors.accentInk)),
  );
}
