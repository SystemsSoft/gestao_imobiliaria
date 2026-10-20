import 'dart:convert';
import 'dart:typed_data';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/json.dart';
import '../../../../core/utils/id.dart';
import '../../domain/entities/sicoob.dart';
import '../../domain/repositories/sicoob_repository.dart';

typedef _Json = Map<String, dynamic>;

double _d(Object? v) => lerDouble(v) ?? 0;

ConfiguracaoSicoob _config(_Json j) => ConfiguracaoSicoob(
  ambiente: lerTexto(j['ambiente']).isEmpty
      ? 'sandbox'
      : lerTexto(j['ambiente']),
  clientId: lerTexto(j['clientId']),
  numeroCliente: lerTexto(j['numeroCliente']),
  codigoModalidade: lerInt(j['codigoModalidade'], 1),
  numeroContaCorrente: lerTexto(j['numeroContaCorrente']),
  chavePix: lerTexto(j['chavePix']),
  contaBancariaId: j['contaBancariaId'] as String?,
  tokenConfigurado: j['tokenConfigurado'] as bool? ?? false,
  linkInternetBanking: lerTexto(j['linkInternetBanking']).isEmpty
      ? linkSicoobPadrao
      : lerTexto(j['linkInternetBanking']),
);

PagadorSicoob _pagador(_Json j) => PagadorSicoob(
  documento: lerTexto(j['documento']),
  nome: lerTexto(j['nome']),
  endereco: lerTexto(j['endereco']),
  bairro: lerTexto(j['bairro']),
  cidade: lerTexto(j['cidade']),
  cep: lerTexto(j['cep']),
  uf: lerTexto(j['uf']),
  email: lerTexto(j['email']),
);

_Json _pagadorJson(PagadorSicoob p) => {
  'documento': p.documento,
  'nome': p.nome,
  'endereco': p.endereco,
  'bairro': p.bairro,
  'cidade': p.cidade,
  'cep': p.cep,
  'uf': p.uf,
  'email': p.email,
};

BoletoSicoob _boleto(_Json j) => BoletoSicoob(
  id: j['id'] as String,
  nossoNumero: lerTexto(j['nossoNumero']),
  valor: _d(j['valor']),
  vencimento: lerData(j['vencimento']) ?? DateTime.now(),
  pagadorNome: lerTexto(j['pagadorNome']),
  linhaDigitavel: lerTexto(j['linhaDigitavel']),
  codigoBarras: lerTexto(j['codigoBarras']),
  situacao: lerTexto(j['situacao']),
  cobrancaId: j['cobrancaId'] as String?,
  criadoEm: lerData(j['criadoEm']) ?? DateTime.now(),
);

PixSicoob _pix(_Json j) => PixSicoob(
  id: j['id'] as String,
  txid: lerTexto(j['txid']),
  valor: _d(j['valor']),
  devedorNome: lerTexto(j['devedorNome']),
  descricao: lerTexto(j['descricao']),
  status: lerTexto(j['status']),
  copiaECola: lerTexto(j['copiaECola']),
  qrCodePng: lerTexto(j['qrCodePng']),
  criadoEm: lerData(j['criadoEm']) ?? DateTime.now(),
);

ChamadaSicoob _chamada(_Json j) => ChamadaSicoob(
  id: j['id'] as String,
  criadoEm: lerData(j['criadoEm']) ?? DateTime.now(),
  api: lerTexto(j['api']),
  operacao: lerTexto(j['operacao']),
  metodo: lerTexto(j['metodo']),
  caminho: lerTexto(j['caminho']),
  statusHttp: (j['statusHttp'] as num?)?.toInt(),
  duracaoMs: lerInt(j['duracaoMs']),
  sucesso: j['sucesso'] as bool? ?? false,
  erro: lerTexto(j['erro']),
  requisicao: lerTexto(j['requisicao']),
  resposta: lerTexto(j['resposta']),
);

/// Integração no servidor (`/api/v1/integracoes/sicoob`).
class SicoobApiRepository implements SicoobRepository {
  const SicoobApiRepository(this._api);
  final ApiClient _api;
  static const _base = 'integracoes/sicoob';

  List<_Json> _lista(Object? r) => (r as List).cast<_Json>();

  @override
  Future<ConfiguracaoSicoob> configuracao() async =>
      _config(await _api.get('$_base/configuracao') as _Json);

  @override
  Future<ConfiguracaoSicoob> salvarConfiguracao(
    ConfiguracaoSicoob c, {
    String? token,
  }) async => _config(
    await _api.put('$_base/configuracao', {
          'ambiente': c.ambiente,
          'clientId': c.clientId,
          'numeroCliente': c.numeroCliente,
          'codigoModalidade': c.codigoModalidade,
          'numeroContaCorrente': c.numeroContaCorrente,
          'chavePix': c.chavePix,
          'contaBancariaId': c.contaBancariaId,
          'linkInternetBanking': c.linkInternetBanking,
          'token': token,
        })
        as _Json,
  );

  @override
  Future<List<ResultadoTesteSicoob>> testar() async => [
    for (final j in _lista(await _api.post('$_base/testar', null)))
      ResultadoTesteSicoob(
        api: lerTexto(j['api']),
        nome: lerTexto(j['nome']),
        ok: j['ok'] as bool? ?? false,
        statusHttp: (j['statusHttp'] as num?)?.toInt(),
        mensagem: lerTexto(j['mensagem']),
      ),
  ];

  @override
  Future<List<CobrancaAbertaSicoob>> cobrancasAbertas() async => [
    for (final j in _lista(await _api.get('$_base/cobrancas-abertas')))
      CobrancaAbertaSicoob(
        id: j['id'] as String,
        descricao: lerTexto(j['descricao']),
        locatario: lerTexto(j['locatario']),
        valor: _d(j['valor']),
        vencimento: lerData(j['vencimento']) ?? DateTime.now(),
      ),
  ];

  @override
  Future<RascunhoSicoob> rascunho(String cobrancaId) async {
    final j =
        await _api.get('$_base/rascunho', query: {'cobrancaId': cobrancaId})
            as _Json;
    return RascunhoSicoob(
      valor: _d(j['valor']),
      vencimento: lerData(j['vencimento']) ?? DateTime.now(),
      pagador: _pagador(j['pagador'] as _Json),
      descricao: lerTexto(j['descricao']),
      multaPercentual: _d(j['multaPercentual']),
      jurosMesPercentual: _d(j['jurosMesPercentual']),
    );
  }

  @override
  Future<List<BoletoSicoob>> boletos() async => [
    for (final j in _lista(await _api.get('$_base/boletos'))) _boleto(j),
  ];

  @override
  Future<({BoletoSicoob boleto, Uint8List pdf})> registrarBoleto(
    NovoBoletoSicoob b,
  ) async {
    final j =
        await _api.post('$_base/boletos', {
              'valor': b.valor,
              'vencimento': escreverData(b.vencimento),
              'pagador': _pagadorJson(b.pagador),
              'multaPercentual': b.multaPercentual,
              'jurosMesPercentual': b.jurosMesPercentual,
              'mensagem': b.mensagem,
              'comPix': b.comPix,
              'cobrancaId': b.cobrancaId,
            })
            as _Json;
    final pdf = lerTexto(j['pdf']);
    return (
      boleto: _boleto(j['boleto'] as _Json),
      pdf: pdf.isEmpty ? Uint8List(0) : base64Decode(pdf),
    );
  }

  @override
  Future<BoletoSicoob> consultarBoleto(String id) async =>
      _boleto(await _api.post('$_base/boletos/$id/consultar', null) as _Json);

  @override
  Future<Uint8List> pdfBoleto(String id) async => base64Decode(
    lerTexto((await _api.get('$_base/boletos/$id/pdf') as _Json)['pdf']),
  );

  @override
  Future<BoletoSicoob> baixarBoleto(String id) async =>
      _boleto(await _api.post('$_base/boletos/$id/baixar', null) as _Json);

  @override
  Future<List<PixSicoob>> cobrancasPix() async => [
    for (final j in _lista(await _api.get('$_base/pix'))) _pix(j),
  ];

  @override
  Future<PixSicoob> criarPix(NovoPixSicoob p) async => _pix(
    await _api.post('$_base/pix', {
          'valor': p.valor,
          'devedorDocumento': p.devedorDocumento,
          'devedorNome': p.devedorNome,
          'descricao': p.descricao,
          'expiracaoHoras': p.expiracaoHoras,
          'cobrancaId': p.cobrancaId,
        })
        as _Json,
  );

  @override
  Future<PixSicoob> consultarPix(String id) async =>
      _pix(await _api.post('$_base/pix/$id/consultar', null) as _Json);

  @override
  Future<List<PixRecebido>> pixRecebidos(DateTime inicio, DateTime fim) async =>
      [
        for (final j in _lista(
          await _api.get(
            '$_base/pix-recebidos',
            query: {'inicio': escreverData(inicio), 'fim': escreverData(fim)},
          ),
        ))
          PixRecebido(
            endToEndId: lerTexto(j['endToEndId']),
            txid: lerTexto(j['txid']),
            valor: _d(j['valor']),
            horario: lerTexto(j['horario']),
            pagador: lerTexto(j['pagador']),
            info: lerTexto(j['info']),
          ),
      ];

  @override
  Future<SaldoSicoob> saldo() async {
    final j = await _api.get('$_base/saldo') as _Json;
    return SaldoSicoob(
      saldo: _d(j['saldo']),
      saldoLimite: _d(j['saldoLimite']),
      saldoBloqueado: _d(j['saldoBloqueado']),
    );
  }

  @override
  Future<ExtratoSicoob> extrato(int mes, int ano) async {
    final j =
        await _api.get('$_base/extrato', query: {'mes': mes, 'ano': ano})
            as _Json;
    return ExtratoSicoob(
      saldoAnterior: _d(j['saldoAnterior']),
      saldoAtual: _d(j['saldoAtual']),
      transacoes: [
        for (final t in (j['transacoes'] as List).cast<_Json>())
          TransacaoSicoob(
            tipo: lerTexto(t['tipo']),
            valor: _d(t['valor']),
            data: lerData(t['data']) ?? DateTime.now(),
            descricao: lerTexto(t['descricao']),
            documento: lerTexto(t['documento']),
            complemento: lerTexto(t['complemento']),
          ),
      ],
    );
  }

  @override
  Future<({int importadas, int repetidas})> importarExtrato(
    int mes,
    int ano,
  ) async {
    final j =
        await _api.post('$_base/extrato/importar', {'mes': mes, 'ano': ano})
            as _Json;
    return (
      importadas: lerInt(j['importadas']),
      repetidas: lerInt(j['repetidas']),
    );
  }

  @override
  Future<ResultadoRetornoSicoob> processarRetorno(
    Uint8List arquivo, {
    required bool aplicar,
  }) async {
    final j =
        await _api.post('$_base/retorno', {
              'conteudo': base64Encode(arquivo),
              'aplicar': aplicar,
            })
            as _Json;
    return ResultadoRetornoSicoob(
      aplicado: j['aplicado'] as bool? ?? false,
      baixas: lerInt(j['baixas']),
      itens: [
        for (final i in (j['itens'] as List).cast<_Json>())
          ItemRetornoSicoob(
            nossoNumero: lerTexto(i['nossoNumero']),
            valorPago: _d(i['valorPago']),
            dataCredito: lerData(i['dataCredito']),
            situacao: lerTexto(i['situacao']),
            mensagem: lerTexto(i['mensagem']),
            descricao: lerTexto(i['descricao']),
            locatario: lerTexto(i['locatario']),
          ),
      ],
    );
  }

  @override
  Future<List<ChamadaSicoob>> chamadas() async => [
    for (final j in _lista(await _api.get('$_base/chamadas'))) _chamada(j),
  ];

  @override
  Future<ChamadaSicoob> chamada(String id) async =>
      _chamada(await _api.get('$_base/chamadas/$id') as _Json);
}

/// Sem servidor (testes e demonstração): respostas simuladas do Sandbox.
class SicoobMemoryRepository implements SicoobRepository {
  var config = const ConfiguracaoSicoob();
  final boletosPorId = <String, BoletoSicoob>{};
  final pixPorId = <String, PixSicoob>{};
  final registro = <ChamadaSicoob>[];
  var abertas = <CobrancaAbertaSicoob>[];

  void _registrar(String operacao, String metodo, String caminho) =>
      registro.insert(
        0,
        ChamadaSicoob(
          id: gerarId(),
          criadoEm: DateTime.now(),
          api: caminho.split('/').first,
          operacao: operacao,
          metodo: metodo,
          caminho: caminho,
          statusHttp: 200,
          sucesso: true,
        ),
      );

  @override
  Future<ConfiguracaoSicoob> configuracao() async => config;

  @override
  Future<ConfiguracaoSicoob> salvarConfiguracao(
    ConfiguracaoSicoob c, {
    String? token,
  }) async => config = ConfiguracaoSicoob(
    ambiente: c.ambiente,
    clientId: c.clientId,
    numeroCliente: c.numeroCliente,
    codigoModalidade: c.codigoModalidade,
    numeroContaCorrente: c.numeroContaCorrente,
    chavePix: c.chavePix,
    contaBancariaId: c.contaBancariaId,
    tokenConfigurado: config.tokenConfigurado || (token ?? '').isNotEmpty,
  );

  @override
  Future<List<ResultadoTesteSicoob>> testar() async => [
    for (final (api, nome) in [
      ('cobranca', 'Cobrança Bancária'),
      ('pix', 'Pix Recebimentos'),
      ('conta', 'Conta Corrente'),
    ])
      ResultadoTesteSicoob(
        api: api,
        nome: nome,
        ok: config.tokenConfigurado,
        statusHttp: config.tokenConfigurado ? 200 : null,
        mensagem: config.tokenConfigurado
            ? 'Conectado e autorizado.'
            : 'Informe o client_id e o token do Sandbox.',
      ),
  ];

  @override
  Future<List<CobrancaAbertaSicoob>> cobrancasAbertas() async => abertas;

  @override
  Future<RascunhoSicoob> rascunho(String cobrancaId) async {
    final c = abertas.firstWhere((x) => x.id == cobrancaId);
    return RascunhoSicoob(
      valor: c.valor,
      vencimento: c.vencimento,
      pagador: PagadorSicoob(documento: '52998224725', nome: c.locatario),
      descricao: 'Aluguel ${c.descricao}',
      multaPercentual: 10,
      jurosMesPercentual: 1,
    );
  }

  @override
  Future<List<BoletoSicoob>> boletos() async => boletosPorId.values.toList();

  @override
  Future<({BoletoSicoob boleto, Uint8List pdf})> registrarBoleto(
    NovoBoletoSicoob b,
  ) async {
    _registrar('Registrar boleto', 'POST', 'cobranca-bancaria/v3/boletos');
    final boleto = BoletoSicoob(
      id: gerarId(),
      nossoNumero: '${100000 + boletosPorId.length}',
      valor: b.valor,
      vencimento: b.vencimento,
      pagadorNome: b.pagador.nome,
      linhaDigitavel: '75691.23456 00001.234567 8 99990000015000',
      situacao: 'Em Aberto',
      cobrancaId: b.cobrancaId,
      criadoEm: DateTime.now(),
    );
    boletosPorId[boleto.id] = boleto;
    return (boleto: boleto, pdf: Uint8List(0));
  }

  @override
  Future<BoletoSicoob> consultarBoleto(String id) async => boletosPorId[id]!;

  @override
  Future<Uint8List> pdfBoleto(String id) async => Uint8List(0);

  @override
  Future<BoletoSicoob> baixarBoleto(String id) async {
    final b = boletosPorId[id]!;
    return boletosPorId[id] = BoletoSicoob(
      id: b.id,
      nossoNumero: b.nossoNumero,
      valor: b.valor,
      vencimento: b.vencimento,
      pagadorNome: b.pagadorNome,
      linhaDigitavel: b.linhaDigitavel,
      situacao: 'Baixado',
      criadoEm: b.criadoEm,
    );
  }

  @override
  Future<List<PixSicoob>> cobrancasPix() async => pixPorId.values.toList();

  @override
  Future<PixSicoob> criarPix(NovoPixSicoob p) async {
    _registrar('Criar cobrança Pix', 'PUT', 'pix/api/v2/cob');
    final pix = PixSicoob(
      id: gerarId(),
      txid: 'TESTE${pixPorId.length}'.padRight(26, '0'),
      valor: p.valor,
      devedorNome: p.devedorNome,
      descricao: p.descricao,
      status: 'ATIVA',
      copiaECola: '00020126580014br.gov.bcb.pix0136teste',
      criadoEm: DateTime.now(),
    );
    return pixPorId[pix.id] = pix;
  }

  @override
  Future<PixSicoob> consultarPix(String id) async => pixPorId[id]!;

  @override
  Future<List<PixRecebido>> pixRecebidos(DateTime inicio, DateTime fim) async =>
      const [];

  @override
  Future<SaldoSicoob> saldo() async =>
      const SaldoSicoob(saldo: 4302.49, saldoLimite: 5000, saldoBloqueado: 0);

  @override
  Future<ExtratoSicoob> extrato(int mes, int ano) async => ExtratoSicoob(
    saldoAnterior: 2244.12,
    saldoAtual: 4302.49,
    transacoes: [
      TransacaoSicoob(
        tipo: 'CREDITO',
        valor: 3000,
        data: DateTime(ano, mes, 5),
        descricao: 'PIX RECEBIDO',
        documento: 'Pix',
      ),
    ],
  );

  @override
  Future<({int importadas, int repetidas})> importarExtrato(
    int mes,
    int ano,
  ) async => (importadas: 1, repetidas: 0);

  /// Prévia/baixa simulada: cada boleto em aberto vira um pagamento.
  @override
  Future<ResultadoRetornoSicoob> processarRetorno(
    Uint8List arquivo, {
    required bool aplicar,
  }) async {
    if (arquivo.isEmpty) throw const FormatException('O arquivo está vazio.');
    final itens = [
      for (final b in boletosPorId.values)
        if (b.cobrancaId != null && b.situacao != 'Liquidado')
          ItemRetornoSicoob(
            nossoNumero: b.nossoNumero,
            valorPago: b.valor,
            dataCredito: DateTime.now(),
            situacao: aplicar ? 'aplicada' : 'baixar',
            mensagem: aplicar ? 'Baixa feita.' : 'Será marcada como paga.',
            locatario: b.pagadorNome,
          ),
    ];
    if (aplicar) {
      for (final b in boletosPorId.values.toList()) {
        if (b.cobrancaId == null) continue;
        boletosPorId[b.id] = BoletoSicoob(
          id: b.id,
          nossoNumero: b.nossoNumero,
          valor: b.valor,
          vencimento: b.vencimento,
          pagadorNome: b.pagadorNome,
          linhaDigitavel: b.linhaDigitavel,
          situacao: 'Liquidado',
          cobrancaId: b.cobrancaId,
          criadoEm: b.criadoEm,
        );
      }
    }
    return ResultadoRetornoSicoob(
      aplicado: aplicar,
      baixas: itens.length,
      itens: itens,
    );
  }

  @override
  Future<List<ChamadaSicoob>> chamadas() async => registro;

  @override
  Future<ChamadaSicoob> chamada(String id) async =>
      registro.firstWhere((c) => c.id == id);
}
