import '../../domain/entities/cobranca.dart';
import '../../domain/entities/contrato_locacao.dart';
import '../../domain/entities/despesa.dart';
import '../../domain/entities/modelo_contrato.dart';
import '../../domain/repositories/cobranca_repository.dart';
import '../../domain/repositories/contrato_locacao_repository.dart';
import '../../domain/repositories/despesa_repository.dart';
import '../../domain/repositories/modelo_contrato_repository.dart';
import '../../domain/repositories/repasse_repository.dart';
import '../datasources/locacao_memory_datasource.dart';

class ContratoLocacaoRepositoryImpl implements ContratoLocacaoRepository {
  const ContratoLocacaoRepositoryImpl(this._ds);
  final LocacaoMemoryDataSource _ds;

  @override
  Stream<List<ContratoLocacao>> observar() => _ds.contratos.watch();

  @override
  Future<List<ContratoLocacao>> listar() async => _ds.contratos.all;

  @override
  Future<ContratoLocacao?> obter(String id) async => _ds.contratos.byId(id);

  @override
  Future<void> salvar(ContratoLocacao contrato) async =>
      _ds.contratos.upsert(contrato);

  @override
  Future<void> remover(String id) async =>
      _ds.contratos.removeWhere((e) => e.id == id);

  @override
  Future<String> proximoNumero() async {
    _ds.seqContrato++;
    return 'LOC-${_ds.seqContrato.toString().padLeft(4, '0')}';
  }
}

class DespesaRepositoryImpl implements DespesaRepository {
  const DespesaRepositoryImpl(this._ds);
  final LocacaoMemoryDataSource _ds;

  @override
  Stream<List<Despesa>> observar() => _ds.despesas.watch();

  @override
  Future<List<Despesa>> listar() async => _ds.despesas.all;

  @override
  Future<void> salvar(Despesa despesa) async => _ds.despesas.upsert(despesa);

  @override
  Future<void> remover(String id) async =>
      _ds.despesas.removeWhere((e) => e.id == id);

  @override
  Future<void> removerDoContrato(String contratoId) async =>
      _ds.despesas.removeWhere((e) => e.contratoId == contratoId);
}

class CobrancaRepositoryImpl implements CobrancaRepository {
  const CobrancaRepositoryImpl(this._ds);
  final LocacaoMemoryDataSource _ds;

  @override
  Stream<List<Cobranca>> observar() => _ds.cobrancas.watch();

  @override
  Future<List<Cobranca>> listar() async => _ds.cobrancas.all;

  @override
  Future<void> salvar(Cobranca cobranca) async =>
      _ds.cobrancas.upsert(cobranca);

  @override
  Future<void> remover(String id) async =>
      _ds.cobrancas.removeWhere((e) => e.id == id);

  @override
  Future<void> removerDoContrato(String contratoId) async =>
      _ds.cobrancas.removeWhere((e) => e.contratoId == contratoId);
}

class ModeloContratoRepositoryImpl implements ModeloContratoRepository {
  const ModeloContratoRepositoryImpl(this._ds);
  final LocacaoMemoryDataSource _ds;

  @override
  Stream<List<ModeloContrato>> observar() => _ds.modelos.watch();

  @override
  Future<List<ModeloContrato>> listar() async => _ds.modelos.all;

  @override
  Future<void> salvar(ModeloContrato modelo) async =>
      _ds.modelos.upsert(modelo);

  @override
  Future<void> remover(String id) async =>
      _ds.modelos.removeWhere((e) => e.id == id);
}

class RepasseRepositoryImpl implements RepasseRepository {
  const RepasseRepositoryImpl(this._ds);
  final LocacaoMemoryDataSource _ds;

  @override
  Stream<Map<String, DateTime>> observarRealizados() => _ds.watchRepasses();

  @override
  Future<void> marcar(
    String cobrancaId,
    String contatoId,
    DateTime? data,
  ) async => _ds.marcarRepasse(chaveRepasse(cobrancaId, contatoId), data);
}
