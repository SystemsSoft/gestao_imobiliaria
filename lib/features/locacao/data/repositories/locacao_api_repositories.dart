import '../../../../core/api/json.dart';
import '../../domain/entities/cobranca.dart';
import '../../domain/entities/contrato_locacao.dart';
import '../../domain/entities/despesa.dart';
import '../../domain/repositories/cobranca_repository.dart';
import '../../domain/repositories/contrato_locacao_repository.dart';
import '../../domain/repositories/despesa_repository.dart';
import '../../domain/repositories/repasse_repository.dart';
import '../datasources/locacao_api_datasource.dart';
import '../models/locacao_json.dart';

// Gravações usam PUT /{id}: o servidor cria quando o id ainda não existe.

class ContratoLocacaoApiRepository implements ContratoLocacaoRepository {
  const ContratoLocacaoApiRepository(this._ds);
  final LocacaoApiDataSource _ds;

  @override
  Stream<List<ContratoLocacao>> observar() => _ds.contratos.watch();

  @override
  Future<List<ContratoLocacao>> listar() => _ds.contratos.all();

  @override
  Future<ContratoLocacao?> obter(String id) => _ds.contratos.byId(id);

  @override
  Future<ContratoLocacao> salvar(ContratoLocacao contrato) async {
    final json = await _ds.api.put(
      'locacao/contratos/${contrato.id}',
      contratoParaJson(contrato),
    );
    final salvo = contratoDeJson(json as Map<String, dynamic>);
    _ds.contratos.cache.upsert(salvo);
    return salvo;
  }

  @override
  Future<void> remover(String id) async {
    await _ds.api.delete('locacao/contratos/$id');
    _ds.contratos.cache.removeWhere((e) => e.id == id);
  }
}

class DespesaApiRepository implements DespesaRepository {
  const DespesaApiRepository(this._ds);
  final LocacaoApiDataSource _ds;

  @override
  Stream<List<Despesa>> observar() => _ds.despesas.watch();

  @override
  Future<List<Despesa>> listar() => _ds.despesas.all();

  @override
  Future<void> salvar(Despesa despesa) async {
    final json = await _ds.api.put(
      'locacao/despesas/${despesa.id}',
      despesaParaJson(despesa),
    );
    _ds.despesas.cache.upsert(despesaDeJson(json as Map<String, dynamic>));
  }

  @override
  Future<void> remover(String id) async {
    await _ds.api.delete('locacao/despesas/$id');
    _ds.despesas.cache.removeWhere((e) => e.id == id);
  }

  /// O servidor já apagou junto com o contrato; só atualiza o cache.
  @override
  Future<void> removerDoContrato(String contratoId) async =>
      _ds.despesas.cache.removeWhere((e) => e.contratoId == contratoId);
}

class CobrancaApiRepository implements CobrancaRepository {
  const CobrancaApiRepository(this._ds);
  final LocacaoApiDataSource _ds;

  @override
  Stream<List<Cobranca>> observar() => _ds.cobrancas.watch();

  @override
  Future<List<Cobranca>> listar() => _ds.cobrancas.all();

  @override
  Future<void> salvar(Cobranca cobranca) async {
    final json = await _ds.api.put(
      'locacao/cobrancas/${cobranca.id}',
      cobrancaParaJson(cobranca),
    );
    _ds.cobrancas.cache.upsert(cobrancaDeJson(json as Map<String, dynamic>));
  }

  @override
  Future<void> remover(String id) async {
    await _ds.api.delete('locacao/cobrancas/$id');
    _ds.cobrancas.cache.removeWhere((e) => e.id == id);
    _ds.repasses.cache.removeWhere((r) => r.cobrancaId == id);
  }

  /// O servidor já apagou junto com o contrato; só atualiza o cache.
  @override
  Future<void> removerDoContrato(String contratoId) async {
    final ids = {
      for (final c in _ds.cobrancas.cache.all)
        if (c.contratoId == contratoId) c.id,
    };
    _ds.cobrancas.cache.removeWhere((c) => ids.contains(c.id));
    _ds.repasses.cache.removeWhere((r) => ids.contains(r.cobrancaId));
  }
}

class RepasseApiRepository implements RepasseRepository {
  const RepasseApiRepository(this._ds);
  final LocacaoApiDataSource _ds;

  @override
  Stream<Map<String, DateTime>> observarRealizados() =>
      _ds.repasses.watch().map(
        (l) => {
          for (final r in l) chaveRepasse(r.cobrancaId, r.contatoId): r.data,
        },
      );

  @override
  Future<void> marcar(
    String cobrancaId,
    String contatoId,
    DateTime? data,
  ) async {
    final caminho = 'locacao/repasses/$cobrancaId/$contatoId';
    final chave = chaveRepasse(cobrancaId, contatoId);
    if (data == null) {
      await _ds.api.delete(caminho);
      _ds.repasses.cache.removeWhere(
        (r) => chaveRepasse(r.cobrancaId, r.contatoId) == chave,
      );
      return;
    }
    final json = await _ds.api.put(caminho, {'data': escreverData(data)});
    _ds.repasses.cache.upsert(
      RepasseRealizado.deJson(json as Map<String, dynamic>),
    );
  }
}
