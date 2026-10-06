import 'package:get_it/get_it.dart';

import 'data/repositories/auth_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/usecases/entrar.dart';
import 'presentation/viewmodels/login_viewmodel.dart';

void registrarAuth(GetIt sl) {
  sl
    ..registerLazySingleton<AuthRepository>(AuthRepositoryLocal.new)
    ..registerFactory(() => Entrar(sl()))
    ..registerFactory(() => LoginViewModel(sl()));
}
