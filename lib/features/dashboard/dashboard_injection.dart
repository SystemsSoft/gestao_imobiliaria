import 'package:get_it/get_it.dart';

import 'data/repositories/dashboard_mock_repository.dart';
import 'domain/repositories/dashboard_repository.dart';
import 'domain/usecases/obter_dashboard.dart';
import 'presentation/viewmodels/dashboard_viewmodel.dart';

void registrarDashboard(GetIt sl) {
  sl
    // Dados de demonstração até a integração com os módulos/servidor.
    ..registerLazySingleton<DashboardRepository>(DashboardMockRepository.new)
    ..registerFactory(() => ObterDashboard(sl()))
    ..registerFactory(() => DashboardViewModel(sl(), sl(), sl()));
}
