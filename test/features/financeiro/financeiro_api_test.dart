import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_imobiliaria/core/api/status_conexao.dart';
import 'package:gestao_imobiliaria/core/utils/id.dart';
import 'package:gestao_imobiliaria/features/financeiro/data/repositories/financeiro_api_repositories.dart';
import 'package:gestao_imobiliaria/features/financeiro/domain/entities/conta_bancaria.dart';
import 'package:gestao_imobiliaria/features/financeiro/domain/entities/financeiro_enums.dart';
import 'package:gestao_imobiliaria/features/financeiro/domain/entities/indice_mensal.dart';
import 'package:gestao_imobiliaria/features/financeiro/domain/entities/lancamento.dart';
import 'package:gestao_imobiliaria/features/financeiro/domain/entities/linha_extrato.dart';
import 'package:gestao_imobiliaria/features/financeiro/domain/usecases/boleto_usecases.dart';
import 'package:gestao_imobiliaria/features/financeiro/domain/usecases/financeiro_usecases.dart';
import 'package:gestao_imobiliaria/features/financeiro/domain/usecases/lancamento_usecases.dart';

import '../../apoio/servidor_falso.dart';

Lancamento _lanc() => Lancamento(
  id: gerarId(),
  tipo: TipoLancamento.receber,
  descricao: 'Comissão de venda',
  categoria: 'Comissão de venda',
  valor: 5000,
  vencimento: DateTime(2026, 10, 10),
  multaPercentual: 2,
  jurosMesPercentual: 1,
  indice: IndiceMonetario.igpm,
);

void main() {
  late ServidorFalso servidor;
  late FinanceiroApiDataSource ds;
  late LancamentoApiRepository lancamentos;

  setUp(() {
    servidor = ServidorFalso();
    ds = FinanceiroApiDataSource(servidor.cliente(), StatusConexao());
    lancamentos = LancamentoApiRepository(ds);
  });

  test('repetição mensal vai em lote e volta igual', () async {
    await SalvarLancamento(lancamentos)(_lanc(), repetir: 3);
    expect(
      servidor.requisicoes.where((r) => r.startsWith('PUT')).single,
      'PUT /api/v1/financeiro/lancamentos',
    );
    final l = await lancamentos.listar();
    expect(l, hasLength(3));
    expect(l.map((e) => e.vencimento.month).toSet(), {10, 11, 12});
    expect(l.first.indice, IndiceMonetario.igpm);
    expect(l.first.parcelaTotal, 3);
  });

  test('baixa, conciliação e estorno', () async {
    final conta = ContaBancaria(id: gerarId(), nome: 'Itaú Empresa');
    await ContaBancariaApiRepository(ds).salvar(conta);
    final l = _lanc();
    await lancamentos.salvar(l);
    final baixado = await BaixarLancamento(
      lancamentos,
      IndiceApiRepository(ds),
      const CalcularEncargosLancamento(),
    )(l, DateTime(2026, 10, 10), meio: MeioPagamento.pix, contaId: conta.id);
    final lido = (await lancamentos.obter(l.id))!;
    expect(
      (lido.status, lido.meio, lido.contaBaixaId),
      (StatusLancamento.baixado, MeioPagamento.pix, conta.id),
    );

    final extrato = ExtratoApiRepository(ds);
    final linha = LinhaExtrato(
      id: gerarId(),
      contaId: conta.id,
      data: DateTime(2026, 10, 10),
      descricao: 'PIX recebido',
      valor: baixado.valorBaixa!,
    );
    await extrato.salvar(linha);
    await ConciliarLinha(extrato)(linha, baixado);
    expect(
      servidor.colecao('financeiro/extrato')[linha.id]!['lancamentoId'],
      l.id,
    );

    await DesfazerConciliacao(extrato)((await extrato.listar()).single);
    await EstornarBaixa(lancamentos, extrato)(lido);
    expect(
      servidor.colecao('financeiro/lancamentos')[l.id]!['status'],
      'aberto',
    );
  });

  test('emitir boleto recebe o nosso número do servidor', () async {
    final conta = ContaBancaria(id: gerarId(), nome: 'Bradesco');
    final contas = ContaBancariaApiRepository(ds);
    await contas.salvar(conta);
    final boletos = BoletoApiRepository(ds);
    final l1 = _lanc(), l2 = _lanc();
    await lancamentos.salvar(l1);
    await lancamentos.salvar(l2);
    final b1 = await EmitirBoleto(boletos, contas)(l1, conta.id);
    final b2 = await EmitirBoleto(boletos, contas)(l2, conta.id);
    expect((b1.nossoNumero, b2.nossoNumero), ('0000000001', '0000000002'));
    expect((await boletos.listar()).map((b) => b.nossoNumero), [
      '0000000001',
      '0000000002',
    ]);
  });

  test('índices e configuração', () async {
    final indices = IndiceApiRepository(ds);
    await SalvarIndice(indices)(
      const IndiceMensal(
        indice: IndiceMonetario.ipca,
        ano: 2026,
        mes: 9,
        percentual: 0.44,
      ),
    );
    expect((await indices.listar()).single.id, 'ipca-2026-9');
    await indices.remover('ipca-2026-9');
    expect(servidor.colecao('financeiro/indices'), isEmpty);

    final cfg = ConfiguracaoFinanceiraApiRepository(ds);
    expect((await cfg.obter()).multaPercentual, 2);
    await cfg.salvar(
      const ConfiguracaoFinanceira(
        multaPercentual: 10,
        indicePadrao: IndiceMonetario.ipca,
        linkBanco: 'https://banco.exemplo.com.br',
      ),
    );
    final lida = await cfg.obter();
    expect(
      (lida.multaPercentual, lida.indicePadrao, lida.linkBanco),
      (10.0, IndiceMonetario.ipca, 'https://banco.exemplo.com.br'),
    );
  });
}
