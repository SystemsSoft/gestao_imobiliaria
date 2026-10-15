import '../../../crm/domain/repositories/contato_repository.dart';
import '../../../crm/domain/repositories/evento_repository.dart';
import '../../../crm/domain/repositories/imovel_repository.dart';
import '../../../financeiro/domain/repositories/financeiro_repositories.dart';
import '../../../locacao/domain/repositories/cobranca_repository.dart';
import '../../../locacao/domain/repositories/contrato_locacao_repository.dart';
import '../../../locacao/domain/repositories/repasse_repository.dart';
import '../../../temporada/domain/repositories/reserva_repository.dart';
import '../../../vendas/domain/repositories/parcela_repository.dart';
import '../../../vendas/domain/repositories/venda_repository.dart';
import '../../domain/entities/dashboard.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../domain/services/montar_dashboard.dart';

/// Painel com os dados reais dos módulos (servidor ou memória).
class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl({
    required this.imoveis,
    required this.contatos,
    required this.eventos,
    required this.vendas,
    required this.parcelas,
    required this.contratos,
    required this.cobrancas,
    required this.repasses,
    required this.reservas,
    required this.lancamentos,
    DateTime Function()? agora,
  }) : _agora = agora ?? DateTime.now;

  final ImovelRepository imoveis;
  final ContatoRepository contatos;
  final EventoRepository eventos;
  final VendaRepository vendas;
  final ParcelaRepository parcelas;
  final ContratoLocacaoRepository contratos;
  final CobrancaRepository cobrancas;
  final RepasseRepository repasses;
  final ReservaRepository reservas;
  final LancamentoRepository lancamentos;
  final DateTime Function() _agora;

  @override
  Future<DashboardResumo> obter(PeriodoDesempenho periodo) async {
    // Dispara todas as leituras juntas (na primeira vez vêm do servidor).
    final fImoveis = imoveis.listar();
    final fContatos = contatos.listar();
    final fEventos = eventos.listar();
    final fVendas = vendas.listar();
    final fParcelas = parcelas.listar();
    final fContratos = contratos.listar();
    final fCobrancas = cobrancas.listar();
    final fRepasses = repasses.realizados();
    final fReservas = reservas.listar();
    final fLancamentos = lancamentos.listar();
    return montarDashboard(
      DadosDashboard(
        imoveis: await fImoveis,
        contatos: await fContatos,
        eventos: await fEventos,
        vendas: await fVendas,
        parcelas: await fParcelas,
        contratos: await fContratos,
        cobrancas: await fCobrancas,
        repasses: await fRepasses,
        reservas: await fReservas,
        lancamentos: await fLancamentos,
      ),
      periodo,
      _agora(),
    );
  }
}
