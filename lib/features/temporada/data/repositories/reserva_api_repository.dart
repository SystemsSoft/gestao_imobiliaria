import '../../../../core/api/api_client.dart';
import '../../../../core/api/status_conexao.dart';
import '../../../../core/data/remote_collection.dart';
import '../../domain/entities/reserva.dart';
import '../../domain/repositories/reserva_repository.dart';
import '../models/reserva_json.dart';

/// Reservas no servidor (`/api/v1/temporada/reservas`), com cache local.
class ReservaApiRepository implements ReservaRepository {
  ReservaApiRepository(this._api, StatusConexao status)
    : _reservas = RemoteCollection(
        idOf: (r) => r.id,
        status: status,
        carregar: () async => [
          for (final j in await _api.listarTudo('temporada/reservas'))
            reservaDeJson(j),
        ],
      );

  final ApiClient _api;
  final RemoteCollection<Reserva> _reservas;

  @override
  Stream<List<Reserva>> observar() => _reservas.watch();

  @override
  Future<List<Reserva>> listar() => _reservas.all();

  @override
  Future<Reserva?> obter(String id) => _reservas.byId(id);

  /// Se o servidor recusa (ex.: outro usuário reservou o período), recarrega
  /// as reservas para o calendário mostrar a situação atual.
  @override
  Future<Reserva> salvar(Reserva reserva) async {
    final Object? json;
    try {
      json = await _api.put(
        'temporada/reservas/${reserva.id}',
        reservaParaJson(reserva),
      );
    } on ApiException catch (e) {
      if (e.statusCode != null) await _reservas.recarregar();
      rethrow;
    }
    final salva = reservaDeJson(json as Map<String, dynamic>);
    _reservas.cache.upsert(salva);
    return salva;
  }

  @override
  Future<void> remover(String id) async {
    await _api.delete('temporada/reservas/$id');
    _reservas.cache.removeWhere((r) => r.id == id);
  }
}
