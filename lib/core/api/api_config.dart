import 'package:flutter/foundation.dart';

/// Endereço do servidor. No navegador, o próprio endereço em que o app
/// abriu (ele é servido em `/gestao` de cada domínio); fora dele, ou em
/// desenvolvimento local, o de produção na AWS. Para usar o servidor local:
/// `flutter run --dart-define=API_URL=http://localhost:8000`.
class ApiConfig {
  ApiConfig._();

  static const producao = 'https://api.xn--associaoconectabci-7sb3f.com.br';

  static const _definida = String.fromEnvironment('API_URL');

  static String get url {
    if (_definida.isNotEmpty) return _definida;
    if (kIsWeb && !_local(Uri.base.host)) return Uri.base.origin;
    return producao;
  }

  static bool _local(String host) =>
      host == 'localhost' || host == '127.0.0.1' || host.isEmpty;
}
