import 'instalacao_app.dart';

/// Fora do navegador (testes, apps nativos): nada a instalar.
class InstalacaoAppPlataforma implements InstalacaoApp {
  @override
  Sistema get sistema => Sistema.outro;

  @override
  Navegador get navegador => Navegador.outro;

  @override
  bool get instalado => false;

  @override
  bool get disponivel => false;

  @override
  bool get enderecoOficial => false;

  @override
  Future<ResultadoInstalacao> instalar() async =>
      ResultadoInstalacao.indisponivel;
}
