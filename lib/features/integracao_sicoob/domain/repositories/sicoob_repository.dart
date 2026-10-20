import 'dart:typed_data';

import '../entities/sicoob.dart';

abstract interface class SicoobRepository {
  Future<ConfiguracaoSicoob> configuracao();

  /// [token] vazio ou nulo mantém o token atual.
  Future<ConfiguracaoSicoob> salvarConfiguracao(
    ConfiguracaoSicoob c, {
    String? token,
  });
  Future<List<ResultadoTesteSicoob>> testar();

  Future<List<CobrancaAbertaSicoob>> cobrancasAbertas();
  Future<RascunhoSicoob> rascunho(String cobrancaId);

  Future<List<BoletoSicoob>> boletos();

  /// Registra no banco; devolve o boleto e o PDF (pode vir vazio).
  Future<({BoletoSicoob boleto, Uint8List pdf})> registrarBoleto(
    NovoBoletoSicoob b,
  );
  Future<BoletoSicoob> consultarBoleto(String id);
  Future<Uint8List> pdfBoleto(String id);
  Future<BoletoSicoob> baixarBoleto(String id);

  Future<List<PixSicoob>> cobrancasPix();
  Future<PixSicoob> criarPix(NovoPixSicoob p);
  Future<PixSicoob> consultarPix(String id);
  Future<List<PixRecebido>> pixRecebidos(DateTime inicio, DateTime fim);

  Future<SaldoSicoob> saldo();
  Future<ExtratoSicoob> extrato(int mes, int ano);

  /// Leva o extrato do mês para a Conciliação bancária.
  Future<({int importadas, int repetidas})> importarExtrato(int mes, int ano);

  /// Lê o arquivo de retorno (CNAB 240) baixado no Sicoob. Com
  /// [aplicar] falso só mostra o que será feito; verdadeiro dá baixa nas
  /// cobranças do aluguel pagas.
  Future<ResultadoRetornoSicoob> processarRetorno(
    Uint8List arquivo, {
    required bool aplicar,
  });

  Future<List<ChamadaSicoob>> chamadas();
  Future<ChamadaSicoob> chamada(String id);
}
