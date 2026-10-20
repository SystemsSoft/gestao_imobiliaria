import 'package:get_it/get_it.dart';

import '../../core/api/api_client.dart';
import '../financeiro/data/repositories/financeiro_api_repositories.dart';
import '../locacao/data/datasources/locacao_api_datasource.dart';
import 'data/repositories/sicoob_repositories.dart';
import 'domain/repositories/sicoob_repository.dart';
import 'presentation/viewmodels/integracao_sicoob_viewmodel.dart';

void registrarIntegracaoSicoob(GetIt sl) {
  if (sl.isRegistered<ApiClient>()) {
    sl.registerLazySingleton<SicoobRepository>(() => SicoobApiRepository(sl()));
  } else {
    sl.registerLazySingleton<SicoobRepository>(SicoobMemoryRepository.new);
  }
  sl.registerFactory(
    () => IntegracaoSicoobViewModel(
      sl(),
      sl(),
      // O extrato importado aparece na Conciliação bancária na hora.
      aoImportarExtrato: () {
        if (sl.isRegistered<FinanceiroApiDataSource>()) {
          sl<FinanceiroApiDataSource>().extrato.recarregar();
        }
      },
      // As cobranças baixadas pelo retorno aparecem pagas na Locação.
      aoBaixarCobrancas: () {
        if (sl.isRegistered<LocacaoApiDataSource>()) {
          sl<LocacaoApiDataSource>().cobrancas.recarregar();
        }
      },
    ),
  );
}
