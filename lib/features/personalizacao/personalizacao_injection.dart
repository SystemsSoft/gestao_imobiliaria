import 'package:get_it/get_it.dart';

import '../../core/api/api_client.dart';
import 'data/repositories/empresa_repositories.dart';
import 'domain/repositories/empresa_repository.dart';
import 'domain/usecases/personalizacao_usecases.dart';
import 'presentation/viewmodels/personalizacao_viewmodel.dart';

void registrarPersonalizacao(GetIt sl) {
  if (sl.isRegistered<ApiClient>()) {
    sl.registerLazySingleton<EmpresaRepository>(
      () => EmpresaApiRepository(sl()),
    );
  } else {
    sl.registerLazySingleton<EmpresaRepository>(EmpresaMemoryRepository.new);
  }
  sl
    ..registerFactory(() => CarregarPersonalizacao(sl()))
    ..registerFactory(() => SalvarDadosEmpresa(sl()))
    ..registerFactory(() => SalvarLogo(sl()))
    ..registerFactory(() => RemoverLogo(sl()))
    ..registerFactory(() => PersonalizacaoViewModel(sl(), sl(), sl(), sl()));
}
