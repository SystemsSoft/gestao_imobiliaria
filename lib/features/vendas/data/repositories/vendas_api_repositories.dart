import '../../../../core/api/api_client.dart';
import '../../../../core/api/status_conexao.dart';
import '../../../../core/data/remote_collection.dart';
import '../../domain/entities/parcela.dart';
import '../../domain/entities/venda.dart';
import '../../domain/repositories/parcela_repository.dart';
import '../../domain/repositories/venda_repository.dart';
import '../models/vendas_json.dart';

/// Vendas no servidor (`/api/v1/vendas`), com cache local para as telas.
class VendasApiDataSource {
  VendasApiDataSource(this.api, StatusConexao status)
    : vendas = RemoteCollection(
        idOf: (e) => e.id,
        status: status,
        carregar: () async => [
          for (final j in await api.listarTudo('vendas')) vendaDeJson(j),
        ],
      ),
      parcelas = RemoteCollection(
        idOf: (e) => e.id,
        status: status,
        carregar: () async => [
          for (final j in await api.listarTudo('vendas/parcelas'))
            parcelaDeJson(j),
        ],
      );

  final ApiClient api;
  final RemoteCollection<Venda> vendas;
  final RemoteCollection<Parcela> parcelas;
}

class VendaApiRepository implements VendaRepository {
  const VendaApiRepository(this._ds);
  final VendasApiDataSource _ds;

  @override
  Stream<List<Venda>> observar() => _ds.vendas.watch();

  @override
  Future<List<Venda>> listar() => _ds.vendas.all();

  @override
  Future<Venda?> obter(String id) => _ds.vendas.byId(id);

  @override
  Future<Venda> salvar(Venda venda) async {
    final json = await _ds.api.put('vendas/${venda.id}', vendaParaJson(venda));
    final salva = vendaDeJson(json as Map<String, dynamic>);
    _ds.vendas.cache.upsert(salva);
    return salva;
  }

  @override
  Future<void> remover(String id) async {
    await _ds.api.delete('vendas/$id');
    _ds.vendas.cache.removeWhere((e) => e.id == id);
    _ds.parcelas.cache.removeWhere((p) => p.vendaId == id);
  }
}

class ParcelaApiRepository implements ParcelaRepository {
  const ParcelaApiRepository(this._ds);
  final VendasApiDataSource _ds;

  @override
  Stream<List<Parcela>> observar() => _ds.parcelas.watch();

  @override
  Future<List<Parcela>> listar() => _ds.parcelas.all();

  @override
  Future<List<Parcela>> daVenda(String vendaId) async => [
    for (final p in await _ds.parcelas.all())
      if (p.vendaId == vendaId) p,
  ];

  @override
  Future<void> salvar(Parcela parcela) async {
    final json = await _ds.api.put(
      'vendas/parcelas/${parcela.id}',
      parcelaParaJson(parcela),
    );
    _ds.parcelas.cache.upsert(parcelaDeJson(json as Map<String, dynamic>));
  }

  /// Uma só requisição para a tabela inteira do financiamento.
  @override
  Future<void> salvarTodas(List<Parcela> parcelas) async {
    if (parcelas.isEmpty) return;
    final json = await _ds.api.put('vendas/parcelas', [
      for (final p in parcelas) {'id': p.id, ...parcelaParaJson(p)},
    ]);
    for (final j in json as List) {
      _ds.parcelas.cache.upsert(parcelaDeJson(j as Map<String, dynamic>));
    }
  }

  @override
  Future<void> removerDaVenda(String vendaId) async {
    if (await _ds.vendas.byId(vendaId) != null) {
      await _ds.api.delete('vendas/$vendaId/parcelas');
    }
    _ds.parcelas.cache.removeWhere((p) => p.vendaId == vendaId);
  }
}
