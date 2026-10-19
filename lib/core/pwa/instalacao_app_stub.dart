import 'instalacao_app.dart';

/// Fora do navegador (testes, apps nativos): nada a instalar.
class InstalacaoAppPlataforma implements InstalacaoApp {
  @override
  bool get android => false;

  @override
  bool get instalado => false;

  @override
  bool get mostrarOpcao => false;

  @override
  bool get disponivel => false;

  @override
  bool get enderecoOficial => false;

  @override
  Future<ResultadoInstalacao> instalar() async =>
      ResultadoInstalacao.indisponivel;
}
