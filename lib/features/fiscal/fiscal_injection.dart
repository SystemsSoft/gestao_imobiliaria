import 'package:get_it/get_it.dart';

import '../../core/api/api_client.dart';
import '../../core/api/status_conexao.dart';

import 'data/datasources/fiscal_memory_datasource.dart';
import 'data/documentos/pdf_dimob_gateway.dart';
import 'data/repositories/declarante_api_repository.dart';
import 'data/repositories/declarante_repository_impl.dart';
import 'domain/repositories/declarante_repository.dart';
import 'domain/repositories/dimob_gateway.dart';
import 'domain/usecases/fiscal_usecases.dart';
import 'domain/usecases/gerar_dimob.dart';
import 'presentation/viewmodels/dimob_viewmodel.dart';
import 'presentation/viewmodels/ir_fiscal_viewmodel.dart';

void registrarFiscal(GetIt sl) {
  // Servidor quando há ApiClient registrado; senão, memória (testes).
  // DIMOB e IR são calculados com os dados de Locação, Vendas e CRM.
  if (sl.isRegistered<ApiClient>()) {
    sl.registerLazySingleton<DeclaranteRepository>(
      () => DeclaranteApiRepository(sl(), sl<StatusConexao>()),
    );
  } else {
    sl
      ..registerLazySingleton(FiscalMemoryDataSource.new)
      ..registerLazySingleton<DeclaranteRepository>(
        () => DeclaranteRepositoryImpl(sl()),
      );
  }
  sl
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
