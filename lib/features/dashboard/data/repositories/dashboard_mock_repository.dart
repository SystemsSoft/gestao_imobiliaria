import 'dart:math';

import '../../domain/entities/dashboard.dart';
import '../../domain/repositories/dashboard_repository.dart';

/// Dados de demonstração do dashboard. Substituir por uma implementação que
/// consulte os módulos (ou o backend) quando a integração for feita.
class DashboardMockRepository implements DashboardRepository {
  DashboardMockRepository({DateTime Function()? agora})
    : _agora = agora ?? DateTime.now;

  final DateTime Function() _agora;

  @override
  Future<DashboardResumo> obter(PeriodoDesempenho periodo) async {
    final hoje = _agora();
    DateTime dia(int deltaDias, int h, int m) =>
        DateTime(hoje.year, hoje.month, hoje.day + deltaDias, h, m);

    return DashboardResumo(
      imoveis: const Indicador(valor: 248, variacaoPercentual: 12),
      clientes: const Indicador(valor: 186, variacaoPercentual: 8),
      vendasMes: const Indicador(valor: 12, variacaoPercentual: 33),
      locacoesAtivas: const Indicador(valor: 37, variacaoPercentual: 19),
      desempenho: _desempenho(periodo, hoje),
      conversao: const FunilConversao(
        taxa: 8.7,
        variacao: 2.1,
        leads: 92,
        visitas: 54,
        propostas: 28,
        negociacoes: 17,
      ),
      compromissos: [
        Compromisso(
          quando: dia(1, 10, 0),
          titulo: 'Visita - Apartamento Centro',
          detalhe: 'Cliente: Ana Souza',
          tipo: TipoCompromisso.visita,
        ),
        Compromisso(
          quando: dia(1, 14, 30),
          titulo: 'Reunião - Negociação',
          detalhe: 'Cliente: Carlos Mendes',
          tipo: TipoCompromisso.reuniao,
        ),
        Compromisso(
          quando: dia(2, 9, 0),
          titulo: 'Assinatura de contrato',
          detalhe: 'Imóvel: Barra da Tijuca',
          tipo: TipoCompromisso.assinatura,
        ),
        Compromisso(
          quando: dia(3, 16, 0),
          titulo: 'Visita - Casa Jardim América',
          detalhe: 'Cliente: Fernanda Lima',
          tipo: TipoCompromisso.visita,
        ),
      ],
      imoveisRecentes: [
        ImovelRecente(
          titulo: 'Apartamento - Barra da Tijuca',
          caracteristicas: '3 quartos • 2 suítes • 120 m²',
          finalidade: FinalidadeImovelRecente.venda,
          preco: r'R$ 1.250.000',
          cadastradoEm: hoje.subtract(const Duration(hours: 2)),
          casa: false,
        ),
        ImovelRecente(
          titulo: 'Casa - Recreio dos Bandeirantes',
          caracteristicas: '4 quartos • 3 suítes • 350 m²',
          finalidade: FinalidadeImovelRecente.venda,
          preco: r'R$ 2.800.000',
          cadastradoEm: hoje.subtract(const Duration(hours: 5)),
          casa: true,
        ),
        ImovelRecente(
          titulo: 'Apartamento - Ipanema',
          caracteristicas: '2 quartos • 1 suíte • 85 m²',
          finalidade: FinalidadeImovelRecente.locacao,
          preco: r'R$ 5.200/mês',
          cadastradoEm: hoje.subtract(const Duration(hours: 8)),
          casa: false,
        ),
        ImovelRecente(
          titulo: 'Sala Comercial - Centro',
          caracteristicas: '1 vaga • 45 m²',
          finalidade: FinalidadeImovelRecente.locacao,
          preco: r'R$ 2.800/mês',
          cadastradoEm: hoje.subtract(const Duration(days: 1)),
          casa: false,
        ),
      ],
      financeiro: const ResumoFinanceiroMes(
        receitas: 86420,
        variacaoPercentual: 18,
        evolucao: [
          8,
          12,
          11,
          19,
          24,
          22,
          31,
          36,
          34,
          45,
          52,
          49,
          58,
          66,
          63,
          74,
          86,
        ],
        itens: [
          ItemFinanceiro(
            rotulo: 'Vendas',
            valor: 52300,
            percentual: 60,
            despesa: false,
          ),
          ItemFinanceiro(
            rotulo: 'Aluguéis',
            valor: 28750,
            percentual: 33,
            despesa: false,
          ),
          ItemFinanceiro(
            rotulo: 'Despesas',
            valor: 12630,
            percentual: 7,
            despesa: true,
          ),
        ],
      ),
      atividades: [
        AtividadeRecente(
          titulo: 'Novo cliente cadastrado',
          detalhe: 'Cliente: Ana Souza',
          quando: dia(0, 13, 47),
          tipo: TipoAtividadeRecente.cliente,
        ),
        AtividadeRecente(
          titulo: 'Contrato de locação assinado',
          detalhe: 'Imóvel: Casa Jardim América',
          quando: dia(0, 11, 32),
          tipo: TipoAtividadeRecente.contrato,
        ),
        AtividadeRecente(
          titulo: 'Pagamento recebido',
          detalhe: 'Aluguel do mês',
          quando: dia(0, 10, 18),
          tipo: TipoAtividadeRecente.pagamento,
        ),
        AtividadeRecente(
          titulo: 'Imóvel atualizado',
          detalhe: 'Apartamento - Barra da Tijuca',
          quando: dia(0, 9, 5),
          tipo: TipoAtividadeRecente.imovel,
        ),
        AtividadeRecente(
          titulo: 'Proposta enviada',
          detalhe: 'Cliente: Roberto Almeida',
          quando: dia(0, 8, 45),
          tipo: TipoAtividadeRecente.proposta,
        ),
      ],
      contadores: const ContadoresPainel(
        contratosVencendo: 5,
        boletosEmAtraso: 3,
        reservasProximas: 4,
        repassesPendentes: 2,
        novosLeads: 14,
        visitasAgendadas: 6,
        negociacoesAtivas: 8,
        oportunidades: 5,
      ),
    );
  }

  /// Série fictícia, estável a cada abertura (semente fixa).
  List<PontoDesempenho> _desempenho(PeriodoDesempenho p, DateTime hoje) {
    final r = Random(7);
    String dd(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    const meses = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];
    switch (p) {
      case PeriodoDesempenho.ano:
        return [
          for (var i = 11; i >= 0; i--)
            () {
              final m = DateTime(hoje.year, hoje.month - i);
              return PontoDesempenho(
                rotulo: meses[m.month - 1],
                vendas: 8 + r.nextInt(10),
                locacoes: 20 + r.nextInt(18),
              );
            }(),
        ];
      case PeriodoDesempenho.semana:
      case PeriodoDesempenho.mes:
        final n = p == PeriodoDesempenho.semana ? 7 : 30;
        return [
          for (var i = n - 1; i >= 0; i--)
            PontoDesempenho(
              rotulo: dd(hoje.subtract(Duration(days: i))),
              vendas: 3 + r.nextInt(8) + (i % 7 == 0 ? 3 : 0),
              locacoes: 2 + r.nextInt(8),
            ),
        ];
    }
  }
}
