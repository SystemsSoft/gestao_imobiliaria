import 'armazenamento_local_stub.dart'
    if (dart.library.js_interop) 'armazenamento_local_web.dart';

/// Guarda pequenos valores neste aparelho (no navegador, o localStorage).
abstract class ArmazenamentoLocal {
  factory ArmazenamentoLocal() = ArmazenamentoLocalPlataforma;

  String? ler(String chave);
  void gravar(String chave, String valor);
  void remover(String chave);
}
