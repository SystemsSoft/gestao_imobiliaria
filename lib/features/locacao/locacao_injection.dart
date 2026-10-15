import 'package:get_it/get_it.dart';

import '../../core/api/api_client.dart';
import '../../core/api/status_conexao.dart';
import 'data/datasources/locacao_api_datasource.dart';

import 'data/datasources/locacao_memory_datasource.dart';
import 'data/documentos/pdf_documentos_locacao_gateway.dart';
import 'data/repositories/locacao_api_repositories.dart';
import 'data/repositories/locacao_repositories_impl.dart';
import 'domain/repositories/cobranca_repository.dart';
import 'domain/repositories/contrato_locacao_repository.dart';
import 'domain/repositories/despesa_repository.dart';
import 'domain/repositories/documentos_locacao_gateway.dart';
import 'domain/repositories/repasse_repository.dart';
import 'domain/usecases/cobranca_usecases.dart';
import 'domain/usecases/contrato_usecases.dart';
import 'domain/usecases/despesa_usecases.dart';
import 'domain/usecases/imposto_renda.dart';
import 'domain/usecases/imprimir_documentos.dart';
import 'domain/usecases/repasse_usecases.dart';
import 'presentation/viewmodels/cobrancas_viewmodel.dart';
import 'presentation/viewmodels/contrato_form_viewmodel.dart';
import 'presentation/viewmodels/contratos_viewmodel.dart';
import 'presentation/viewmodels/despesas_viewmodel.dart';
import 'presentation/viewmodels/imposto_renda_viewmodel.dart';
import 'presentation/viewmodels/repasses_viewmodel.dart';

void registrarLocacao(GetIt sl) {
  // Dados: servidor quando há ApiClient registrado; senão, memória (testes).
  if (sl.isRegistered<ApiClient>()) {
    sl
      ..registerLazySingleton(
        () => LocacaoApiDataSource(sl(), sl<StatusConexao>()),
      )
      ..registerLazySingleton<ContratoLocacaoRepository>(
        () => ContratoLocacaoApiRepository(sl()),
      )
      ..registerLazySingleton<DespesaRepository>(
        () => DespesaApiRepository(sl()),
      )
      ..registerLazySingleton<CobrancaRepository>(
        () => CobrancaApiRepository(sl()),
      )
      ..registerLazySingleton<RepasseRepository>(
        () => RepasseApiRepository(sl()),
      );
  } else {
    sl
      ..registerLazySingleton(LocacaoMemoryDataSource.new)
      ..registerLazySingleton<ContratoLocacaoRepository>(
        () => ContratoLocacaoRepositoryImpl(sl()),
      )
      ..registerLazySingleton<DespesaRepository>(
        () => DespesaRepositoryImpl(sl()),
      )
      ..registerLazySingleton<CobrancaRepository>(
        () => CobrancaRepositoryImpl(sl()),
      )
      ..registerLazySingleton<RepasseRepository>(
        () => RepasseRepositoryImpl(sl()),
      );
  }
  sl
    ..registerLazySingleton<DocumentosLocacaoGateway>(
      PdfDocumentosLocacaoGateway.new,
    )
    // Casos de uso
    ..registerFactory(() => ObservarContratos(sl()))
    ..registerFactory(() => SalvarContrato(sl()))
    ..registerFactory(() => RemoverContrato(sl(), sl(), sl()))
    ..registerFactory(() => ObservarDespesas(sl()))
    ..registerFactory(() => SalvarDespesa(sl()))
    ..registerFactory(() => RemoverDespesa(sl()))
    ..registerFactory(() => ObservarCobrancas(sl()))
    ..registerFactory(() => GerarCobrancasDoMes(sl(), sl(), sl()))
    ..registerFactory(CalcularEncargos.new)
    ..registerFactory(() => RegistrarPagamento(sl(), sl(), sl()))
    ..registerFactory(() => EstornarPagamento(sl()))
    ..registerFactory(() => CancelarCobranca(sl()))
    ..registerFactory(() => RemoverCobranca(sl()))
    ..registerFactory(CalcularRepasse.new)
    ..registerFactory(() => ObservarRepassesRealizados(sl()))
    ..registerFactory(() => MarcarRepasse(sl()))
    ..registerFactory(CalcularResumoIrAnual.new)
    ..registerFactory(() => ImprimirContrato(sl(), sl(), sl()))
    ..registerFactory(() => ImprimirBoleto(sl(), sl(), sl(), sl()))
    ..registerFactory(() => ImprimirRecibo(sl(), sl(), sl(), sl()))
    ..registerFactory(() => ImprimirDemonstrativoRepasse(sl()))
    ..registerFactory(() => ImprimirInformeRendimentos(sl()))
    // ViewModels
    ..registerFactory(
      () => ContratosViewModel(sl(), sl(), sl(), sl(), sl(), sl()),
    )
    ..registerFactory(() => ContratoFormViewModel(sl(), sl(), sl()))
    ..registerFactory(
      () => CobrancasViewModel(
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
    ..registerFactory(() => DespesasViewModel(sl(), sl(), sl(), sl(), sl()))
    ..registerFactory(
      () => RepassesViewModel(
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
      () => ImpostoRendaViewModel(sl(), sl(), sl(), sl(), sl(), sl()),
    );
}
