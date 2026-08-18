/// Формат грошей у ₴: показуємо копійки, коли вони є (69.90), і ціле — коли нема (70).
String uah(num v) {
  final s = v.toStringAsFixed(2);
  return s.endsWith('.00') ? s.substring(0, s.length - 3) : s;
}

/// Українське відмінювання «день»: 1 день, 2-4 дні, 5+ днів.
String dayWord(int n) {
  if (n == 1) return 'день';
  if (n >= 2 && n <= 4) return 'дні';
  return 'днів';
}
