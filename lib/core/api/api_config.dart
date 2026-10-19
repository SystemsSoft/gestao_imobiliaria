/// Endereço do servidor. Por padrão, o de produção na AWS (publicado com o
/// `deploy.sh` do servidor). Para usar o servidor local:
/// `flutter run --dart-define=API_URL=http://localhost:8000`.
class ApiConfig {
  ApiConfig._();

  static const producao = 'https://api.inovacloud.app';

  static const url = String.fromEnvironment('API_URL', defaultValue: producao);
}
