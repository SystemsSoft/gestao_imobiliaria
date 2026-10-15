import 'package:get_it/get_it.dart';

import 'data/repositories/dashboard_repository_impl.dart';
import 'domain/repositories/dashboard_repository.dart';
import 'domain/usecases/obter_dashboard.dart';
import 'presentation/viewmodels/dashboard_viewmodel.dart';

void registrarDashboard(GetIt sl) {
  sl
    // Calculado com os dados reais de CRM, Locação, Vendas, Temporada e
    // Financeiro.
    ..registerFactory<DashboardRepository>(
      () => DashboardRepositoryImpl(
        imoveis: sl(),
        contatos: sl(),
        eventos: sl(),
        vendas: sl(),
        parcelas: sl(),
        contratos: sl(),
        cobrancas: sl(),
        repasses: sl(),
        reservas: sl(),
        lancamentos: sl(),
      ),
    )
    ..registerFactory(() => ObterDashboard(sl()))
    ..registerFactory(() => DashboardViewModel(sl(), sl(), sl()));
}
