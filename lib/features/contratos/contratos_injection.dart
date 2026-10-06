import 'package:get_it/get_it.dart';

import 'data/datasources/modelos_memory_datasource.dart';
import 'data/documentos/pdf_contrato_gateway.dart';
import 'data/repositories/modelo_contrato_repository_impl.dart';
import 'domain/entities/modelo_contrato.dart';
import 'domain/repositories/contrato_impressao_gateway.dart';
import 'domain/repositories/modelo_contrato_repository.dart';
import 'domain/usecases/modelo_usecases.dart';
import 'presentation/viewmodels/modelos_viewmodel.dart';

void registrarContratos(GetIt sl) {
  sl
    ..registerLazySingleton(ModelosMemoryDataSource.new)
    ..registerLazySingleton<ModeloContratoRepository>(
      () => ModeloContratoRepositoryImpl(sl()),
    )
    ..registerLazySingleton<ContratoImpressaoGateway>(PdfContratoGateway.new)
    ..registerFactory(() => ObservarModelos(sl()))
    ..registerFactory(() => SalvarModelo(sl()))
    ..registerFactory(() => RemoverModelo(sl()))
    ..registerFactory(PreencherModelo.new)
    ..registerFactory(() => ImprimirContratoDocumento(sl()))
    ..registerFactoryParam<ModelosViewModel, TipoModelo, void>(
      (tipo, _) => ModelosViewModel(tipo, sl(), sl(), sl()),
    );
}
