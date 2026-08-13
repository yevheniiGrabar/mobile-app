import 'package:flutter/material.dart';
import '../theme.dart';

/// Голосовий асистент «Зоряна» (скелет UI). STT/LLM-tools підключимо далі.
const assistantName = 'Зоряна';

void showAssistant(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _AssistantSheet(),
  );
}

class _AssistantSheet extends StatelessWidget {
  const _AssistantSheet();

  @override
  Widget build(BuildContext context) {
    final suggestions = [
      'Склади меню на тиждень на 2000 грн',
      'Додай масло в список покупок',
      'Порахуй калорії цього обіду',
      'Заміни вечерю на щось дешевше',
      'Замов на вечір ці продукти',
    ];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(
                color: AppColors.line, borderRadius: BorderRadius.circular(4))),
            ),
            const SizedBox(height: 16),
            Row(children: [
              const CircleAvatar(radius: 18, backgroundColor: AppColors.accentInk,
                child: Icon(Icons.auto_awesome, color: AppColors.accent, size: 20)),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                Text(assistantName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                Text('Привіт! Що готуємо цього тижня?', style: TextStyle(fontSize: 12.5, color: AppColors.muted)),
              ]),
            ]),
            const SizedBox(height: 20),
            const Text('СПРОБУЙ ПОПРОСИТИ', style: TextStyle(fontSize: 11, letterSpacing: 1, color: AppColors.muted, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final s in suggestions)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.line)),
                  child: Text(s, style: const TextStyle(fontSize: 12.5, color: AppColors.text)),
                ),
            ]),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.line)),
                  child: const Text('Напиши або натисни мікрофон…', style: TextStyle(color: AppColors.muted)),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('🎙️ Зоряна слухає… (STT підключимо далі)'),
                    duration: Duration(seconds: 2)));
                },
                child: Container(
                  width: 56, height: 56,
                  decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                  child: const Icon(Icons.mic, color: AppColors.accentInk, size: 28),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            const Center(child: Text('Перед оформленням Зоряна завжди перепитає підтвердження',
              style: TextStyle(fontSize: 10.5, color: AppColors.muted))),
          ],
        ),
      ),
    );
  }
}
