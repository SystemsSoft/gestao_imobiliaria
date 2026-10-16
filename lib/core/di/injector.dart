import 'package:get_it/get_it.dart';

import '../api/api_client.dart';
import '../api/sessao_api.dart';
import '../api/status_conexao.dart';

import '../../features/auth/auth_injection.dart';
import '../../features/contratos/contratos_injection.dart';
import '../../features/crm/crm_injection.dart';
import '../../features/dashboard/dashboard_injection.dart';
import '../../features/equipe/equipe_injection.dart';
import '../../features/financeiro/financeiro_injection.dart';
import '../../features/fiscal/fiscal_injection.dart';
import '../../features/home/home_injection.dart';
import '../../features/locacao/locacao_injection.dart';
import '../../features/personalizacao/personalizacao_injection.dart';
import '../../features/manutencao/manutencao_injection.dart';
import '../../features/temporada/temporada_injection.dart';
import '../../features/vendas/vendas_injection.dart';

/// Localizador de serviços da aplicação.
final sl = GetIt.instance;

/// Registra as dependências de todas as features. Com [apiUrl], os módulos
/// já integrados (CRM) usam o servidor; sem ela, ficam em memória (testes).
Future<void> configurarDependencias({String? apiUrl}) async {
  await sl.reset();
  sl.registerLazySingleton(StatusConexao.new);
  if (apiUrl != null && apiUrl.isNotEmpty) {
    sl
      ..registerLazySingleton(SessaoApi.new)
      ..registerLazySingleton(() => ApiClient(apiUrl, sessao: sl()));
  }
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
  registrarPersonalizacao(sl);
}
