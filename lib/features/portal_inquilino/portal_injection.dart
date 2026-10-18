import 'package:get_it/get_it.dart';

import '../../core/api/api_client.dart';
import '../locacao/domain/entities/contrato_locacao.dart';
import 'data/repositories/portal_repositories.dart';
import 'domain/repositories/portal_repository.dart';
import 'domain/usecases/portal_usecases.dart';
import 'presentation/viewmodels/portal_viewmodels.dart';

void registrarPortalInquilino(GetIt sl) {
  if (sl.isRegistered<ApiClient>()) {
    sl.registerLazySingleton<PortalInquilinoRepository>(
      () => PortalInquilinoApiRepository(sl()),
    );
  } else {
    sl.registerLazySingleton<PortalInquilinoRepository>(
      PortalInquilinoMemoryRepository.new,
    );
  }
  sl
    ..registerFactory(() => PublicarDocumentoContrato(sl(), sl()))
    ..registerFactory(() => EnviarComunicado(sl()))
    ..registerFactory(
      () => PortalInquilinoViewModel(sl(), sl(), sl(), sl(), sl()),
    )
    ..registerFactoryParam<PortalContratoViewModel, ContratoLocacao, void>(
      (contrato, _) =>
          PortalContratoViewModel(contrato, sl(), sl(), sl(), sl()),
    );
}
