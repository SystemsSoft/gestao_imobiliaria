import '../../../../core/api/api_client.dart';
import '../../../../core/api/status_conexao.dart';
import '../../../../core/data/remote_collection.dart';
import '../../domain/entities/manutencao.dart';
import '../../domain/repositories/manutencao_repository.dart';
import '../models/manutencao_json.dart';

/// Pauta de manutenção no servidor (`/api/v1/manutencoes`), com cache local.
class ManutencaoApiRepository implements ManutencaoRepository {
  ManutencaoApiRepository(this._api, StatusConexao status)
    : _itens = RemoteCollection(
        idOf: (m) => m.id,
        status: status,
        carregar: () async => [
          for (final j in await _api.listarTudo('manutencoes'))
            manutencaoDeJson(j),
        ],
      );

  final ApiClient _api;
  final RemoteCollection<Manutencao> _itens;

  @override
  Stream<List<Manutencao>> observar() => _itens.watch();

  /// Lê do cache (já carregado pela tela que observa a pauta).
  @override
  Manutencao? porId(String id) => _itens.cache.byId(id);

  /// Grava a pauta com o diário completo.
  @override
  Future<void> salvar(Manutencao m) async {
    final json = await _api.put('manutencoes/${m.id}', manutencaoParaJson(m));
    _itens.cache.upsert(manutencaoDeJson(json as Map<String, dynamic>));
  }

  @override
  Future<void> remover(String id) async {
    await _api.delete('manutencoes/$id');
    _itens.cache.removeWhere((m) => m.id == id);
  }
}
