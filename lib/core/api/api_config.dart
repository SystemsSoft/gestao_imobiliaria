/// Endereço do servidor. Troque na execução com
/// `flutter run --dart-define=API_URL=https://...`.
class ApiConfig {
  ApiConfig._();

  static const url = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8000',
  );
}
