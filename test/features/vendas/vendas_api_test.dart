import 'package:flutter_test/flutter_test.dart';
import 'package:marceloimob_gestao/core/api/status_conexao.dart';
import 'package:marceloimob_gestao/core/utils/id.dart';
import 'package:marceloimob_gestao/features/vendas/data/repositories/vendas_api_repositories.dart';
import 'package:marceloimob_gestao/features/vendas/domain/entities/parcela.dart';
import 'package:marceloimob_gestao/features/vendas/domain/entities/venda.dart';
import 'package:marceloimob_gestao/features/vendas/domain/entities/venda_enums.dart';
import 'package:marceloimob_gestao/features/vendas/domain/usecases/parcela_usecases.dart';
import 'package:marceloimob_gestao/features/vendas/domain/usecases/venda_usecases.dart';

import '../../apoio/servidor_falso.dart';

Venda _venda() => Venda(
  id: gerarId(),
  numero: '',
  imovelId: 'imovel',
  compradores: const ['comprador'],
  vendedores: const [Participacao(contatoId: 'vendedor', percentual: 100)],
  dataVenda: DateTime(2026, 10, 1),
  valorVenda: 300000,
  valorEntrada: 60000,
  vencimentoEntrada: DateTime(2026, 10, 5),
  formaPagamento: FormaPagamento.financiamentoProprio,
  plano: PlanoFinanciamento(
    numeroParcelas: 12,
    taxaJurosMes: 1,
    sistema: SistemaAmortizacao.sac,
    primeiroVencimento: DateTime(2026, 11, 10),
  ),
  corretores: const [
    Participacao(percentual: 60),
    Participacao(contatoId: 'corretor', percentual: 40),
  ],
);

void main() {
  late ServidorFalso servidor;
  late VendasApiDataSource ds;
  late VendaApiRepository vendas;
  late ParcelaApiRepository parcelas;

  setUp(() {
    servidor = ServidorFalso();
    ds = VendasApiDataSource(servidor.cliente(), StatusConexao());
    vendas = VendaApiRepository(ds);
    parcelas = ParcelaApiRepository(ds);
  });

  test('salvar venda grava a venda, depois a tabela em lote', () async {
    final salva = await SalvarVenda(vendas, parcelas)(_venda());
    expect(salva.numero, 'VEN-0001');
    expect(salva.plano!.sistema, SistemaAmortizacao.sac);
    expect(salva.corretores.first.contatoId, isNull);

    final reqs = servidor.requisicoes.where((r) => !r.startsWith('GET'));
    expect(reqs.first, 'PUT /api/v1/vendas/${salva.id}');
    expect(reqs.last, 'PUT /api/v1/vendas/parcelas');
    final ps = await parcelas.daVenda(salva.id);
    expect(ps, hasLength(13)); // entrada + 12
    expect(ps.where((p) => p.tipo == TipoParcela.entrada).single.valor, 60000);
    expect(servidor.colecao('vendas/parcelas'), hasLength(13));
  });

  test('pagar todas as parcelas quita a venda no servidor', () async {
    final v = _venda();
    final curta = Venda(
      id: v.id,
      numero: '',
      imovelId: v.imovelId,
      compradores: v.compradores,
      vendedores: v.vendedores,
      dataVenda: v.dataVenda,
      valorVenda: 1000,
      formaPagamento: FormaPagamento.financiamentoProprio,
      plano: PlanoFinanciamento(
        numeroParcelas: 1,
        taxaJurosMes: 0,
        sistema: SistemaAmortizacao.semJuros,
        primeiroVencimento: DateTime(2026, 11, 10),
      ),
    );
    final salva = await SalvarVenda(vendas, parcelas)(curta);
    final p = (await parcelas.daVenda(salva.id)).single;
    await RegistrarPagamentoParcela(
      parcelas,
      vendas,
      const CalcularEncargosParcela(),
    )(p, DateTime(2026, 11, 10));
    expect(
      servidor.colecao('vendas/parcelas')[p.id]!['status'],
      StatusParcela.paga.name,
    );
    expect(servidor.colecao('vendas')[salva.id]!['status'], 'quitada');
  });

  test('remover venda apaga parcelas e venda', () async {
    final salva = await SalvarVenda(vendas, parcelas)(_venda());
    await RemoverVenda(vendas, parcelas)(salva.id);
    expect(servidor.colecao('vendas'), isEmpty);
    expect(servidor.colecao('vendas/parcelas'), isEmpty);
    expect(await parcelas.daVenda(salva.id), isEmpty);
  });

  test('comissão paga ida e volta', () async {
    final salva = await SalvarVenda(vendas, parcelas)(_venda());
    await MarcarComissaoPaga(vendas)(salva, 1, DateTime(2026, 10, 20));
    final lida = (await vendas.obter(salva.id))!;
    expect(lida.corretores[1].pagaEm, DateTime(2026, 10, 20));
    expect(lida.corretores[0].pagaEm, isNull);
  });

  test('parcela ida e volta mantém valores', () async {
    final salva = await SalvarVenda(vendas, parcelas)(_venda());
    final Parcela p = (await parcelas.daVenda(
      salva.id,
    )).firstWhere((p) => p.numero == 3);
    expect(p.totalParcelas, 12);
    expect(p.saldoDevedor, greaterThan(0));
    expect(p.vencimento, DateTime(2027, 1, 10));
  });
}
