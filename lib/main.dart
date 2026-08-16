import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'theme.dart';
import 'shell.dart';

void main() => runApp(const RozumnyiKoshykApp());

class RozumnyiKoshykApp extends StatelessWidget {
  const RozumnyiKoshykApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Розумний кошик',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      // CupertinoTheme дає стилі навбарам; DefaultTextStyle — базовий стиль тексту
      // для CupertinoPageScaffold-екранів (інакше текст падає в аварійний
      // червоний+підкреслений стиль, бо лише CupertinoApp/Material ставлять його).
      builder: (context, child) => DefaultTextStyle(
        style: const TextStyle(
          color: AppColors.text, fontSize: 15,
          fontFamily: '.SF Pro Text', decoration: TextDecoration.none,
        ),
        child: CupertinoTheme(
          data: const CupertinoThemeData(
            primaryColor: AppColors.accent,
            primaryContrastingColor: AppColors.accentInk,
            scaffoldBackgroundColor: AppColors.bg,
            barBackgroundColor: AppColors.surface,
            applyThemeToAll: true,
            textTheme: CupertinoTextThemeData(
              primaryColor: AppColors.accent,
              textStyle: TextStyle(color: AppColors.text, fontSize: 15, fontFamily: '.SF Pro Text', decoration: TextDecoration.none),
              navLargeTitleTextStyle: TextStyle(color: AppColors.text, fontSize: 30, fontWeight: FontWeight.w800, fontFamily: '.SF Pro Text', decoration: TextDecoration.none, letterSpacing: 0.2),
              navTitleTextStyle: TextStyle(color: AppColors.text, fontSize: 17, fontWeight: FontWeight.w700, fontFamily: '.SF Pro Text', decoration: TextDecoration.none),
            ),
          ),
          child: child!,
        ),
      ),
      home: const MainShell(),
    );
  }
}
