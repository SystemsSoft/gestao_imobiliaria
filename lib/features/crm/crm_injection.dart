import 'package:get_it/get_it.dart';

import '../../core/api/api_client.dart';
import '../../core/api/status_conexao.dart';
import 'data/datasources/crm_api_datasource.dart';

import 'data/datasources/crm_memory_datasource.dart';
import 'data/repositories/contato_repository_impl.dart';
import 'data/repositories/crm_api_repositories.dart';
import 'data/repositories/evento_repository_impl.dart';
import 'data/repositories/imovel_repository_impl.dart';
import 'domain/repositories/contato_repository.dart';
import 'domain/repositories/evento_repository.dart';
import 'domain/repositories/imovel_repository.dart';
import 'domain/usecases/contato_usecases.dart';
import 'domain/usecases/evento_usecases.dart';
import 'domain/usecases/imovel_usecases.dart';
import 'domain/usecases/sugerir_negocios.dart';
import 'presentation/viewmodels/central_viewmodel.dart';
import 'presentation/viewmodels/contato_form_viewmodel.dart';
import 'presentation/viewmodels/contatos_viewmodel.dart';
import 'presentation/viewmodels/cruzamento_viewmodel.dart';
import 'presentation/viewmodels/evento_form_viewmodel.dart';
import 'presentation/viewmodels/imoveis_viewmodel.dart';
import 'presentation/viewmodels/imovel_form_viewmodel.dart';

void registrarCrm(GetIt sl) {
  // Dados: servidor quando há ApiClient registrado; senão, memória (testes).
  if (sl.isRegistered<ApiClient>()) {
    sl
      ..registerLazySingleton(() => CrmApiDataSource(sl(), sl<StatusConexao>()))
      ..registerLazySingleton<ImovelRepository>(() => ImovelApiRepository(sl()))
      ..registerLazySingleton<ContatoRepository>(
        () => ContatoApiRepository(sl()),
      )
      ..registerLazySingleton<EventoRepository>(
        () => EventoApiRepository(sl()),
      );
  } else {
    sl
      ..registerLazySingleton(CrmMemoryDataSource.new)
      ..registerLazySingleton<ImovelRepository>(
        () => ImovelRepositoryImpl(sl()),
      )
      ..registerLazySingleton<ContatoRepository>(
        () => ContatoRepositoryImpl(sl()),
      )
      ..registerLazySingleton<EventoRepository>(
        () => EventoRepositoryImpl(sl()),
      );
  }
  sl
    // Casos de uso
    ..registerFactory(() => ObservarImoveis(sl()))
    ..registerFactory(() => ListarImoveis(sl()))
    ..registerFactory(() => SalvarImovel(sl()))
    ..registerFactory(() => RemoverImovel(sl(), sl()))
    ..registerFactory(() => ObservarContatos(sl()))
    ..registerFactory(() => ListarContatos(sl()))
    ..registerFactory(() => SalvarContato(sl()))
    ..registerFactory(() => RemoverContato(sl(), sl()))
    ..registerFactory(() => ObservarEventos(sl()))
    ..registerFactory(() => SalvarEvento(sl()))
    ..registerFactory(() => RemoverEvento(sl()))
    ..registerFactory(() => AlternarConclusaoEvento(sl()))
    ..registerFactory(SugerirNegocios.new)
    // ViewModels
    ..registerFactory(() => ImoveisViewModel(sl(), sl()))
    ..registerFactory(() => ImovelFormViewModel(sl(), sl()))
    ..registerFactory(() => ContatosViewModel(sl(), sl()))
    ..registerFactory(() => ContatoFormViewModel(sl()))
    ..registerFactory(() => CruzamentoViewModel(sl(), sl(), sl()))
    ..registerFactory(
      () => CentralViewModel(sl(), sl(), sl(), sl(), sl(), sl()),
    )
    ..registerFactory(() => EventoFormViewModel(sl(), sl(), sl()));
}
