import '../../../../core/api/api_client.dart';
import '../../../../core/api/status_conexao.dart';
import '../../../../core/data/remote_collection.dart';
import '../../domain/entities/boleto_bancario.dart';
import '../../domain/entities/conta_bancaria.dart';
import '../../domain/entities/indice_mensal.dart';
import '../../domain/entities/lancamento.dart';
import '../../domain/entities/linha_extrato.dart';
import '../../domain/repositories/financeiro_repositories.dart';
import '../models/financeiro_json.dart';

/// Financeiro no servidor (`/api/v1/financeiro`), com cache local.
class FinanceiroApiDataSource {
  FinanceiroApiDataSource(this.api, StatusConexao status)
    : lancamentos = RemoteCollection(
        idOf: (e) => e.id,
        status: status,
        carregar: () async => [
          for (final j in await api.listarTudo('financeiro/lancamentos'))
            lancamentoDeJson(j),
        ],
      ),
      contas = RemoteCollection(
        idOf: (e) => e.id,
        status: status,
        carregar: () async => [
          for (final j in await api.get('financeiro/contas-bancarias') as List)
            contaBancariaDeJson(j as Map<String, dynamic>),
        ],
      ),
      extrato = RemoteCollection(
        idOf: (e) => e.id,
        status: status,
        carregar: () async => [
          for (final j in await api.listarTudo('financeiro/extrato'))
            linhaExtratoDeJson(j),
        ],
      ),
      boletos = RemoteCollection(
        idOf: (e) => e.id,
        status: status,
        carregar: () async => [
          for (final j in await api.listarTudo('financeiro/boletos'))
            boletoDeJson(j),
        ],
      ),
      indices = RemoteCollection(
        idOf: (e) => e.id,
        status: status,
        carregar: () async => [
          for (final j in await api.get('financeiro/indices') as List)
            indiceDeJson(j as Map<String, dynamic>),
        ],
      ),
      configuracao = RemoteCollection(
        idOf: (_) => 'config',
        status: status,
        carregar: () async => [
          configuracaoDeJson(
            await api.get('financeiro/configuracao') as Map<String, dynamic>,
          ),
        ],
      );

  final ApiClient api;
  final RemoteCollection<Lancamento> lancamentos;
  final RemoteCollection<ContaBancaria> contas;
  final RemoteCollection<LinhaExtrato> extrato;
  final RemoteCollection<BoletoBancario> boletos;
  final RemoteCollection<IndiceMensal> indices;
  final RemoteCollection<ConfiguracaoFinanceira> configuracao;
}

// Gravações usam PUT /{id}: o servidor cria quando o id ainda não existe.

class LancamentoApiRepository implements LancamentoRepository {
  const LancamentoApiRepository(this._ds);
  final FinanceiroApiDataSource _ds;

  @override
  Stream<List<Lancamento>> observar() => _ds.lancamentos.watch();

  @override
  Future<List<Lancamento>> listar() => _ds.lancamentos.all();

  @override
  Future<Lancamento?> obter(String id) => _ds.lancamentos.byId(id);

  @override
  Future<void> salvar(Lancamento l) async {
    final json = await _ds.api.put(
      'financeiro/lancamentos/${l.id}',
      lancamentoParaJson(l),
    );
    _ds.lancamentos.cache.upsert(
      lancamentoDeJson(json as Map<String, dynamic>),
    );
  }

  /// Uma só requisição para a repetição mensal inteira.
  @override
  Future<void> salvarTodos(List<Lancamento> lancamentos) async {
    if (lancamentos.isEmpty) return;
    final json = await _ds.api.put('financeiro/lancamentos', [
      for (final l in lancamentos) {'id': l.id, ...lancamentoParaJson(l)},
    ]);
    for (final j in json as List) {
      _ds.lancamentos.cache.upsert(lancamentoDeJson(j as Map<String, dynamic>));
    }
  }

  @override
  Future<void> remover(String id) async {
    await _ds.api.delete('financeiro/lancamentos/$id');
    _ds.lancamentos.cache.removeWhere((e) => e.id == id);
    _ds.boletos.cache.removeWhere((b) => b.lancamentoId == id);
  }
}

class ContaBancariaApiRepository implements ContaBancariaRepository {
  const ContaBancariaApiRepository(this._ds);
  final FinanceiroApiDataSource _ds;

  @override
  Stream<List<ContaBancaria>> observar() => _ds.contas.watch();

  @override
  Future<List<ContaBancaria>> listar() => _ds.contas.all();

  @override
  Future<ContaBancaria?> obter(String id) => _ds.contas.byId(id);

  @override
  Future<void> salvar(ContaBancaria c) async {
    final json = await _ds.api.put(
      'financeiro/contas-bancarias/${c.id}',
      contaBancariaParaJson(c),
    );
    _ds.contas.cache.upsert(contaBancariaDeJson(json as Map<String, dynamic>));
  }

  @override
  Future<void> remover(String id) async {
    await _ds.api.delete('financeiro/contas-bancarias/$id');
    _ds.contas.cache.removeWhere((e) => e.id == id);
  }
}

class ExtratoApiRepository implements ExtratoRepository {
  const ExtratoApiRepository(this._ds);
  final FinanceiroApiDataSource _ds;

  @override
  Stream<List<LinhaExtrato>> observar() => _ds.extrato.watch();

  @override
  Future<List<LinhaExtrato>> listar() => _ds.extrato.all();

  @override
  Future<void> salvar(LinhaExtrato linha) async {
    final json = await _ds.api.put(
      'financeiro/extrato/${linha.id}',
      linhaExtratoParaJson(linha),
    );
    _ds.extrato.cache.upsert(linhaExtratoDeJson(json as Map<String, dynamic>));
  }

  @override
  Future<void> remover(String id) async {
    await _ds.api.delete('financeiro/extrato/$id');
    _ds.extrato.cache.removeWhere((e) => e.id == id);
  }
}

class BoletoApiRepository implements BoletoRepository {
  const BoletoApiRepository(this._ds);
  final FinanceiroApiDataSource _ds;

  @override
  Stream<List<BoletoBancario>> observar() => _ds.boletos.watch();

  @override
  Future<List<BoletoBancario>> listar() => _ds.boletos.all();

  /// O servidor atribui o nosso número quando vem vazio.
  @override
  Future<BoletoBancario> salvar(BoletoBancario b) async {
    final json = await _ds.api.put(
      'financeiro/boletos/${b.id}',
      boletoParaJson(b),
    );
    final salvo = boletoDeJson(json as Map<String, dynamic>);
    _ds.boletos.cache.upsert(salvo);
    return salvo;
  }
}

class IndiceApiRepository implements IndiceRepository {
  const IndiceApiRepository(this._ds);
  final FinanceiroApiDataSource _ds;

  @override
  Stream<List<IndiceMensal>> observar() => _ds.indices.watch();

  @override
  Future<List<IndiceMensal>> listar() => _ds.indices.all();

  @override
  Future<void> salvar(IndiceMensal i) async {
    final json = await _ds.api.put('financeiro/indices', indiceParaJson(i));
    _ds.indices.cache.upsert(indiceDeJson(json as Map<String, dynamic>));
  }

  /// [id] no formato do app: "indice-ano-mes" (ex.: igpm-2026-3).
  @override
  Future<void> remover(String id) async {
    final i = _ds.indices.cache.byId(id);
    if (i == null) return;
    await _ds.api.delete(
      'financeiro/indices/${i.indice.name}/${i.ano}/${i.mes}',
    );
    _ds.indices.cache.removeWhere((e) => e.id == id);
  }
}

class ConfiguracaoFinanceiraApiRepository
    implements ConfiguracaoFinanceiraRepository {
  const ConfiguracaoFinanceiraApiRepository(this._ds);
  final FinanceiroApiDataSource _ds;

  @override
  Stream<ConfiguracaoFinanceira> observar() => _ds.configuracao.watch().map(
    (l) => l.firstOrNull ?? const ConfiguracaoFinanceira(),
  );

  @override
  Future<ConfiguracaoFinanceira> obter() async =>
      (await _ds.configuracao.all()).firstOrNull ??
      const ConfiguracaoFinanceira();

  @override
  Future<void> salvar(ConfiguracaoFinanceira c) async {
    final json = await _ds.api.put(
      'financeiro/configuracao',
      configuracaoParaJson(c),
    );
    _ds.configuracao.cache.upsert(
      configuracaoDeJson(json as Map<String, dynamic>),
    );
  }
}
