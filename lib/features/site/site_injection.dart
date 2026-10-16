import 'package:get_it/get_it.dart';

import '../../core/api/api_client.dart';
import '../../core/api/status_conexao.dart';
import '../crm/data/datasources/crm_api_datasource.dart';
import 'data/repositories/site_repositories.dart';
import 'domain/repositories/site_repository.dart';
import 'domain/usecases/site_usecases.dart';
import 'presentation/viewmodels/site_viewmodels.dart';

void registrarSite(GetIt sl) {
  if (sl.isRegistered<ApiClient>()) {
    sl.registerLazySingleton<SiteRepository>(
      () => SiteApiRepository(
        sl(),
        sl<StatusConexao>(),
        endereco: sl<ApiClient>()
            .endereco('')
            .toString()
            .replaceAll(RegExp(r'/$'), ''),
        // O servidor criou contato e tarefa: atualiza o CRM aberto no app.
        aoChegarLead: () {
          final crm = sl<CrmApiDataSource>();
          crm.contatos.recarregar();
          crm.eventos.recarregar();
        },
      ),
    );
  } else {
    sl.registerLazySingleton<SiteRepository>(SiteMemoryRepository.new);
  }
  sl
    ..registerFactory(() => ObterConfiguracaoSite(sl()))
    ..registerFactory(() => SalvarConfiguracaoSite(sl()))
    ..registerFactory(() => ObservarLeads(sl()))
    ..registerFactory(() => AtualizarLead(sl()))
    ..registerFactory(() => RemoverLead(sl()))
    ..registerFactory(() => PublicarImovelNoSite(sl()))
    ..registerFactory(() => LeadsViewModel(sl(), sl(), sl(), sl(), sl()))
    ..registerFactory(() => ImoveisNoSiteViewModel(sl(), sl()))
    ..registerFactory(
      () =>
          ConfiguracaoSiteViewModel(sl(), sl(), sl<SiteRepository>().endereco),
    );
}
