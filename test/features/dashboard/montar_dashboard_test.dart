import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_imobiliaria/features/crm/domain/entities/contato.dart';
import 'package:gestao_imobiliaria/features/crm/domain/entities/enums.dart';
import 'package:gestao_imobiliaria/features/crm/domain/entities/evento.dart';
import 'package:gestao_imobiliaria/features/crm/domain/entities/imovel.dart';
import 'package:gestao_imobiliaria/features/dashboard/domain/entities/dashboard.dart';
import 'package:gestao_imobiliaria/features/dashboard/domain/services/montar_dashboard.dart';
import 'package:gestao_imobiliaria/features/financeiro/domain/entities/financeiro_enums.dart';
import 'package:gestao_imobiliaria/features/financeiro/domain/entities/lancamento.dart';
import 'package:gestao_imobiliaria/features/locacao/domain/entities/cobranca.dart';
import 'package:gestao_imobiliaria/features/locacao/domain/entities/contrato_locacao.dart';
import 'package:gestao_imobiliaria/features/locacao/domain/entities/locacao_enums.dart';
import 'package:gestao_imobiliaria/features/temporada/domain/entities/reserva.dart';
import 'package:gestao_imobiliaria/features/vendas/domain/entities/parcela.dart';
import 'package:gestao_imobiliaria/features/vendas/domain/entities/venda.dart';
import 'package:gestao_imobiliaria/features/vendas/domain/entities/venda_enums.dart';

final agora = DateTime(2026, 10, 15, 12);

DadosDashboard _dados() {
  final dono = Contato(
    id: 'dono',
    nome: 'Roberto',
    criadoEm: DateTime(2026, 8, 1),
    papeis: {PapelContato.proprietario},
    etapa: EtapaFunil.fechado,
  );
  final lead = Contato(
    id: 'lead',
    nome: 'Ana Souza',
    criadoEm: DateTime(2026, 10, 14, 9),
    etapa: EtapaFunil.visita,
  );
  final inquilino = Contato(
    id: 'inq',
    nome: 'Juliana',
    criadoEm: DateTime(2026, 9, 1),
    papeis: {PapelContato.locatario},
    etapa: EtapaFunil.negociacao,
  );
  final contrato = ContratoLocacao(
    id: 'c1',
    numero: 'LOC-0001',
    imovelId: 'i1',
    locatarioId: 'inq',
    beneficiarios: const [Beneficiario(contatoId: 'dono', percentual: 100)],
    dataInicio: DateTime(2026, 9, 1),
    valorAluguel: 3000,
    prazoMeses: 2, // termina em 31/10: vence nos próximos 60 dias
  );
  return DadosDashboard(
    imoveis: [
      Imovel(
        id: 'i1',
        codigo: 'IM-0001',
        titulo: 'Apartamento Icaraí',
        finalidades: {Finalidade.locacao},
        valorLocacao: 3000,
        quartos: 2,
        areaUtil: 70,
        criadoEm: DateTime(2026, 9, 1),
      ),
      Imovel(
        id: 'i2',
        codigo: 'IM-0002',
        titulo: 'Casa Recreio',
        tipo: TipoImovel.casa,
        valorVenda: 900000,
        criadoEm: DateTime(2026, 10, 10),
      ),
    ],
    contatos: [dono, lead, inquilino],
    eventos: [
      Evento(
        id: 'e1',
        titulo: 'Visita Casa Recreio',
        criadoEm: DateTime(2026, 10, 1),
        tipo: TipoEvento.visita,
        dataHora: DateTime(2026, 10, 16, 10),
        contatoId: 'lead',
      ),
      Evento(
        id: 'passado',
        titulo: 'Ligação',
        criadoEm: DateTime(2026, 10, 1),
        dataHora: DateTime(2026, 10, 1, 10),
      ),
    ],
    vendas: [
      Venda(
        id: 'v1',
        numero: 'VEN-0001',
        imovelId: 'i2',
        compradores: const ['lead'],
        vendedores: const [Participacao(contatoId: 'dono', percentual: 100)],
        dataVenda: DateTime(2026, 10, 10),
        valorVenda: 900000,
      ),
    ],
    parcelas: [
      Parcela(
        id: 'p1',
        vendaId: 'v1',
        numero: 0,
        totalParcelas: 1,
        tipo: TipoParcela.entrada,
        vencimento: DateTime(2026, 10, 10),
        valor: 200000,
        amortizacao: 200000,
        juros: 0,
        saldoDevedor: 700000,
        status: StatusParcela.paga,
        dataPagamento: DateTime(2026, 10, 10),
        valorPago: 200000,
      ),
    ],
    contratos: [contrato],
    cobrancas: [
      Cobranca(
        id: 'set',
        contratoId: 'c1',
        competencia: DateTime(2026, 9),
        vencimento: DateTime(2026, 9, 10),
        itens: const [
          ItemCobranca(
            descricao: 'Aluguel',
            valor: 3000,
            tipo: TipoItemCobranca.aluguel,
          ),
        ],
        status: StatusCobranca.paga,
        dataPagamento: DateTime(2026, 9, 10),
        valorPago: 3000,
      ),
      Cobranca(
        id: 'out',
        contratoId: 'c1',
        competencia: DateTime(2026, 10),
        vencimento: DateTime(2026, 10, 10),
        itens: const [
          ItemCobranca(
            descricao: 'Aluguel',
            valor: 3000,
            tipo: TipoItemCobranca.aluguel,
          ),
        ],
      ),
    ],
    reservas: [
      Reserva(
        id: 'r1',
        imovelId: 'i1',
        hospedeId: 'lead',
        checkIn: DateTime(2026, 10, 18),
        checkOut: DateTime(2026, 10, 20),
        valorDiaria: 500,
      ),
    ],
    lancamentos: [
      Lancamento(
        id: 'l1',
        tipo: TipoLancamento.pagar,
        descricao: 'Internet',
        valor: 250,
        vencimento: DateTime(2026, 10, 5),
        status: StatusLancamento.baixado,
        dataBaixa: DateTime(2026, 10, 5),
        valorBaixa: 250,
      ),
    ],
  );
}

void main() {
  test('indicadores e contadores com dados reais', () {
    final r = montarDashboard(_dados(), PeriodoDesempenho.mes, agora);
    expect(r.imoveis.valor, 2);
    expect(r.imoveis.variacaoPercentual, 100); // 1 → 2
    expect(r.clientes.valor, 3);
    expect(r.vendasMes.valor, 1);
    expect(r.locacoesAtivas.valor, 1);

    final c = r.contadores;
    expect(c.contratosVencendo, 1);
    expect(c.boletosEmAtraso, 1); // outubro venceu dia 10 e está aberto
    expect(c.reservasProximas, 1);
    expect(c.repassesPendentes, 1); // setembro pago, ainda não repassado
    expect(c.novosLeads, 1);
    expect(c.visitasAgendadas, 1);
    expect(c.negociacoesAtivas, 1);
  });

  test('funil, compromissos, imóveis recentes e atividades', () {
    final r = montarDashboard(_dados(), PeriodoDesempenho.semana, agora);
    expect(r.conversao.leads, 3);
    expect(r.conversao.taxa, closeTo(33.3, 0.1)); // 1 fechado de 3

    expect(r.compromissos.single.titulo, 'Visita Casa Recreio');
    expect(r.compromissos.single.detalhe, 'Cliente: Ana Souza');

    expect(r.imoveisRecentes.first.titulo, 'Casa Recreio');
    expect(r.imoveisRecentes.first.casa, isTrue);
    expect(r.imoveisRecentes.last.preco, contains('/mês'));
    expect(r.imoveisRecentes.last.caracteristicas, '2 quartos • 70 m²');

    expect(r.atividades.first.titulo, 'Novo cliente cadastrado');
    expect(r.desempenho, hasLength(7));
    // A venda de 10/10 cai na última semana (09 a 15/10).
    expect(r.desempenho.map((p) => p.vendas).reduce((a, b) => a + b), 1);
  });

  test('financeiro do mês', () {
    final f = montarDashboard(
      _dados(),
      PeriodoDesempenho.mes,
      agora,
    ).financeiro;
    expect(f.receitas, 200000); // entrada da venda paga em outubro
    final itens = {for (final i in f.itens) i.rotulo: i.valor};
    expect(itens, {'Vendas': 200000, 'Aluguéis': 0, 'Despesas': 250});
    expect(f.evolucao.last, 200000);
    expect(f.variacaoPercentual, closeTo(6566.7, 0.1)); // set: 3.000
  });

  test('sem dados: tudo zerado, sem erro', () {
    final r = montarDashboard(
      const DadosDashboard(),
      PeriodoDesempenho.ano,
      agora,
    );
    expect(r.imoveis.valor, 0);
    expect(r.conversao.taxa, 0);
    expect(r.compromissos, isEmpty);
    expect(r.desempenho, hasLength(12));
    expect(r.financeiro.evolucao.length, greaterThanOrEqualTo(2));
  });
}
