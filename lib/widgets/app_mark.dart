import 'package:flutter/widgets.dart';

/// Фірмовий значок Mealize — «розумна тарілка» (лист + плата в тарілці).
/// Самодостатній: зелений диск із білим листом усередині, працює на будь-якому фоні.
/// [mealize_mark.png] — квадратний значок (шапка / бічне меню / app icon).
class AppMark extends StatelessWidget {
  const AppMark({super.key, this.size = 34});
  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/brand/mealize_mark.png',
        width: size, height: size, fit: BoxFit.contain, filterQuality: FilterQuality.medium,
      );
}

/// Повний логотип-локап (тарілка + виделка/ніж + «Mealize») — для сплешу,
/// шапки бічного меню, маркетингу.
class AppLogoFull extends StatelessWidget {
  const AppLogoFull({super.key, this.height = 40});
  final double height;

  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/brand/mealize_full.png',
        height: height, fit: BoxFit.contain, filterQuality: FilterQuality.medium,
      );
}
