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
      home: const MainShell(),
    );
  }
}
