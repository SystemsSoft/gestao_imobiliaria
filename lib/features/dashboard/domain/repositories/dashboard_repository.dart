import '../entities/dashboard.dart';

abstract interface class DashboardRepository {
  Future<DashboardResumo> obter(PeriodoDesempenho periodo);
}
