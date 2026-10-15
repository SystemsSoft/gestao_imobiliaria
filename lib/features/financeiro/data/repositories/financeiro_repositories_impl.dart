import '../../domain/entities/boleto_bancario.dart';
import '../../domain/entities/conta_bancaria.dart';
import '../../domain/entities/indice_mensal.dart';
import '../../domain/entities/lancamento.dart';
import '../../domain/entities/linha_extrato.dart';
import '../../domain/repositories/financeiro_repositories.dart';
import '../datasources/financeiro_memory_datasource.dart';

class LancamentoRepositoryImpl implements LancamentoRepository {
  const LancamentoRepositoryImpl(this._ds);
  final FinanceiroMemoryDataSource _ds;

  @override
  Stream<List<Lancamento>> observar() => _ds.lancamentos.watch();

  @override
  Future<List<Lancamento>> listar() async => _ds.lancamentos.all;

  @override
  Future<Lancamento?> obter(String id) async => _ds.lancamentos.byId(id);

  @override
  Future<void> salvar(Lancamento l) async => _ds.lancamentos.upsert(l);

  @override
  Future<void> salvarTodos(List<Lancamento> lancamentos) async {
    for (final l in lancamentos) {
      _ds.lancamentos.upsert(l);
    }
  }

  @override
  Future<void> remover(String id) async =>
      _ds.lancamentos.removeWhere((e) => e.id == id);
}

class ContaBancariaRepositoryImpl implements ContaBancariaRepository {
  const ContaBancariaRepositoryImpl(this._ds);
  final FinanceiroMemoryDataSource _ds;

  @override
  Stream<List<ContaBancaria>> observar() => _ds.contas.watch();

  @override
  Future<List<ContaBancaria>> listar() async => _ds.contas.all;

  @override
  Future<ContaBancaria?> obter(String id) async => _ds.contas.byId(id);

  @override
  Future<void> salvar(ContaBancaria conta) async => _ds.contas.upsert(conta);

  @override
  Future<void> remover(String id) async =>
      _ds.contas.removeWhere((e) => e.id == id);
}

class ExtratoRepositoryImpl implements ExtratoRepository {
  const ExtratoRepositoryImpl(this._ds);
  final FinanceiroMemoryDataSource _ds;

  @override
  Stream<List<LinhaExtrato>> observar() => _ds.extrato.watch();

  @override
  Future<List<LinhaExtrato>> listar() async => _ds.extrato.all;

  @override
  Future<void> salvar(LinhaExtrato linha) async => _ds.extrato.upsert(linha);

  @override
  Future<void> remover(String id) async =>
      _ds.extrato.removeWhere((e) => e.id == id);
}

class BoletoRepositoryImpl implements BoletoRepository {
  const BoletoRepositoryImpl(this._ds);
  final FinanceiroMemoryDataSource _ds;

  @override
  Stream<List<BoletoBancario>> observar() => _ds.boletos.watch();

  @override
  Future<List<BoletoBancario>> listar() async => _ds.boletos.all;

  @override
  Future<BoletoBancario> salvar(BoletoBancario boleto) async {
    var salvo = boleto;
    if (boleto.nossoNumero.isEmpty) {
      final n = (_ds.sequenciaNossoNumero[boleto.contaId] ?? 0) + 1;
      _ds.sequenciaNossoNumero[boleto.contaId] = n;
      salvo = boleto.comNossoNumero(n.toString().padLeft(10, '0'));
    }
    _ds.boletos.upsert(salvo);
    return salvo;
  }
}

class IndiceRepositoryImpl implements IndiceRepository {
  const IndiceRepositoryImpl(this._ds);
  final FinanceiroMemoryDataSource _ds;

  @override
  Stream<List<IndiceMensal>> observar() => _ds.indices.watch();

  @override
  Future<List<IndiceMensal>> listar() async => _ds.indices.all;

  @override
  Future<void> salvar(IndiceMensal indice) async => _ds.indices.upsert(indice);

  @override
  Future<void> remover(String id) async =>
      _ds.indices.removeWhere((e) => e.id == id);
}

class ConfiguracaoFinanceiraRepositoryImpl
    implements ConfiguracaoFinanceiraRepository {
  const ConfiguracaoFinanceiraRepositoryImpl(this._ds);
  final FinanceiroMemoryDataSource _ds;

  @override
  Stream<ConfiguracaoFinanceira> observar() => _ds.configuracao.watch().map(
    (l) => l.firstOrNull ?? const ConfiguracaoFinanceira(),
  );

  @override
  Future<ConfiguracaoFinanceira> obter() async =>
      _ds.configuracao.all.firstOrNull ?? const ConfiguracaoFinanceira();

  @override
  Future<void> salvar(ConfiguracaoFinanceira configuracao) async =>
      _ds.configuracao.upsert(configuracao);
}
