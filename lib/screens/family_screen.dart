import 'package:flutter/cupertino.dart';
import '../theme.dart';
import '../data/menu_prefs.dart';

/// Склад сім'ї — скільки людей (для розрахунку порцій).
class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});
  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  final _p = MenuPrefs.instance;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.bg,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Склад сім\'ї'), backgroundColor: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.line, width: 0.5))),
      child: SafeArea(child: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Кількість осіб', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              SizedBox(height: 2),
              Text('Меню й порції на всіх', style: TextStyle(fontSize: 12.5, color: AppColors.muted)),
            ])),
            Row(children: [
              _round(CupertinoIcons.minus, () { if (_p.people > 1) setState(() { _p.people--; _p.notify(); }); }),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Text('${_p.people}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
              _round(CupertinoIcons.plus, () { if (_p.people < 10) setState(() { _p.people++; _p.notify(); }); }),
            ]),
          ]),
        ),
        const SizedBox(height: 12),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('Впливає на кількість інгредієнтів у списку покупок.', style: TextStyle(fontSize: 12, color: AppColors.muted))),
      ])),
    );
  }

  Widget _round(IconData i, VoidCallback f) => GestureDetector(onTap: f, child: Container(
    width: 40, height: 40, alignment: Alignment.center,
    decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(12)),
    child: Icon(i, color: AppColors.accent, size: 20)));
}
