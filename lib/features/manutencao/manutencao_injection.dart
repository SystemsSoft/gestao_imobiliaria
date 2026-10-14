import 'package:get_it/get_it.dart';

import 'data/documentos/pdf_documentos_manutencao_gateway.dart';
import 'data/repositories/manutencao_memory_repository.dart';
import 'domain/entities/manutencao.dart';
import 'domain/repositories/documentos_manutencao_gateway.dart';
import 'domain/repositories/manutencao_repository.dart';
import 'domain/usecases/manutencao_usecases.dart';
import 'presentation/viewmodels/manutencoes_viewmodel.dart';

void registrarManutencao(GetIt sl) {
  sl
    ..registerLazySingleton<ManutencaoRepository>(
      ManutencaoMemoryRepository.new,
    )
    ..registerLazySingleton<DocumentosManutencaoGateway>(
      PdfDocumentosManutencaoGateway.new,
    )
    ..registerFactory(() => ObservarManutencoes(sl()))
    ..registerFactory(() => SalvarManutencao(sl()))
    ..registerFactory(() => RemoverManutencao(sl()))
    ..registerFactory(() => RegistrarDiario(sl()))
    ..registerFactory(() => RemoverRegistroDiario(sl()))
    ..registerFactory(() => AlterarStatusManutencao(sl()))
    ..registerFactory(() => ImprimirDiarioManutencao(sl(), sl(), sl(), sl()))
    ..registerFactoryParam<ManutencoesViewModel, ContextoManutencao, void>(
      (contexto, _) => ManutencoesViewModel(
        contexto,
        sl(),
        sl(),
        sl(),
        sl(),
        sl(),
        sl(),
        sl(),
        sl(),
      ),
    );
}
