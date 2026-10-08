import '../entities/dashboard.dart';
import '../repositories/dashboard_repository.dart';

class ObterDashboard {
  const ObterDashboard(this._repo);
  final DashboardRepository _repo;

  Future<DashboardResumo> call(PeriodoDesempenho periodo) =>
      _repo.obter(periodo);
}
