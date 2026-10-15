import 'package:get_it/get_it.dart';

import '../../core/api/api_client.dart';
import 'data/repositories/auth_repository_api.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/usecases/entrar.dart';
import 'presentation/viewmodels/login_viewmodel.dart';

void registrarAuth(GetIt sl) {
  // Login no servidor quando há ApiClient; senão, local (testes).
  if (sl.isRegistered<ApiClient>()) {
    sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryApi(sl(), sl(), sl()),
    );
  } else {
    sl.registerLazySingleton<AuthRepository>(AuthRepositoryLocal.new);
  }
  sl
    ..registerFactory(() => Entrar(sl()))
    ..registerFactory(() => Sair(sl()))
    ..registerFactory(() => AlterarSenha(sl()))
    ..registerFactory(() => LoginViewModel(sl()));
}
