import 'package:get_it/get_it.dart';

import '../../core/api/api_client.dart';
import '../../core/api/status_conexao.dart';

import 'data/datasources/modelos_memory_datasource.dart';
import 'data/documentos/pdf_contrato_gateway.dart';
import 'data/repositories/modelo_contrato_api_repository.dart';
import 'data/repositories/modelo_contrato_repository_impl.dart';
import 'data/repositories/modelos_prontos_repository_impl.dart';
import 'domain/entities/modelo_contrato.dart';
import 'domain/repositories/contrato_impressao_gateway.dart';
import 'domain/repositories/modelo_contrato_repository.dart';
import 'domain/repositories/modelos_prontos_repository.dart';
import 'domain/services/editor_modelo_service.dart';
import 'domain/usecases/modelo_usecases.dart';
import 'presentation/viewmodels/modelo_editor_viewmodel.dart';
import 'presentation/viewmodels/modelos_prontos_viewmodel.dart';
import 'presentation/viewmodels/modelos_viewmodel.dart';

void registrarContratos(GetIt sl) {
  // "Meus modelos": servidor quando há ApiClient; senão, memória (testes).
  // O catálogo de modelos prontos acompanha o app.
  if (sl.isRegistered<ApiClient>()) {
    sl.registerLazySingleton<ModeloContratoRepository>(
      () => ModeloContratoApiRepository(sl(), sl<StatusConexao>()),
    );
  } else {
    sl
      ..registerLazySingleton(ModelosMemoryDataSource.new)
      ..registerLazySingleton<ModeloContratoRepository>(
        () => ModeloContratoRepositoryImpl(sl()),
      );
  }
  sl
    ..registerLazySingleton<ModelosProntosRepository>(
      () => const ModelosProntosRepositoryImpl(),
    )
    ..registerLazySingleton<ContratoImpressaoGateway>(PdfContratoGateway.new)
    ..registerFactory(() => const EditorModeloService())
    ..registerFactory(() => ObservarModelos(sl()))
    ..registerFactory(() => SalvarModelo(sl()))
    ..registerFactory(() => RemoverModelo(sl()))
    ..registerFactory(() => DuplicarModelo(sl()))
    ..registerFactory(() => ListarModelosProntos(sl()))
    ..registerFactory(() => RestaurarModelo(sl()))
    ..registerFactory(PreencherModelo.new)
    ..registerFactory(() => ImprimirContratoDocumento(sl()))
    ..registerFactory(() => ImprimirExemploModelo(sl()))
    ..registerFactoryParam<ModelosViewModel, TipoModelo?, void>(
      (tipo, _) => ModelosViewModel(
        tipo,
        sl(),
        sl(),
        sl(),
        sl(),
        sl(),
        sl(),
        sl(),
        sl(),
      ),
    )
    ..registerFactory(() => ModelosProntosViewModel(sl(), sl()))
    ..registerFactory(() => ModeloEditorViewModel(sl(), sl(), sl(), sl()));
}
