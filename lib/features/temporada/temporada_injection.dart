import 'package:get_it/get_it.dart';

import '../../core/api/api_client.dart';
import '../../core/api/status_conexao.dart';

import 'data/datasources/temporada_memory_datasource.dart';
import 'data/repositories/reserva_api_repository.dart';
import 'data/repositories/reserva_repository_impl.dart';
import 'domain/repositories/reserva_repository.dart';
import 'domain/services/calendario_temporada.dart';
import 'domain/usecases/reserva_usecases.dart';
import 'presentation/viewmodels/calendario_viewmodel.dart';
import 'presentation/viewmodels/reserva_form_viewmodel.dart';
import 'presentation/viewmodels/reservas_viewmodel.dart';

void registrarTemporada(GetIt sl) {
  // Servidor quando há ApiClient registrado; senão, memória (testes).
  if (sl.isRegistered<ApiClient>()) {
    sl.registerLazySingleton<ReservaRepository>(
      () => ReservaApiRepository(sl(), sl<StatusConexao>()),
    );
  } else {
    sl
      ..registerLazySingleton(TemporadaMemoryDataSource.new)
      ..registerLazySingleton<ReservaRepository>(
        () => ReservaRepositoryImpl(sl()),
      );
  }
  sl
    ..registerFactory(() => const CalendarioTemporada())
    ..registerFactory(() => const CalcularEstadia())
    ..registerFactory(() => ObservarReservas(sl()))
    ..registerFactory(() => ConsultarDisponibilidade(sl()))
    ..registerFactory(() => SalvarReserva(sl(), sl()))
    ..registerFactory(() => RemoverReserva(sl()))
    ..registerFactory(() => AlterarSituacaoReserva(sl(), sl()))
    ..registerFactory(() => QuitarReserva(sl()))
    ..registerFactory(() => CalendarioViewModel(sl(), sl(), sl(), sl()))
    ..registerFactory(
      () => ReservasViewModel(sl(), sl(), sl(), sl(), sl(), sl()),
    )
    ..registerFactory(() => ReservaFormViewModel(sl(), sl(), sl(), sl(), sl()));
}
