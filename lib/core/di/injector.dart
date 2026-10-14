import 'package:get_it/get_it.dart';

import '../../features/auth/auth_injection.dart';
import '../../features/contratos/contratos_injection.dart';
import '../../features/crm/crm_injection.dart';
import '../../features/dashboard/dashboard_injection.dart';
import '../../features/equipe/equipe_injection.dart';
import '../../features/financeiro/financeiro_injection.dart';
import '../../features/fiscal/fiscal_injection.dart';
import '../../features/home/home_injection.dart';
import '../../features/locacao/locacao_injection.dart';
import '../../features/manutencao/manutencao_injection.dart';
import '../../features/temporada/temporada_injection.dart';
import '../../features/vendas/vendas_injection.dart';

/// Localizador de serviços da aplicação.
final sl = GetIt.instance;

/// Registra as dependências de todas as features.
Future<void> configurarDependencias() async {
  await sl.reset();
  registrarAuth(sl);
  registrarHome(sl);
  registrarCrm(sl);
  registrarContratos(sl);
  registrarLocacao(sl);
  registrarVendas(sl);
  registrarManutencao(sl);
  registrarTemporada(sl);
  registrarFinanceiro(sl);
  registrarFiscal(sl);
  registrarEquipe(sl);
  registrarDashboard(sl);
}
