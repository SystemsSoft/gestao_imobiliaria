import 'package:get_it/get_it.dart';

import '../../core/api/api_client.dart';
import '../../core/api/status_conexao.dart';

import 'data/datasources/financeiro_memory_datasource.dart';
import 'data/documentos/pdf_boleto_gateway.dart';
import 'data/repositories/documento_api_repository.dart';
import 'data/repositories/documento_memoria_repository.dart';
import 'data/repositories/financeiro_api_repositories.dart';
import 'data/repositories/financeiro_repositories_impl.dart';
import 'domain/repositories/boleto_impressao_gateway.dart';
import 'domain/repositories/documento_repository.dart';
import 'domain/repositories/financeiro_repositories.dart';
import 'domain/services/atualizacao_monetaria.dart';
import 'domain/services/conciliacao_service.dart';
import 'domain/usecases/boleto_usecases.dart';
import 'domain/usecases/documento_usecases.dart';
import 'domain/usecases/financeiro_usecases.dart';
import 'domain/usecases/lancamento_usecases.dart';
import 'presentation/viewmodels/conciliacao_viewmodel.dart';
import 'presentation/viewmodels/contas_viewmodel.dart';
import 'presentation/viewmodels/documentos_viewmodel.dart';
import 'presentation/viewmodels/encargos_viewmodel.dart';
import 'presentation/viewmodels/fluxo_caixa_viewmodel.dart';
import 'presentation/viewmodels/lancamento_form_viewmodel.dart';

void registrarFinanceiro(GetIt sl) {
  // Dados: servidor quando há ApiClient registrado; senão, memória (testes).
  if (sl.isRegistered<ApiClient>()) {
    sl
      ..registerLazySingleton(
        () => FinanceiroApiDataSource(sl(), sl<StatusConexao>()),
      )
      ..registerLazySingleton<LancamentoRepository>(
        () => LancamentoApiRepository(sl()),
      )
      ..registerLazySingleton<ContaBancariaRepository>(
        () => ContaBancariaApiRepository(sl()),
      )
      ..registerLazySingleton<ExtratoRepository>(
        () => ExtratoApiRepository(sl()),
      )
      ..registerLazySingleton<BoletoRepository>(() => BoletoApiRepository(sl()))
      ..registerLazySingleton<IndiceRepository>(() => IndiceApiRepository(sl()))
      ..registerLazySingleton<ConfiguracaoFinanceiraRepository>(
        () => ConfiguracaoFinanceiraApiRepository(sl()),
      )
      ..registerLazySingleton<DocumentoRepository>(
        () => DocumentoApiRepository(sl(), sl()),
      );
  } else {
    sl
      ..registerLazySingleton(FinanceiroMemoryDataSource.new)
      ..registerLazySingleton<LancamentoRepository>(
        () => LancamentoRepositoryImpl(sl()),
      )
      ..registerLazySingleton<ContaBancariaRepository>(
        () => ContaBancariaRepositoryImpl(sl()),
      )
      ..registerLazySingleton<ExtratoRepository>(
        () => ExtratoRepositoryImpl(sl()),
      )
      ..registerLazySingleton<BoletoRepository>(
        () => BoletoRepositoryImpl(sl()),
      )
      ..registerLazySingleton<IndiceRepository>(
        () => IndiceRepositoryImpl(sl()),
      )
      ..registerLazySingleton<ConfiguracaoFinanceiraRepository>(
        () => ConfiguracaoFinanceiraRepositoryImpl(sl()),
      )
      ..registerLazySingleton<DocumentoRepository>(
        () => DocumentoMemoriaRepository(sl()),
      );
  }
  sl
    ..registerLazySingleton<BoletoImpressaoGateway>(PdfBoletoGateway.new)
    // Serviços e casos de uso
    ..registerFactory(() => const AtualizacaoMonetaria())
    ..registerFactory(() => const ConciliacaoService())
    ..registerFactory(() => ObservarLancamentos(sl()))
    ..registerFactory(() => SalvarLancamento(sl()))
    ..registerFactory(() => RemoverLancamento(sl()))
    ..registerFactory(() => const CalcularEncargosLancamento())
    ..registerFactory(() => BaixarLancamento(sl(), sl(), sl()))
    ..registerFactory(() => EstornarBaixa(sl(), sl()))
    ..registerFactory(() => CancelarLancamento(sl()))
    ..registerFactory(() => ObservarContasBancarias(sl()))
    ..registerFactory(() => ListarContasBancarias(sl()))
    ..registerFactory(() => SalvarContaBancaria(sl()))
    ..registerFactory(() => RemoverContaBancaria(sl(), sl(), sl()))
    ..registerFactory(() => const CalcularFluxoCaixa())
    ..registerFactory(() => ObservarExtrato(sl()))
    ..registerFactory(() => SalvarLinhaExtrato(sl()))
    ..registerFactory(() => RemoverLinhaExtrato(sl()))
    ..registerFactory(() => ConciliarLinha(sl()))
    ..registerFactory(() => DesfazerConciliacao(sl()))
    ..registerFactory(() => ConciliarAutomaticamente(sl()))
    ..registerFactory(() => ObservarIndices(sl()))
    ..registerFactory(() => SalvarIndice(sl()))
    ..registerFactory(() => RemoverIndice(sl()))
    ..registerFactory(() => ObservarConfiguracaoFinanceira(sl()))
    ..registerFactory(() => ObterConfiguracaoFinanceira(sl()))
    ..registerFactory(() => SalvarConfiguracaoFinanceira(sl()))
    ..registerFactory(() => ObservarBoletos(sl()))
    ..registerFactory(() => EmitirBoleto(sl(), sl()))
    ..registerFactory(() => CancelarBoleto(sl()))
    ..registerFactory(() => ProcessarRetornoBancario(sl(), sl(), sl()))
    ..registerFactory(() => ImprimirBoletoBancario(sl(), sl(), sl(), sl()))
    ..registerFactory(() => ListarPastas(sl()))
    ..registerFactory(() => SalvarPasta(sl()))
    ..registerFactory(() => RemoverPasta(sl()))
    ..registerFactory(() => ListarDocumentos(sl()))
    ..registerFactory(() => EnviarDocumento(sl()))
    ..registerFactory(() => SalvarDocumento(sl()))
    ..registerFactory(() => SubstituirArquivoDocumento(sl()))
    ..registerFactory(() => RemoverDocumento(sl()))
    ..registerFactory(() => EnderecoDocumento(sl()))
    ..registerFactory(() => ListarDestinatarios(sl()))
    ..registerFactory(() => CompartilharPasta(sl()))
    // ViewModels
    ..registerFactory(
      () =>
          ContasViewModel(sl(), sl(), sl(), sl(), sl(), sl(), sl(), sl(), sl()),
    )
    ..registerFactory(() => LancamentoFormViewModel(sl(), sl(), sl()))
    ..registerFactory(() => FluxoCaixaViewModel(sl(), sl(), sl()))
    ..registerFactory(
      () => ConciliacaoViewModel(
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
      () => DocumentosViewModel(
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
      () => EncargosViewModel(sl(), sl(), sl(), sl(), sl(), sl()),
    );
}
