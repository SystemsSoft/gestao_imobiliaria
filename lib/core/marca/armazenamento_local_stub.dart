import 'armazenamento_local.dart';

/// Fora do navegador (testes): só em memória.
class ArmazenamentoLocalPlataforma implements ArmazenamentoLocal {
  final _valores = <String, String>{};

  @override
  String? ler(String chave) => _valores[chave];

  @override
  void gravar(String chave, String valor) => _valores[chave] = valor;

  @override
  void remover(String chave) => _valores.remove(chave);
}
