import 'dart:typed_data';

import '../../../../core/presentation/view_model.dart';
import '../../../financeiro/domain/entities/conta_bancaria.dart';
import '../../../financeiro/domain/usecases/financeiro_usecases.dart';
import '../../domain/entities/sicoob.dart';
import '../../domain/repositories/sicoob_repository.dart';

/// Tela de testes da integração Sicoob (Sandbox): configuração, boletos,
/// Pix, conta corrente e registro das chamadas.
class IntegracaoSicoobViewModel extends ViewModel {
  IntegracaoSicoobViewModel(
    this._repo,
    ObservarContasBancarias observarContas, {
    this.aoImportarExtrato,
    this.aoBaixarCobrancas,
  }) {
    observar(observarContas(), (l) => contasBancarias = l);
    recarregar();
  }

  final SicoobRepository _repo;

  /// Avisa o Financeiro para buscar o extrato de novo depois da importação.
  final void Function()? aoImportarExtrato;

  /// Avisa a Locação para buscar as cobranças de novo depois do retorno.
  final void Function()? aoBaixarCobrancas;

  ConfiguracaoSicoob? configuracao;
  List<ContaBancaria> contasBancarias = const [];
  List<ResultadoTesteSicoob> testes = const [];
  List<BoletoSicoob> boletos = const [];
  List<PixSicoob> pix = const [];
  List<PixRecebido> recebidos = const [];
  List<ChamadaSicoob> chamadas = const [];
  List<CobrancaAbertaSicoob> cobrancasAbertas = const [];
  SaldoSicoob? saldo;
  ExtratoSicoob? extrato;
  bool carregado = false;

  /// PDF do último boleto registrado (para abrir na hora).
  Uint8List? ultimoPdf;
  String? ultimaMensagem;

  bool get pronto =>
      configuracao != null &&
      configuracao!.tokenConfigurado &&
      configuracao!.clientId.isNotEmpty;

  Future<void> recarregar() async {
    await executar(() async {
      configuracao = await _repo.configuracao();
      boletos = await _repo.boletos();
      pix = await _repo.cobrancasPix();
      chamadas = await _repo.chamadas();
      cobrancasAbertas = await _repo.cobrancasAbertas();
    });
    carregado = true;
    notificar();
  }

  Future<void> _atualizarChamadas() async {
    try {
      chamadas = await _repo.chamadas();
    } on Exception {
      // O registro é só informativo.
    }
  }

  /// Executa uma ação que fala com o Sicoob e atualiza o registro mesmo se
  /// ela falhar (a falha também fica registrada).
  Future<bool> _comSicoob(Future<void> Function() acao) async {
    final ok = await executar(acao);
    await _atualizarChamadas();
    notificar();
    return ok;
  }

  Future<bool> salvarConfiguracao(ConfiguracaoSicoob c, {String? token}) =>
      executar(() async {
        configuracao = await _repo.salvarConfiguracao(c, token: token);
      });

  Future<bool> testar() => _comSicoob(() async {
    testes = await _repo.testar();
  });

  Future<RascunhoSicoob?> rascunho(String cobrancaId) async {
    RascunhoSicoob? r;
    await executar(() async => r = await _repo.rascunho(cobrancaId));
    return r;
  }

  Future<bool> registrarBoleto(NovoBoletoSicoob b) => _comSicoob(() async {
    final r = await _repo.registrarBoleto(b);
    ultimoPdf = r.pdf.isEmpty ? null : r.pdf;
    boletos = [r.boleto, ...boletos.where((x) => x.id != r.boleto.id)];
  });

  void _trocarBoleto(BoletoSicoob b) =>
      boletos = [for (final x in boletos) x.id == b.id ? b : x];

  Future<bool> consultarBoleto(BoletoSicoob b) =>
      _comSicoob(() async => _trocarBoleto(await _repo.consultarBoleto(b.id)));

  Future<Uint8List?> pdfBoleto(BoletoSicoob b) async {
    Uint8List? pdf;
    await _comSicoob(() async => pdf = await _repo.pdfBoleto(b.id));
    return pdf;
  }

  Future<bool> baixarBoleto(BoletoSicoob b) =>
      _comSicoob(() async => _trocarBoleto(await _repo.baixarBoleto(b.id)));

  /// Última cobrança Pix criada (mostrada com o QR code).
  PixSicoob? pixCriado;

  Future<bool> criarPix(NovoPixSicoob p) => _comSicoob(() async {
    pixCriado = await _repo.criarPix(p);
    pix = [pixCriado!, ...pix];
  });

  Future<bool> consultarPix(PixSicoob p) => _comSicoob(() async {
    final novo = await _repo.consultarPix(p.id);
    pix = [for (final x in pix) x.id == novo.id ? novo : x];
    pixCriado = novo;
  });

  Future<bool> buscarRecebidos(DateTime inicio, DateTime fim) =>
      _comSicoob(() async => recebidos = await _repo.pixRecebidos(inicio, fim));

  Future<bool> buscarSaldo() =>
      _comSicoob(() async => saldo = await _repo.saldo());

  Future<bool> buscarExtrato(int mes, int ano) =>
      _comSicoob(() async => extrato = await _repo.extrato(mes, ano));

  Future<bool> importarExtrato(int mes, int ano) => _comSicoob(() async {
    final r = await _repo.importarExtrato(mes, ano);
    ultimaMensagem =
        '${r.importadas} lançamento(s) levado(s) à Conciliação bancária'
        '${r.repetidas > 0 ? '; ${r.repetidas} já estava(m) lá' : ''}.';
    aoImportarExtrato?.call();
  });

  /// Lê o retorno; [aplicar] dá baixa nas cobranças pagas.
  Future<ResultadoRetornoSicoob?> processarRetorno(
    Uint8List arquivo, {
    required bool aplicar,
  }) async {
    ResultadoRetornoSicoob? r;
    final ok = await executar(
      () async => r = await _repo.processarRetorno(arquivo, aplicar: aplicar),
    );
    if (!ok) return null;
    if (aplicar && r!.baixas > 0) {
      boletos = await _repo.boletos();
      cobrancasAbertas = await _repo.cobrancasAbertas();
      aoBaixarCobrancas?.call();
      notificar();
    }
    return r;
  }

  Future<ChamadaSicoob?> detalheChamada(ChamadaSicoob c) async {
    ChamadaSicoob? d;
    await executar(() async => d = await _repo.chamada(c.id));
    return d;
  }

  Future<void> atualizarChamadas() async {
    await _atualizarChamadas();
    notificar();
  }
}
