import '../../../../core/api/api_client.dart';
import '../../../../core/api/json.dart';
import '../../../../core/api/status_conexao.dart';
import '../../../../core/data/remote_collection.dart';
import '../../domain/entities/declarante_dimob.dart';
import '../../domain/repositories/declarante_repository.dart';

Map<String, Object?> declaranteParaJson(DeclaranteDimob d) => {
  'documento': d.documento,
  'nome': d.nome,
  'responsavelNome': d.responsavelNome,
  'responsavelCpf': d.responsavelCpf,
  'retificadora': d.retificadora,
  'numeroRecibo': d.numeroRecibo,
};

DeclaranteDimob declaranteDeJson(Map<String, dynamic> j) => DeclaranteDimob(
  documento: lerTexto(j['documento']),
  nome: lerTexto(j['nome']),
  responsavelNome: lerTexto(j['responsavelNome']),
  responsavelCpf: lerTexto(j['responsavelCpf']),
  retificadora: j['retificadora'] as bool? ?? false,
  numeroRecibo: lerTexto(j['numeroRecibo']),
);

/// Declarante da DIMOB no servidor (`/api/v1/fiscal/declarante`).
class DeclaranteApiRepository implements DeclaranteRepository {
  DeclaranteApiRepository(this._api, StatusConexao status)
    : _dados = RemoteCollection(
        idOf: (_) => 'declarante',
        status: status,
        carregar: () async => [
          declaranteDeJson(
            await _api.get('fiscal/declarante') as Map<String, dynamic>,
          ),
        ],
      );

  final ApiClient _api;
  final RemoteCollection<DeclaranteDimob> _dados;

  @override
  Stream<DeclaranteDimob> observar() =>
      _dados.watch().map((l) => l.firstOrNull ?? DeclaranteDimob());

  @override
  Future<DeclaranteDimob> obter() async =>
      (await _dados.all()).firstOrNull ?? DeclaranteDimob();

  @override
  Future<void> salvar(DeclaranteDimob declarante) async {
    final json = await _api.put(
      'fiscal/declarante',
      declaranteParaJson(declarante),
    );
    _dados.cache.upsert(declaranteDeJson(json as Map<String, dynamic>));
  }
}
