import 'package:flutter/material.dart';
import '../theme.dart';
import '../models.dart';

/// Фото страви: спершу локальний ассет (миттєво, гарно), якщо немає —
/// мережева AI-генерація, у крайньому разі — градієнт-плейсхолдер.
class DishImage extends StatelessWidget {
  final Meal meal;
  final BoxFit fit;
  const DishImage({super.key, required this.meal, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      meal.assetImage,
      fit: fit,
      gaplessPlayback: true,
      errorBuilder: (c, e, s) => Image.network(
        meal.imageUrl,
        fit: fit,
        loadingBuilder: (c, child, progress) => progress == null ? child : _ph(true),
        errorBuilder: (c, e, s) => _ph(false),
      ),
    );
  }

  Widget _ph(bool loading) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [AppColors.surface2, AppColors.accentSoft]),
        ),
        child: Center(child: Icon(loading ? Icons.restaurant : Icons.ramen_dining,
            color: AppColors.accent.withValues(alpha: 0.7), size: 28)),
      );
}
