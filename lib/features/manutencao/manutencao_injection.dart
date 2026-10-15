import 'package:get_it/get_it.dart';

import '../../core/api/api_client.dart';
import '../../core/api/status_conexao.dart';

import 'data/documentos/pdf_documentos_manutencao_gateway.dart';
import 'data/repositories/manutencao_api_repository.dart';
import 'data/repositories/manutencao_memory_repository.dart';
import 'domain/entities/manutencao.dart';
import 'domain/repositories/documentos_manutencao_gateway.dart';
import 'domain/repositories/manutencao_repository.dart';
import 'domain/usecases/manutencao_usecases.dart';
import 'presentation/viewmodels/manutencoes_viewmodel.dart';

void registrarManutencao(GetIt sl) {
  // Servidor quando há ApiClient registrado; senão, memória (testes).
  if (sl.isRegistered<ApiClient>()) {
    sl.registerLazySingleton<ManutencaoRepository>(
      () => ManutencaoApiRepository(sl(), sl<StatusConexao>()),
    );
  } else {
    sl.registerLazySingleton<ManutencaoRepository>(
      ManutencaoMemoryRepository.new,
    );
  }
  sl
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
