// ─────────────────────────────────────────────────────────────────────────
// МУЛЬТИРИНКОВА ОСНОВА: абстракція магазину/провайдера.
//
// Ідея: додаток працює не лише з Сільпо (Україна), а й з іншими мережами по
// регіонах. Кожен магазин ховається за інтерфейсом `StoreProvider`. Сьогодні
// живий тільки Silpo (через MCP), решта — задокументовані точки підключення.
// Коли АТБ зробить свій MCP-сервер — додаємо `AtbProvider` і вмикаємо його,
// нічого більше в UI не змінюючи.
// ─────────────────────────────────────────────────────────────────────────

/// Ринок (регіон користувача). Від нього залежить, які магазини доступні.
enum Market { ua, us, eu }

extension MarketX on Market {
  String get code => switch (this) { Market.ua => 'UA', Market.us => 'US', Market.eu => 'EU' };
  String get label => switch (this) {
        Market.ua => '🇺🇦 Україна',
        Market.us => '🇺🇸 США',
        Market.eu => '🇪🇺 Європа',
      };
}

/// Що вміє магазин: замовлення в 1 тап чи лише список покупок.
enum StoreCapability {
  /// Реальні ціни/асортимент + оформлення замовлення (checkout-лінк).
  ordering,

  /// Лише генерація списку покупок (немає публічного API замовлення).
  listOnly,
}

/// Статичний опис магазину для UI (селектор ринку/магазину).
class StoreInfo {
  final String id; // 'silpo', 'instacart', 'kroger', 'atb'
  final Market market;
  final String name;
  final String emoji;
  final StoreCapability capability;

  /// false → показуємо як «Скоро», вибрати не можна (напр. АТБ до появи MCP).
  final bool enabled;
  final String note;

  const StoreInfo({
    required this.id,
    required this.market,
    required this.name,
    required this.emoji,
    required this.capability,
    required this.enabled,
    this.note = '',
  });

  bool get canOrder => capability == StoreCapability.ordering && enabled;
}

/// Абстракція джерела продуктів/цін/кошика. Реальні реалізації підключають
/// свій транспорт (Silpo → MCP, Instacart/Kroger → REST, АТБ → майбутній MCP).
abstract class StoreProvider {
  StoreInfo get info;

  /// Пошук/матчинг продукту за назвою інгредієнта (реальні ціни).
  Future<List<StoreProduct>> searchProducts(String query);

  /// Побудувати кошик і повернути посилання на оформлення (web/mobile checkout).
  /// Оплату робить користувач на боці магазину — застосунок гроші не рухає.
  Future<CheckoutLink> buildCheckout(List<CartLine> lines);
}

class StoreProduct {
  final String sku;
  final String title;
  final int priceUah; // мінорні одиниці спрощено до грн для демо
  final bool onPromo;
  const StoreProduct(this.sku, this.title, this.priceUah, {this.onPromo = false});
}

class CartLine {
  final String query;
  final int qty;
  const CartLine(this.query, {this.qty = 1});
}

class CheckoutLink {
  final String webUrl;
  final String? mobileUrl;
  const CheckoutLink(this.webUrl, {this.mobileUrl});
}

/// Помилка «ще не підключено» — навмисна, щоб точки інтеграції були явними.
class ProviderNotWiredException implements Exception {
  final String storeId;
  const ProviderNotWiredException(this.storeId);
  @override
  String toString() => 'StoreProvider "$storeId" ще не підключено (заглушка)';
}

// ── Конкретні провайдери (поки заглушки; підключення транспорту — далі) ──────

/// 🇺🇦 Сільпо — головний ринок. Реальні дані через Silpo MCP.
/// TODO: під'єднати JSON-RPC (silpo_find_products_batch / silpo_get_promotions,
/// потрібні branchId + deliveryType + timeslot; checkout = checkoutWebLink).
class SilpoProvider implements StoreProvider {
  const SilpoProvider();
  @override
  StoreInfo get info => const StoreInfo(
        id: 'silpo', market: Market.ua, name: 'Сільпо', emoji: '🟢',
        capability: StoreCapability.ordering, enabled: true,
        note: 'Реальні ціни й акції · оформлення в 1 тап');
  @override
  Future<List<StoreProduct>> searchProducts(String query) async =>
      throw const ProviderNotWiredException('silpo'); // → Silpo MCP
  @override
  Future<CheckoutLink> buildCheckout(List<CartLine> lines) async =>
      throw const ProviderNotWiredException('silpo');
}

/// 🇺🇸 Instacart — одна інтеграція = сотні мереж США.
/// TODO: Instacart Developer Platform + MCP (shoppable recipe / shopping list).
class InstacartProvider implements StoreProvider {
  const InstacartProvider();
  @override
  StoreInfo get info => const StoreInfo(
        id: 'instacart', market: Market.us, name: 'Instacart', emoji: '🛒',
        capability: StoreCapability.ordering, enabled: false,
        note: 'США · сотні мереж через один API');
  @override
  Future<List<StoreProduct>> searchProducts(String query) async =>
      throw const ProviderNotWiredException('instacart');
  @override
  Future<CheckoutLink> buildCheckout(List<CartLine> lines) async =>
      throw const ProviderNotWiredException('instacart');
}

/// 🇺🇸 Kroger — пряме API/MCP великої мережі США.
class KrogerProvider implements StoreProvider {
  const KrogerProvider();
  @override
  StoreInfo get info => const StoreInfo(
        id: 'kroger', market: Market.us, name: 'Kroger', emoji: '🛒',
        capability: StoreCapability.ordering, enabled: false,
        note: 'США · пряме API мережі');
  @override
  Future<List<StoreProduct>> searchProducts(String query) async =>
      throw const ProviderNotWiredException('kroger');
  @override
  Future<CheckoutLink> buildCheckout(List<CartLine> lines) async =>
      throw const ProviderNotWiredException('kroger');
}

/// 🇺🇦 АТБ — чекаємо, поки зроблять MCP-сервер (план користувача).
/// Поки що вимкнено; додаток покаже «Скоро».
class AtbProvider implements StoreProvider {
  const AtbProvider();
  @override
  StoreInfo get info => const StoreInfo(
        id: 'atb', market: Market.ua, name: 'АТБ', emoji: '🔴',
        capability: StoreCapability.ordering, enabled: false,
        note: 'Скоро · щойно АТБ запустить MCP-сервер');
  @override
  Future<List<StoreProduct>> searchProducts(String query) async =>
      throw const ProviderNotWiredException('atb');
  @override
  Future<CheckoutLink> buildCheckout(List<CartLine> lines) async =>
      throw const ProviderNotWiredException('atb');
}

/// 🇪🇺 Європа (fallback) — поки лише список покупок, без 1-тап замовлення.
class ListOnlyEuProvider implements StoreProvider {
  const ListOnlyEuProvider();
  @override
  StoreInfo get info => const StoreInfo(
        id: 'eu_list', market: Market.eu, name: 'Список покупок', emoji: '📝',
        capability: StoreCapability.listOnly, enabled: true,
        note: 'ЄС · генеруємо список (замовлення — де з’являться API)');
  @override
  Future<List<StoreProduct>> searchProducts(String query) async => const [];
  @override
  Future<CheckoutLink> buildCheckout(List<CartLine> lines) async =>
      throw const ProviderNotWiredException('eu_list');
}

/// Реєстр магазинів + вибір активного. Єдина точка, звідки UI дізнається,
/// що доступно в поточному ринку. Додати магазин = додати провайдер сюди.
class StoreRegistry {
  StoreRegistry._();
  static final StoreRegistry instance = StoreRegistry._();

  final List<StoreProvider> _providers = const [
    SilpoProvider(),
    AtbProvider(),
    InstacartProvider(),
    KrogerProvider(),
    ListOnlyEuProvider(),
  ];

  Market activeMarket = Market.ua;
  String activeStoreId = 'silpo';

  List<StoreProvider> get all => _providers;

  List<StoreProvider> providersFor(Market m) =>
      _providers.where((p) => p.info.market == m).toList();

  StoreProvider get active =>
      _providers.firstWhere((p) => p.info.id == activeStoreId, orElse: () => const SilpoProvider());

  /// Обрати магазин (лише якщо він увімкнений).
  bool select(String storeId) {
    final p = _providers.where((p) => p.info.id == storeId);
    if (p.isEmpty || !p.first.info.enabled) return false;
    activeStoreId = storeId;
    activeMarket = p.first.info.market;
    return true;
  }
}
