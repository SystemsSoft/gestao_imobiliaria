import '../../../../core/api/api_client.dart';
import '../../../../core/api/json.dart';
import '../../../../core/utils/id.dart';
import '../../domain/entities/portal.dart';
import '../../domain/repositories/portal_repository.dart';

AcessoInquilino _acesso(Map<String, dynamic> j) => AcessoInquilino(
  contatoId: j['contatoId'] as String,
  login: lerTexto(j['login']),
  ativo: j['ativo'] as bool? ?? true,
  trocarSenha: j['trocarSenha'] as bool? ?? true,
  bloqueado: j['bloqueado'] as bool? ?? false,
  ultimoAcesso: lerData(j['ultimoAcesso']),
  criadoEm: lerData(j['criadoEm']) ?? DateTime.now(),
);

ArquivoContrato _arquivo(Map<String, dynamic> j) => ArquivoContrato(
  id: j['id'] as String,
  contratoId: j['contratoId'] as String,
  manutencaoId: j['manutencaoId'] as String?,
  tipo: lerEnum(
    TipoArquivoContrato.values,
    j['tipo'],
    TipoArquivoContrato.documento,
  ),
  origem: lerEnum(OrigemArquivo.values, j['origem'], OrigemArquivo.imobiliaria),
  titulo: lerTexto(j['titulo']),
  observacao: lerTexto(j['observacao']),
  referencia: lerTexto(j['referencia']),
  visivelInquilino: j['visivelInquilino'] as bool? ?? true,
  criadoEm: lerData(j['criadoEm']) ?? DateTime.now(),
);

ComunicadoInquilino _comunicado(Map<String, dynamic> j) => ComunicadoInquilino(
  id: j['id'] as String,
  contratoId: j['contratoId'] as String?,
  titulo: lerTexto(j['titulo']),
  mensagem: lerTexto(j['mensagem']),
  automatico: j['automatico'] as bool? ?? false,
  criadoEm: lerData(j['criadoEm']) ?? DateTime.now(),
  leituras: lerInt(j['leituras']),
);

/// Portal no servidor (`/api/v1/portal-inquilino`). Sem cache: cada tela
/// busca o que precisa (são poucos registros por contrato).
class PortalInquilinoApiRepository implements PortalInquilinoRepository {
  const PortalInquilinoApiRepository(this._api);
  final ApiClient _api;

  static const _base = 'portal-inquilino';

  List<Map<String, dynamic>> _lista(Object? r) =>
      (r as List).cast<Map<String, dynamic>>();

  @override
  Future<List<AcessoInquilino>> acessos() async => [
    for (final j in _lista(await _api.get('$_base/acessos'))) _acesso(j),
  ];

  @override
  Future<SenhaProvisoria> liberarAcesso(String contatoId) async {
    final j =
        await _api.post('$_base/acessos/$contatoId', null)
            as Map<String, dynamic>;
    return SenhaProvisoria(
      login: lerTexto(j['login']),
      senha: lerTexto(j['senha']),
    );
  }

  @override
  Future<void> revogarAcesso(String contatoId) =>
      _api.delete('$_base/acessos/$contatoId');

  @override
  Future<List<ArquivoContrato>> arquivos({
    String? contratoId,
    String? manutencaoId,
  }) async => [
    for (final j in _lista(
      await _api.get(
        '$_base/arquivos',
        query: {'contratoId': contratoId, 'manutencaoId': manutencaoId},
      ),
    ))
      _arquivo(j),
  ];

  @override
  Future<void> salvarArquivo(ArquivoContrato a) =>
      _api.put('$_base/arquivos/${a.id}', {
        'contratoId': a.contratoId,
        'tipo': a.tipo.name,
        'titulo': a.titulo,
        'referencia': a.referencia,
        'observacao': a.observacao,
        'visivelInquilino': a.visivelInquilino,
      });

  @override
  Future<void> removerArquivo(String id) => _api.delete('$_base/arquivos/$id');

  @override
  Future<List<ComunicadoInquilino>> comunicados({String? contratoId}) async => [
    for (final j in _lista(
      await _api.get('$_base/comunicados', query: {'contratoId': contratoId}),
    ))
      _comunicado(j),
  ];

  @override
  Future<void> enviarComunicado({
    String? contratoId,
    required String titulo,
    required String mensagem,
  }) => _api.post('$_base/comunicados', {
    'contratoId': contratoId,
    'titulo': titulo,
    'mensagem': mensagem,
  });

  @override
  Future<void> removerComunicado(String id) =>
      _api.delete('$_base/comunicados/$id');
}

/// Sem servidor (testes).
class PortalInquilinoMemoryRepository implements PortalInquilinoRepository {
  final acessosPorContato = <String, AcessoInquilino>{};
  final arquivosPorId = <String, ArquivoContrato>{};
  final comunicadosPorId = <String, ComunicadoInquilino>{};

  @override
  Future<List<AcessoInquilino>> acessos() async =>
      acessosPorContato.values.toList();

  @override
  Future<SenhaProvisoria> liberarAcesso(String contatoId) async {
    acessosPorContato[contatoId] = AcessoInquilino(
      contatoId: contatoId,
      login: '00000000000',
      criadoEm: DateTime.now(),
    );
    return const SenhaProvisoria(login: '00000000000', senha: 'Provisoria23');
  }

  @override
  Future<void> revogarAcesso(String contatoId) async =>
      acessosPorContato.remove(contatoId);

  @override
  Future<List<ArquivoContrato>> arquivos({
    String? contratoId,
    String? manutencaoId,
  }) async => [
    for (final a in arquivosPorId.values)
      if ((contratoId == null || a.contratoId == contratoId) &&
          (manutencaoId == null || a.manutencaoId == manutencaoId))
        a,
  ];

  @override
  Future<void> salvarArquivo(ArquivoContrato a) async =>
      arquivosPorId[a.id] = a;

  @override
  Future<void> removerArquivo(String id) async => arquivosPorId.remove(id);

  @override
  Future<List<ComunicadoInquilino>> comunicados({String? contratoId}) async => [
    for (final c in comunicadosPorId.values)
      if (contratoId == null ||
          c.contratoId == null ||
          c.contratoId == contratoId)
        c,
  ]..sort((a, b) => b.criadoEm.compareTo(a.criadoEm));

  @override
  Future<void> enviarComunicado({
    String? contratoId,
    required String titulo,
    required String mensagem,
  }) async {
    final id = gerarId();
    comunicadosPorId[id] = ComunicadoInquilino(
      id: id,
      contratoId: contratoId,
      titulo: titulo,
      mensagem: mensagem,
      criadoEm: DateTime.now(),
    );
  }

  @override
  Future<void> removerComunicado(String id) async =>
      comunicadosPorId.remove(id);
}
