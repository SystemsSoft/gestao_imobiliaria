import 'package:get_it/get_it.dart';

import '../../core/api/api_client.dart';
import '../../core/api/status_conexao.dart';

import 'data/datasources/vendas_memory_datasource.dart';
import 'data/documentos/pdf_documentos_venda_gateway.dart';
import 'data/repositories/vendas_api_repositories.dart';
import 'data/repositories/vendas_repositories_impl.dart';
import 'domain/repositories/documentos_venda_gateway.dart';
import 'domain/repositories/parcela_repository.dart';
import 'domain/repositories/venda_repository.dart';
import 'domain/usecases/imprimir_documentos_venda.dart';
import 'domain/usecases/parcela_usecases.dart';
import 'domain/usecases/venda_usecases.dart';
import 'presentation/viewmodels/comissoes_viewmodel.dart';
import 'presentation/viewmodels/recebimentos_viewmodel.dart';
import 'presentation/viewmodels/venda_detalhe_viewmodel.dart';
import 'presentation/viewmodels/venda_form_viewmodel.dart';
import 'presentation/viewmodels/vendas_viewmodel.dart';

void registrarVendas(GetIt sl) {
  // Dados: servidor quando há ApiClient registrado; senão, memória (testes).
  if (sl.isRegistered<ApiClient>()) {
    sl
      ..registerLazySingleton(
        () => VendasApiDataSource(sl(), sl<StatusConexao>()),
      )
      ..registerLazySingleton<VendaRepository>(() => VendaApiRepository(sl()))
      ..registerLazySingleton<ParcelaRepository>(
        () => ParcelaApiRepository(sl()),
      );
  } else {
    sl
      ..registerLazySingleton(VendasMemoryDataSource.new)
      ..registerLazySingleton<VendaRepository>(() => VendaRepositoryImpl(sl()))
      ..registerLazySingleton<ParcelaRepository>(
        () => ParcelaRepositoryImpl(sl()),
      );
  }
  sl
    ..registerLazySingleton<DocumentosVendaGateway>(
      PdfDocumentosVendaGateway.new,
    )
    // Casos de uso
    ..registerFactory(() => ObservarVendas(sl()))
    ..registerFactory(() => ObservarParcelas(sl()))
    ..registerFactory(SimularFinanciamento.new)
    ..registerFactory(() => SalvarVenda(sl(), sl()))
    ..registerFactory(() => RemoverVenda(sl(), sl()))
    ..registerFactory(() => MarcarComissaoPaga(sl()))
    ..registerFactory(CalcularEncargosParcela.new)
    ..registerFactory(() => RegistrarPagamentoParcela(sl(), sl(), sl()))
    ..registerFactory(() => EstornarPagamentoParcela(sl(), sl()))
    ..registerFactory(() => ImprimirContratoVenda(sl(), sl(), sl()))
    ..registerFactory(() => ImprimirCarne(sl(), sl(), sl()))
    ..registerFactory(() => ImprimirPromissorias(sl(), sl(), sl()))
    ..registerFactory(() => ImprimirReciboComissao(sl(), sl(), sl()))
    // ViewModels
    ..registerFactory(
      () => VendasViewModel(sl(), sl(), sl(), sl(), sl(), sl(), sl()),
    )
    ..registerFactory(() => VendaFormViewModel(sl(), sl(), sl(), sl()))
    ..registerFactoryParam<VendaDetalheViewModel, String, void>(
      (id, _) => VendaDetalheViewModel(
        id,
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
        sl(),
      ),
    )
    ..registerFactory(
      () => RecebimentosViewModel(sl(), sl(), sl(), sl(), sl(), sl()),
    )
    ..registerFactory(() => ComissoesViewModel(sl(), sl(), sl(), sl()));
}
