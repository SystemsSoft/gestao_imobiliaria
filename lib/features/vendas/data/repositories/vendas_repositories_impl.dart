import '../../domain/entities/parcela.dart';
import '../../domain/entities/venda.dart';
import '../../domain/repositories/parcela_repository.dart';
import '../../domain/repositories/venda_repository.dart';
import '../datasources/vendas_memory_datasource.dart';

class VendaRepositoryImpl implements VendaRepository {
  const VendaRepositoryImpl(this._ds);
  final VendasMemoryDataSource _ds;

  @override
  Stream<List<Venda>> observar() => _ds.vendas.watch();

  @override
  Future<List<Venda>> listar() async => _ds.vendas.all;

  @override
  Future<Venda?> obter(String id) async => _ds.vendas.byId(id);

  @override
  Future<Venda> salvar(Venda venda) async {
    final salva = venda.numero.isEmpty
        ? venda.copyWith(
            numero: 'VEN-${(++_ds.seqVenda).toString().padLeft(4, '0')}',
          )
        : venda;
    _ds.vendas.upsert(salva);
    return salva;
  }

  @override
  Future<void> remover(String id) async =>
      _ds.vendas.removeWhere((e) => e.id == id);
}

class ParcelaRepositoryImpl implements ParcelaRepository {
  const ParcelaRepositoryImpl(this._ds);
  final VendasMemoryDataSource _ds;

  @override
  Stream<List<Parcela>> observar() => _ds.parcelas.watch();

  @override
  Future<List<Parcela>> listar() async => _ds.parcelas.all;

  @override
  Future<List<Parcela>> daVenda(String vendaId) async =>
      _ds.parcelas.all.where((p) => p.vendaId == vendaId).toList();

  @override
  Future<void> salvar(Parcela parcela) async => _ds.parcelas.upsert(parcela);

  @override
  Future<void> salvarTodas(List<Parcela> parcelas) async {
    for (final p in parcelas) {
      _ds.parcelas.upsert(p);
    }
  }

  @override
  Future<void> removerDaVenda(String vendaId) async =>
      _ds.parcelas.removeWhere((p) => p.vendaId == vendaId);
}
