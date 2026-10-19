import 'package:get_it/get_it.dart';

import '../../core/api/api_client.dart';
import 'data/repositories/auditoria_repositories.dart';
import 'domain/entities/auditoria.dart';
import 'domain/repositories/auditoria_repository.dart';
import 'domain/usecases/auditoria_usecases.dart';
import 'presentation/viewmodels/auditoria_viewmodels.dart';

void registrarAuditoria(GetIt sl) {
  if (sl.isRegistered<ApiClient>()) {
    sl.registerLazySingleton<AuditoriaRepository>(
      () => AuditoriaApiRepository(sl()),
    );
  } else {
    sl.registerLazySingleton<AuditoriaRepository>(
      AuditoriaMemoryRepository.new,
    );
  }
  sl
    ..registerFactory(() => AnexarMidiaAuditoria(sl(), sl()))
    ..registerFactory(() => PendenciasViewModel(sl(), sl(), sl(), sl()))
    ..registerFactory(() => AuditoriasViewModel(sl(), sl(), sl(), sl(), sl()))
    ..registerFactoryParam<AuditoriaFormViewModel, Auditoria, void>(
      (a, _) => AuditoriaFormViewModel(a, sl(), sl(), sl(), sl(), sl(), sl()),
    )
    ..registerFactory(() => ProprietariosAuditoriaViewModel(sl(), sl()))
    ..registerFactory(() => ConfiguracaoAuditoriaViewModel(sl()));
}
