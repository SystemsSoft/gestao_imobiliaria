import 'package:get_it/get_it.dart';

import '../../core/api/api_client.dart';
import '../../core/api/sessao_api.dart';
import '../../core/api/status_conexao.dart';
import 'data/repositories/equipe_api_repositories.dart';

import 'data/datasources/equipe_memory_datasource.dart';
import 'data/repositories/equipe_repositories_impl.dart';
import 'domain/repositories/equipe_repositories.dart';
import 'domain/services/fila_service.dart';
import 'domain/usecases/chat_usecases.dart';
import 'domain/usecases/comissao_equipe_usecases.dart';
import 'domain/usecases/fila_usecases.dart';
import 'domain/usecases/permissao_usecases.dart';
import 'domain/usecases/usuario_usecases.dart';
import 'presentation/viewmodels/atividades_viewmodel.dart';
import 'presentation/viewmodels/chat_viewmodel.dart';
import 'presentation/viewmodels/comissoes_equipe_viewmodel.dart';
import 'presentation/viewmodels/fila_viewmodel.dart';
import 'presentation/viewmodels/permissoes_viewmodel.dart';
import 'presentation/viewmodels/usuarios_viewmodel.dart';

void registrarEquipe(GetIt sl) {
  // Dados: servidor quando há ApiClient registrado; senão, memória (testes).
  if (sl.isRegistered<ApiClient>()) {
    sl
      ..registerLazySingleton(
        () => EquipeApiDataSource(sl(), sl<SessaoApi>(), sl<StatusConexao>()),
      )
      ..registerLazySingleton<UsuarioRepository>(
        () => UsuarioApiRepository(sl()),
      )
      ..registerLazySingleton<SessaoRepository>(() => SessaoApiRepository(sl()))
      ..registerLazySingleton<ConfiguracaoSegurancaRepository>(
        () => ConfiguracaoSegurancaApiRepository(sl()),
      )
      ..registerLazySingleton<UsuarioAtualRepository>(
        () => UsuarioAtualApiRepository(sl()),
      )
      ..registerLazySingleton<AtividadeRepository>(
        () => AtividadeApiRepository(sl()),
      )
      ..registerLazySingleton<FilaRepository>(() => FilaApiRepository(sl()))
      ..registerLazySingleton<AtendimentoRepository>(
        () => AtendimentoApiRepository(sl()),
      )
      ..registerLazySingleton<ComissaoEquipeRepository>(
        () => ComissaoEquipeApiRepository(sl()),
      )
      ..registerLazySingleton<MensagemRepository>(
        () => MensagemApiRepository(sl()),
      );
  } else {
    sl
      ..registerLazySingleton(EquipeMemoryDataSource.new)
      ..registerLazySingleton<UsuarioRepository>(
        () => UsuarioRepositoryImpl(sl()),
      )
      ..registerLazySingleton<SessaoRepository>(
        () => SessaoRepositoryImpl(sl()),
      )
      ..registerLazySingleton<ConfiguracaoSegurancaRepository>(
        () => ConfiguracaoSegurancaRepositoryImpl(sl()),
      )
      ..registerLazySingleton<UsuarioAtualRepository>(
        () => UsuarioAtualRepositoryImpl(sl()),
      )
      ..registerLazySingleton<AtividadeRepository>(
        () => AtividadeRepositoryImpl(sl()),
      )
      ..registerLazySingleton<FilaRepository>(() => FilaRepositoryImpl(sl()))
      ..registerLazySingleton<AtendimentoRepository>(
        () => AtendimentoRepositoryImpl(sl()),
      )
      ..registerLazySingleton<ComissaoEquipeRepository>(
        () => ComissaoEquipeRepositoryImpl(sl()),
      )
      ..registerLazySingleton<MensagemRepository>(
        () => MensagemRepositoryImpl(sl()),
      );
  }
  sl
    // Casos de uso
    ..registerFactory(() => const FilaService())
    ..registerFactory(() => ObservarUsuarios(sl()))
    ..registerFactory(() => ObservarSessoes(sl()))
    ..registerFactory(() => ObservarUsuarioAtual(sl()))
    ..registerFactory(() => ObservarConfiguracaoSeguranca(sl()))
    ..registerFactory(() => ObservarAtividades(sl()))
    ..registerFactory(() => RegistrarAtividade(sl(), sl()))
    ..registerFactory(() => SalvarUsuario(sl(), sl()))
    ..registerFactory(() => AlternarAtivoUsuario(sl(), sl(), sl()))
    ..registerFactory(() => RemoverUsuario(sl(), sl(), sl(), sl()))
    ..registerFactory(() => DefinirUsuarioAtual(sl(), sl(), sl(), sl(), sl()))
    ..registerFactory(() => EncerrarSessao(sl(), sl(), sl()))
    ..registerFactory(() => SalvarConfiguracaoSeguranca(sl(), sl()))
    ..registerFactory(() => SalvarPermissoes(sl(), sl()))
    ..registerFactory(() => ObservarFila(sl()))
    ..registerFactory(() => ObservarAtendimentos(sl()))
    ..registerFactory(() => GerenciarFila(sl(), sl(), sl()))
    ..registerFactory(() => ChamarProximo(sl(), sl(), sl(), sl()))
    ..registerFactory(() => FinalizarAtendimento(sl(), sl(), sl()))
    ..registerFactory(() => ObservarRegrasComissao(sl()))
    ..registerFactory(() => ObservarLancamentosComissao(sl()))
    ..registerFactory(() => SalvarRegraComissao(sl(), sl()))
    ..registerFactory(() => SalvarLancamentoComissao(sl(), sl()))
    ..registerFactory(() => AlterarStatusComissao(sl(), sl()))
    ..registerFactory(() => RemoverLancamentoComissao(sl()))
    ..registerFactory(() => const ResumirComissoes())
    ..registerFactory(() => ObservarMensagens(sl()))
    ..registerFactory(() => EnviarMensagem(sl(), sl()))
    ..registerFactory(() => MarcarConversaLida(sl()))
    ..registerFactory(() => ApagarMensagem(sl()))
    // ViewModels
    ..registerFactory(
      () => UsuariosViewModel(
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
    ..registerFactory(() => PermissoesViewModel(sl(), sl()))
    ..registerFactory(() => AtividadesViewModel(sl(), sl()))
    ..registerFactory(
      () => FilaViewModel(sl(), sl(), sl(), sl(), sl(), sl(), sl(), sl(), sl()),
    )
    ..registerFactory(
      () => ComissoesEquipeViewModel(
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
      () => ChatViewModel(sl(), sl(), sl(), sl(), sl(), sl(), sl(), sl(), sl()),
    );
}
