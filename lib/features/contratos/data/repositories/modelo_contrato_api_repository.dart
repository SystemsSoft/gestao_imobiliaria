import '../../../../core/api/api_client.dart';
import '../../../../core/api/status_conexao.dart';
import '../../../../core/data/remote_collection.dart';
import '../../../../core/utils/id.dart';
import '../../domain/entities/modelo_contrato.dart';
import '../../domain/repositories/modelo_contrato_repository.dart';
import '../datasources/catalogo_modelos_prontos.dart';
import '../models/modelo_json.dart';

/// "Meus modelos" no servidor (`/api/v1/contratos/modelos`), com cache local.
class ModeloContratoApiRepository implements ModeloContratoRepository {
  ModeloContratoApiRepository(this._api, StatusConexao status) {
    _modelos = RemoteCollection(
      idOf: (m) => m.id,
      status: status,
      carregar: _carregar,
    );
  }

  final ApiClient _api;
  late final RemoteCollection<ModeloContrato> _modelos;

  /// A impressão de contratos de locação e de venda precisa de um modelo de
  /// cada tipo: se o servidor ainda não tem, grava uma cópia do modelo pronto.
  Future<List<ModeloContrato>> _carregar() async {
    final lista = [
      for (final j in await _api.get('contratos/modelos') as List)
        modeloDeJson(j as Map<String, dynamic>),
    ];
    for (final (tipo, prontoId) in [
      (TipoModelo.locacao, idProntoLocacaoResidencial),
      (TipoModelo.venda, idProntoCompraVenda),
    ]) {
      if (lista.any((m) => m.tipo == tipo)) continue;
      final pronto = catalogoModelosProntos.firstWhere((m) => m.id == prontoId);
      final padrao = pronto.comoRascunho().copyWith(
        id: gerarId(),
        nome: '${pronto.nome} (padrão)',
      );
      lista.add(await _gravar(padrao));
    }
    return lista;
  }

  Future<ModeloContrato> _gravar(ModeloContrato m) async {
    final json = await _api.put('contratos/modelos/${m.id}', modeloParaJson(m));
    return modeloDeJson(json as Map<String, dynamic>);
  }

  @override
  Stream<List<ModeloContrato>> observar() => _modelos.watch();

  @override
  Future<List<ModeloContrato>> listar() => _modelos.all();

  @override
  Future<void> salvar(ModeloContrato modelo) async =>
      _modelos.cache.upsert(await _gravar(modelo));

  @override
  Future<void> remover(String id) async {
    await _api.delete('contratos/modelos/$id');
    _modelos.cache.removeWhere((m) => m.id == id);
  }
}
