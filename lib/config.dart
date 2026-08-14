/// Конфіг застосунку. Базовий URL BFF можна задати через
/// `--dart-define=API_BASE_URL=https://...` (для web/прод); дефолт — локальний BFF.
class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );
}
