import 'package:get_it/get_it.dart';

import 'data/datasources/fiscal_memory_datasource.dart';
import 'data/documentos/pdf_dimob_gateway.dart';
import 'data/repositories/declarante_repository_impl.dart';
import 'domain/repositories/declarante_repository.dart';
import 'domain/repositories/dimob_gateway.dart';
import 'domain/usecases/fiscal_usecases.dart';
import 'domain/usecases/gerar_dimob.dart';
import 'presentation/viewmodels/dimob_viewmodel.dart';
import 'presentation/viewmodels/ir_fiscal_viewmodel.dart';

void registrarFiscal(GetIt sl) {
  sl
    ..registerLazySingleton(FiscalMemoryDataSource.new)
    ..registerLazySingleton<DeclaranteRepository>(
      () => DeclaranteRepositoryImpl(sl()),
    )
    ..registerLazySingleton<DimobGateway>(PdfDimobGateway.new)
    ..registerFactory(() => ObservarDeclarante(sl()))
    ..registerFactory(() => SalvarDeclarante(sl()))
    ..registerFactory(
      () => GerarDimob(sl(), sl(), sl(), sl(), sl(), sl(), sl(), sl()),
    )
    ..registerFactory(() => ImprimirConferenciaDimob(sl()))
    ..registerFactory(() => const GerarCsvDimob())
    ..registerFactory(() => CalcularIrConsolidado(sl(), sl(), sl(), sl()))
    ..registerFactory(() => ImprimirInformeIr(sl()))
    ..registerFactory(
      () => DimobViewModel(
        sl(),
        sl(),
        sl(),
        sl(),
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
    ..registerFactory(
      () => IrFiscalViewModel(sl(), sl(), sl(), sl(), sl(), sl()),
    );
}
