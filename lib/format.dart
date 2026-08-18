/// Формат грошей у ₴: показуємо копійки, коли вони є (69.90), і ціле — коли нема (70).
String uah(num v) {
  final s = v.toStringAsFixed(2);
  return s.endsWith('.00') ? s.substring(0, s.length - 3) : s;
}
