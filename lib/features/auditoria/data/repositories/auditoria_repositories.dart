import '../../../../core/api/api_client.dart';
import '../../../../core/api/json.dart';
import '../../../../core/errors/domain_exception.dart';
import '../../../../core/utils/id.dart';
import '../../../portal_inquilino/domain/entities/portal.dart';
import '../../domain/entities/auditoria.dart';
import '../../domain/repositories/auditoria_repository.dart';

typedef _Json = Map<String, dynamic>;

ItemAuditoria _item(_Json j) => ItemAuditoria(
  id: j['id'] as String,
  area: lerTexto(j['area']),
  item: lerTexto(j['item']),
  estado: lerEnum(EstadoItem.values, j['estado'], EstadoItem.pendente),
  observacao: lerTexto(j['observacao']),
  manutencaoId: j['manutencaoId'] as String?,
);

MidiaAuditoria _midia(_Json j) => MidiaAuditoria(
  id: j['id'] as String,
  referencia: lerTexto(j['referencia']),
  tipo: lerEnum(TipoMidia.values, j['tipo'], TipoMidia.foto),
  titulo: lerTexto(j['titulo']),
  itemId: j['itemId'] as String?,
  transcricaoStatus: lerEnum(
    StatusTranscricao.values,
    j['transcricaoStatus'],
    StatusTranscricao.naoSolicitada,
  ),
  transcricaoTexto: lerTexto(j['transcricaoTexto']),
  transcricaoErro: lerTexto(j['transcricaoErro']),
  transcricaoEm: lerData(j['transcricaoEm']),
  criadoEm: lerData(j['criadoEm']) ?? DateTime.now(),
);

Auditoria auditoriaDeJson(Map<String, dynamic> j) => Auditoria(
  id: j['id'] as String,
  numero: lerTexto(j['numero']),
  imovelId: lerTexto(j['imovelId']),
  contratoId: j['contratoId'] as String?,
  proprietarioId: j['proprietarioId'] as String?,
  corretorId: j['corretorId'] as String?,
  tipo: lerEnum(TipoAuditoria.values, j['tipo'], TipoAuditoria.periodica),
  status: lerEnum(
    StatusAuditoria.values,
    j['status'],
    StatusAuditoria.agendada,
  ),
  dataAgendada: lerData(j['dataAgendada']),
  dataRealizada: lerData(j['dataRealizada']),
  nota: (j['nota'] as num?)?.toInt(),
  resumo: lerTexto(j['resumo']),
  recomendacoes: lerTexto(j['recomendacoes']),
  publicada: j['publicada'] as bool? ?? false,
  concluidaEm: lerData(j['concluidaEm']),
  itens: [for (final i in (j['itens'] as List? ?? const [])) _item(i as _Json)],
  midias: [
    for (final m in (j['midias'] as List? ?? const [])) _midia(m as _Json),
  ],
  criadoEm: lerData(j['criadoEm']),
);

Map<String, dynamic> auditoriaParaJson(Auditoria a) => {
  'imovelId': a.imovelId,
  'contratoId': a.contratoId,
  'corretorId': a.corretorId,
  'tipo': a.tipo.name,
  'status': a.status.name,
  'dataAgendada': escreverData(a.dataAgendada),
  'dataRealizada': escreverData(a.dataRealizada),
  'nota': a.nota,
  'resumo': a.resumo,
  'recomendacoes': a.recomendacoes,
  'itens': [
    for (final i in a.itens)
      {
        'id': i.id,
        'area': i.area,
        'item': i.item,
        'estado': i.estado.name,
        'observacao': i.observacao,
      },
  ],
};

ConfiguracaoAuditoria _configuracao(_Json j) => ConfiguracaoAuditoria(
  prazoRepasseDias: lerInt(j['prazoRepasseDias'], 5),
  atrasoCriticoDias: lerInt(j['atrasoCriticoDias'], 30),
  chamadoSemRespostaHoras: lerInt(j['chamadoSemRespostaHoras'], 48),
  manutencaoParadaDias: lerInt(j['manutencaoParadaDias'], 30),
  mesesSemAuditoria: lerInt(j['mesesSemAuditoria'], 12),
  avisoVencimentoContratoDias: lerInt(j['avisoVencimentoContratoDias'], 60),
);

ModeloChecklist _modelo(_Json j) => ModeloChecklist(
  id: j['id'] as String,
  nome: lerTexto(j['nome']),
  padrao: j['padrao'] as bool? ?? false,
  itens: [
    for (final i in (j['itens'] as List? ?? const []))
      (area: lerTexto((i as _Json)['area']), item: lerTexto(i['item'])),
  ],
);

Pendencia _pendencia(_Json j) => Pendencia(
  id: j['id'] as String,
  gravidade: lerEnum(Gravidade.values, j['gravidade'], Gravidade.info),
  area: lerEnum(AreaPendencia.values, j['area'], AreaPendencia.contrato),
  titulo: lerTexto(j['titulo']),
  detalhe: lerTexto(j['detalhe']),
  contratoId: j['contratoId'] as String?,
  imovelId: j['imovelId'] as String?,
  proprietarioId: j['proprietarioId'] as String?,
);

ResumoProprietario _resumo(_Json j) {
  final a = j['acesso'] as _Json?;
  return ResumoProprietario(
    contatoId: j['contatoId'] as String,
    nome: lerTexto(j['nome']),
    documento: lerTexto(j['documento']),
    imoveis: lerInt(j['imoveis']),
    contratosAtivos: lerInt(j['contratosAtivos']),
    aluguelMensal: lerDouble(j['aluguelMensal']) ?? 0,
    emAtraso: lerDouble(j['emAtraso']) ?? 0,
    criticas: lerInt(j['criticas']),
    atencoes: lerInt(j['atencoes']),
    ultimaAuditoria: lerData(j['ultimaAuditoria']),
    saude: lerEnum(Saude.values, j['saude'], Saude.verde),
    acesso: a == null
        ? null
        : AcessoProprietario(
            ativo: a['ativo'] as bool? ?? true,
            trocarSenha: a['trocarSenha'] as bool? ?? true,
            bloqueado: a['bloqueado'] as bool? ?? false,
            ultimoAcesso: lerData(a['ultimoAcesso']),
          ),
  );
}

/// Auditorias no servidor (`/api/v1/auditorias`). Sem cache: as telas
/// buscam o que precisam e as pendências são calculadas na hora.
class AuditoriaApiRepository implements AuditoriaRepository {
  const AuditoriaApiRepository(this._api);
  final ApiClient _api;

  static const _base = 'auditorias';

  List<_Json> _lista(Object? r) => (r as List).cast<_Json>();
  Auditoria _a(Object? r) => auditoriaDeJson(r as _Json);

  @override
  Future<List<Auditoria>> listar({
    String? imovelId,
    String? proprietarioId,
  }) async => [
    for (final j in await _api.listarTudo(
      _base,
      query: {'imovelId': imovelId, 'proprietarioId': proprietarioId},
    ))
      auditoriaDeJson(j),
  ];

  @override
  Future<Auditoria> obter(String id) async => _a(await _api.get('$_base/$id'));

  @override
  Future<Auditoria> salvar(Auditoria a) async =>
      _a(await _api.put('$_base/${a.id}', auditoriaParaJson(a)));

  @override
  Future<void> remover(String id) => _api.delete('$_base/$id');

  @override
  Future<Auditoria> concluir(String id, {required bool publicar}) async =>
      _a(await _api.post('$_base/$id/concluir', {'publicar': publicar}));

  @override
  Future<Auditoria> reabrir(String id) async =>
      _a(await _api.post('$_base/$id/reabrir', null));

  @override
  Future<Auditoria> publicar(String id, bool publicada) async =>
      _a(await _api.post('$_base/$id/publicacao', {'publicada': publicada}));

  @override
  Future<({int criadas, Auditoria auditoria})> gerarManutencoes(
    String id,
  ) async {
    final j = await _api.post('$_base/$id/manutencoes', null) as _Json;
    return (criadas: lerInt(j['criadas']), auditoria: _a(j['auditoria']));
  }

  @override
  Future<Uri> linkRelatorio(String id) async {
    final j = await _api.post('$_base/$id/relatorio', null) as _Json;
    return _api.endereco(lerTexto(j['link']));
  }

  @override
  Future<Auditoria> salvarMidia(
    String auditoriaId, {
    required String midiaId,
    required String referencia,
    required TipoMidia tipo,
    String titulo = '',
    String? itemId,
  }) async => _a(
    await _api.put('$_base/$auditoriaId/midias/$midiaId', {
      'referencia': referencia,
      'tipo': tipo.name,
      'titulo': titulo,
      'itemId': itemId,
    }),
  );

  @override
  Future<Auditoria> removerMidia(String auditoriaId, String midiaId) async {
    await _api.delete('$_base/$auditoriaId/midias/$midiaId');
    return obter(auditoriaId);
  }

  @override
  Future<Auditoria> transcrever(String auditoriaId, String midiaId) async => _a(
    await _api.post('$_base/$auditoriaId/midias/$midiaId/transcrever', null),
  );

  @override
  Future<List<Pendencia>> pendencias({String? proprietarioId}) async => [
    for (final j in _lista(
      await _api.get(
        '$_base/pendencias',
        query: {'proprietarioId': proprietarioId},
      ),
    ))
      _pendencia(j),
  ];

  @override
  Future<List<ResumoProprietario>> proprietarios() async => [
    for (final j in _lista(await _api.get('$_base/proprietarios'))) _resumo(j),
  ];

  @override
  Future<SenhaProvisoria> liberarAcesso(String contatoId) async {
    final j =
        await _api.post('$_base/proprietarios/$contatoId/acesso', null)
            as _Json;
    return SenhaProvisoria(
      login: lerTexto(j['login']),
      senha: lerTexto(j['senha']),
    );
  }

  @override
  Future<void> revogarAcesso(String contatoId) =>
      _api.delete('$_base/proprietarios/$contatoId/acesso');

  @override
  Future<ConfiguracaoAuditoria> configuracao() async =>
      _configuracao(await _api.get('$_base/configuracao') as _Json);

  @override
  Future<void> salvarConfiguracao(ConfiguracaoAuditoria c) =>
      _api.put('$_base/configuracao', {
        'prazoRepasseDias': c.prazoRepasseDias,
        'atrasoCriticoDias': c.atrasoCriticoDias,
        'chamadoSemRespostaHoras': c.chamadoSemRespostaHoras,
        'manutencaoParadaDias': c.manutencaoParadaDias,
        'mesesSemAuditoria': c.mesesSemAuditoria,
        'avisoVencimentoContratoDias': c.avisoVencimentoContratoDias,
      });

  @override
  Future<List<ModeloChecklist>> modelos() async => [
    for (final j in _lista(await _api.get('$_base/modelos'))) _modelo(j),
  ];

  @override
  Future<void> salvarModelo(ModeloChecklist m) =>
      _api.put('$_base/modelos/${m.id}', {
        'nome': m.nome,
        'padrao': m.padrao,
        'itens': [
          for (final i in m.itens) {'area': i.area, 'item': i.item},
        ],
      });

  @override
  Future<void> removerModelo(String id) => _api.delete('$_base/modelos/$id');
}

/// Sem servidor (testes): guarda tudo em memória e imita as regras
/// principais do servidor (numeração, trava da concluída, fila).
class AuditoriaMemoryRepository implements AuditoriaRepository {
  final auditorias = <String, Auditoria>{};
  final modelosPorId = <String, ModeloChecklist>{
    'padrao': const ModeloChecklist(
      id: 'padrao',
      nome: 'Vistoria residencial (padrão)',
      padrao: true,
      itens: [
        (area: 'Sala', item: 'Paredes e teto'),
        (area: 'Sala', item: 'Piso'),
        (area: 'Cozinha', item: 'Torneiras e sifão'),
      ],
    ),
  };
  var pendenciasLista = <Pendencia>[];
  var proprietariosLista = <ResumoProprietario>[];
  final acessos = <String>{};
  var config = const ConfiguracaoAuditoria();
  var _numero = 0;

  Auditoria _buscar(String id) =>
      auditorias[id] ??
      (throw const DomainException('Auditoria não encontrada.'));

  void _editavel(Auditoria a) {
    if (a.concluida) {
      throw const DomainException(
        'Auditoria concluída não pode ser alterada. Reabra para editar.',
      );
    }
  }

  Auditoria _com(
    Auditoria a, {
    StatusAuditoria? status,
    bool? publicada,
    List<ItemAuditoria>? itens,
    List<MidiaAuditoria>? midias,
    String? numero,
  }) => Auditoria(
    id: a.id,
    numero: numero ?? a.numero,
    imovelId: a.imovelId,
    contratoId: a.contratoId,
    proprietarioId: a.proprietarioId,
    corretorId: a.corretorId,
    tipo: a.tipo,
    status: status ?? a.status,
    dataAgendada: a.dataAgendada,
    dataRealizada: a.dataRealizada,
    nota: a.nota,
    resumo: a.resumo,
    recomendacoes: a.recomendacoes,
    publicada: publicada ?? a.publicada,
    itens: itens ?? a.itens,
    midias: midias ?? a.midias,
    criadoEm: a.criadoEm ?? DateTime.now(),
  );

  @override
  Future<List<Auditoria>> listar({
    String? imovelId,
    String? proprietarioId,
  }) async => [
    for (final a in auditorias.values)
      if ((imovelId == null || a.imovelId == imovelId) &&
          (proprietarioId == null || a.proprietarioId == proprietarioId))
        a,
  ];

  @override
  Future<Auditoria> obter(String id) async => _buscar(id);

  @override
  Future<Auditoria> salvar(Auditoria a) async {
    final atual = auditorias[a.id];
    if (atual != null) _editavel(atual);
    final salva = _com(
      a,
      numero: atual?.numero ?? 'AUD-${(++_numero).toString().padLeft(4, '0')}',
      midias: atual?.midias ?? const [],
    );
    return auditorias[a.id] = salva;
  }

  @override
  Future<void> remover(String id) async {
    _editavel(_buscar(id));
    auditorias.remove(id);
  }

  @override
  Future<Auditoria> concluir(String id, {required bool publicar}) async {
    final a = _buscar(id);
    _editavel(a);
    if (a.itens.any((i) => i.estado == EstadoItem.pendente)) {
      throw const DomainException('Avalie todos os itens do checklist.');
    }
    if (a.nota == null) {
      throw const DomainException('Dê a nota de conservação (1 a 5).');
    }
    return auditorias[id] = _com(
      a,
      status: StatusAuditoria.concluida,
      publicada: publicar,
    );
  }

  @override
  Future<Auditoria> reabrir(String id) async => auditorias[id] = _com(
    _buscar(id),
    status: StatusAuditoria.emAndamento,
    publicada: false,
  );

  @override
  Future<Auditoria> publicar(String id, bool publicada) async {
    final a = _buscar(id);
    if (publicada && !a.concluida) {
      throw const DomainException('Conclua a auditoria antes de publicá-la.');
    }
    return auditorias[id] = _com(a, publicada: publicada);
  }

  @override
  Future<({int criadas, Auditoria auditoria})> gerarManutencoes(
    String id,
  ) async {
    final a = _buscar(id);
    var criadas = 0;
    final itens = [
      for (final i in a.itens)
        if (i.estado == EstadoItem.problema && i.manutencaoId == null)
          () {
            criadas++;
            return ItemAuditoria(
              id: i.id,
              area: i.area,
              item: i.item,
              estado: i.estado,
              observacao: i.observacao,
              manutencaoId: gerarId(),
            );
          }()
        else
          i,
    ];
    return (
      criadas: criadas,
      auditoria: auditorias[id] = _com(a, itens: itens),
    );
  }

  @override
  Future<Uri> linkRelatorio(String id) async =>
      Uri.parse('http://localhost:8000/relatorio-auditoria/$id');

  @override
  Future<Auditoria> salvarMidia(
    String auditoriaId, {
    required String midiaId,
    required String referencia,
    required TipoMidia tipo,
    String titulo = '',
    String? itemId,
  }) async {
    final a = _buscar(auditoriaId);
    _editavel(a);
    final m = MidiaAuditoria(
      id: midiaId,
      referencia: referencia,
      tipo: tipo,
      titulo: titulo,
      itemId: itemId,
      criadoEm: DateTime.now(),
    );
    return auditorias[auditoriaId] = _com(
      a,
      midias: [...a.midias.where((x) => x.id != midiaId), m],
    );
  }

  @override
  Future<Auditoria> removerMidia(String auditoriaId, String midiaId) async {
    final a = _buscar(auditoriaId);
    _editavel(a);
    return auditorias[auditoriaId] = _com(
      a,
      midias: a.midias.where((x) => x.id != midiaId).toList(),
    );
  }

  @override
  Future<Auditoria> transcrever(String auditoriaId, String midiaId) async {
    final a = _buscar(auditoriaId);
    return auditorias[auditoriaId] = _com(
      a,
      midias: [
        for (final m in a.midias)
          m.id == midiaId
              ? concluirTranscricao(m, '', StatusTranscricao.pendente)
              : m,
      ],
    );
  }

  /// Simula o trabalho da fila do servidor.
  static MidiaAuditoria concluirTranscricao(
    MidiaAuditoria m,
    String texto, [
    StatusTranscricao status = StatusTranscricao.concluida,
  ]) => MidiaAuditoria(
    id: m.id,
    referencia: m.referencia,
    tipo: m.tipo,
    titulo: m.titulo,
    itemId: m.itemId,
    criadoEm: m.criadoEm,
    transcricaoStatus: status,
    transcricaoTexto: texto,
  );

  @override
  Future<List<Pendencia>> pendencias({String? proprietarioId}) async => [
    for (final p in pendenciasLista)
      if (proprietarioId == null || p.proprietarioId == proprietarioId) p,
  ];

  @override
  Future<List<ResumoProprietario>> proprietarios() async => [
    for (final p in proprietariosLista)
      ResumoProprietario(
        contatoId: p.contatoId,
        nome: p.nome,
        documento: p.documento,
        imoveis: p.imoveis,
        contratosAtivos: p.contratosAtivos,
        saude: p.saude,
        acesso: acessos.contains(p.contatoId)
            ? const AcessoProprietario()
            : null,
      ),
  ];

  @override
  Future<SenhaProvisoria> liberarAcesso(String contatoId) async {
    acessos.add(contatoId);
    return const SenhaProvisoria(login: '00000000000', senha: 'Provisoria23');
  }

  @override
  Future<void> revogarAcesso(String contatoId) async =>
      acessos.remove(contatoId);

  @override
  Future<ConfiguracaoAuditoria> configuracao() async => config;

  @override
  Future<void> salvarConfiguracao(ConfiguracaoAuditoria c) async => config = c;

  @override
  Future<List<ModeloChecklist>> modelos() async => modelosPorId.values.toList();

  @override
  Future<void> salvarModelo(ModeloChecklist m) async {
    if (m.padrao) {
      for (final o in modelosPorId.values.toList()) {
        modelosPorId[o.id] = ModeloChecklist(
          id: o.id,
          nome: o.nome,
          itens: o.itens,
        );
      }
    }
    modelosPorId[m.id] = m;
  }

  @override
  Future<void> removerModelo(String id) async => modelosPorId.remove(id);
}
