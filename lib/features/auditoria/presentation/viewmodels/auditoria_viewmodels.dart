import 'dart:async';

import '../../../../core/arquivos/arquivo_repository.dart';
import '../../../../core/presentation/view_model.dart';
import '../../../../core/utils/id.dart';
import '../../../crm/domain/entities/contato.dart';
import '../../../crm/domain/entities/imovel.dart';
import '../../../crm/domain/usecases/contato_usecases.dart';
import '../../../crm/domain/usecases/imovel_usecases.dart';
import '../../../equipe/domain/entities/usuario_sistema.dart';
import '../../../equipe/domain/usecases/usuario_usecases.dart';
import '../../../locacao/domain/entities/contrato_locacao.dart';
import '../../../locacao/domain/usecases/contrato_usecases.dart';
import '../../../portal_inquilino/domain/entities/portal.dart';
import '../../domain/entities/auditoria.dart';
import '../../domain/repositories/auditoria_repository.dart';
import '../../domain/usecases/auditoria_usecases.dart';

/// Nomes de imóveis, contratos, contatos e usuários (para as listas).
abstract class _ComCadastros extends ViewModel {
  _ComCadastros(
    ObservarImoveis observarImoveis,
    ObservarContatos observarContatos,
    ObservarContratos observarContratos,
  ) {
    observar(observarImoveis(), (l) => imoveis = {for (final i in l) i.id: i});
    observar(
      observarContatos(),
      (l) => contatos = {for (final c in l) c.id: c},
    );
    observar(
      observarContratos(),
      (l) => contratos = {for (final c in l) c.id: c},
    );
  }

  Map<String, Imovel> imoveis = const {};
  Map<String, Contato> contatos = const {};
  Map<String, ContratoLocacao> contratos = const {};

  String nomeImovel(String? id) {
    final i = imoveis[id];
    return i == null ? 'Imóvel' : '${i.codigo} • ${i.titulo}';
  }
}

// ---------------------------------------------------------------- Pendências

class PendenciasViewModel extends _ComCadastros {
  PendenciasViewModel(
    super.observarImoveis,
    super.observarContatos,
    super.observarContratos,
    this._repo,
  ) {
    recarregar();
  }

  final AuditoriaRepository _repo;
  List<Pendencia> _todas = const [];
  bool carregado = false;
  Gravidade? gravidade;
  AreaPendencia? area;
  String _busca = '';

  Future<void> recarregar() async {
    await executar(() async => _todas = await _repo.pendencias());
    carregado = true;
    notificar();
  }

  int contar(Gravidade g) => _todas.where((p) => p.gravidade == g).length;

  List<Pendencia> get lista {
    final q = _busca.toLowerCase();
    return [
      for (final p in _todas)
        if ((gravidade == null || p.gravidade == gravidade) &&
            (area == null || p.area == area) &&
            (q.isEmpty ||
                [
                  p.titulo,
                  p.detalhe,
                  contatos[p.proprietarioId]?.nome ?? '',
                  nomeImovel(p.imovelId),
                  contratos[p.contratoId]?.numero ?? '',
                ].any((t) => t.toLowerCase().contains(q))))
          p,
    ];
  }

  void filtrarGravidade(Gravidade? g) {
    gravidade = g;
    notificar();
  }

  void filtrarArea(AreaPendencia? a) {
    area = a;
    notificar();
  }

  void buscar(String q) {
    _busca = q.trim();
    notificar();
  }
}

// ---------------------------------------------------------------- Auditorias

class AuditoriasViewModel extends _ComCadastros {
  AuditoriasViewModel(
    super.observarImoveis,
    super.observarContatos,
    super.observarContratos,
    ObservarUsuarios observarUsuarios,
    this._repo,
  ) {
    observar(
      observarUsuarios(),
      (l) => usuarios = {for (final u in l) u.id: u},
    );
    recarregar();
  }

  final AuditoriaRepository _repo;
  Map<String, UsuarioSistema> usuarios = const {};
  List<Auditoria> _todas = const [];
  List<ModeloChecklist> modelos = const [];
  bool carregado = false;
  StatusAuditoria? status;
  String _busca = '';

  Future<void> recarregar() async {
    await executar(() async {
      _todas = await _repo.listar();
      modelos = await _repo.modelos();
    });
    carregado = true;
    notificar();
  }

  ModeloChecklist? get modeloPadrao =>
      modelos.where((m) => m.padrao).firstOrNull ?? modelos.firstOrNull;

  int contar(StatusAuditoria s) => _todas.where((a) => a.status == s).length;

  List<Auditoria> get lista {
    final q = _busca.toLowerCase();
    return [
      for (final a in _todas)
        if ((status == null || a.status == status) &&
            (q.isEmpty ||
                [
                  a.numero,
                  nomeImovel(a.imovelId),
                  contatos[a.proprietarioId]?.nome ?? '',
                  usuarios[a.corretorId]?.nome ?? '',
                ].any((t) => t.toLowerCase().contains(q))))
          a,
    ]..sort((a, b) {
      final da = a.data ?? a.criadoEm ?? DateTime(2000);
      final db = b.data ?? b.criadoEm ?? DateTime(2000);
      return db.compareTo(da);
    });
  }

  void filtrar(StatusAuditoria? s) {
    status = s;
    notificar();
  }

  void buscar(String q) {
    _busca = q.trim();
    notificar();
  }
}

// ---------------------------------------------------------- Uma auditoria

/// Formulário da auditoria em campo: checklist, mídias (com transcrição
/// dos vídeos), conclusão, publicação e relatório.
class AuditoriaFormViewModel extends _ComCadastros {
  AuditoriaFormViewModel(
    Auditoria inicial,
    super.observarImoveis,
    super.observarContatos,
    super.observarContratos,
    ObservarUsuarios observarUsuarios,
    this._repo,
    this._anexar, {
    this.intervaloTranscricao = const Duration(seconds: 8),
  }) : auditoria = inicial {
    observar(
      observarUsuarios(),
      (l) =>
          corretores = l.where((u) => u.ativo).toList()
            ..sort((a, b) => a.nome.compareTo(b.nome)),
    );
    _acompanharTranscricoes();
  }

  final AuditoriaRepository _repo;
  final AnexarMidiaAuditoria _anexar;
  final Duration intervaloTranscricao;
  Auditoria auditoria;
  List<UsuarioSistema> corretores = const [];

  /// Há alterações do formulário ainda não salvas.
  bool alterada = false;
  Timer? _timer;

  bool get somenteLeitura => auditoria.concluida;

  /// Contratos do imóvel escolhido.
  List<ContratoLocacao> get contratosDoImovel =>
      contratos.values.where((c) => c.imovelId == auditoria.imovelId).toList()
        ..sort((a, b) => b.dataInicio.compareTo(a.dataInicio));

  List<Imovel> get listaImoveis =>
      imoveis.values.toList()..sort((a, b) => a.codigo.compareTo(b.codigo));

  /// Áreas do checklist na ordem em que aparecem.
  Map<String, List<ItemAuditoria>> get areas {
    final r = <String, List<ItemAuditoria>>{};
    for (final i in auditoria.itens) {
      r.putIfAbsent(i.area, () => []).add(i);
    }
    return r;
  }

  List<MidiaAuditoria> midiasDo(String? itemId) =>
      auditoria.midias.where((m) => m.itemId == itemId).toList();

  void editar(Auditoria Function(Auditoria) mudar) {
    auditoria = mudar(auditoria);
    alterada = true;
    notificar();
  }

  void avaliar(ItemAuditoria item, EstadoItem estado) => editar(
    (a) => a.copyWith(
      itens: [
        for (final i in a.itens)
          i.id == item.id ? i.copyWith(estado: estado) : i,
      ],
      // Começar a avaliar põe a auditoria "em andamento".
      status: a.status == StatusAuditoria.agendada
          ? StatusAuditoria.emAndamento
          : null,
    ),
  );

  void observarItem(ItemAuditoria item, String texto) {
    auditoria = auditoria.copyWith(
      itens: [
        for (final i in auditoria.itens)
          i.id == item.id ? i.copyWith(observacao: texto) : i,
      ],
    );
    alterada = true; // sem notificar: o campo já mostra o texto
  }

  void adicionarItem(String area, String item) => editar(
    (a) => a.copyWith(
      itens: [
        ...a.itens,
        ItemAuditoria(id: gerarId(), area: area.trim(), item: item.trim()),
      ],
    ),
  );

  /// Acrescenta os itens do modelo que ainda não estão no checklist.
  void aplicarModelo(ModeloChecklist m) => editar(
    (a) => a.copyWith(
      itens: [
        ...a.itens,
        for (final i in m.itens)
          if (!a.itens.any((x) => x.area == i.area && x.item == i.item))
            ItemAuditoria(id: gerarId(), area: i.area, item: i.item),
      ],
    ),
  );

  void removerItem(ItemAuditoria item) => editar(
    (a) => a.copyWith(itens: a.itens.where((i) => i.id != item.id).toList()),
  );

  /// Marca como OK todos os itens ainda não avaliados da área.
  void areaOk(String area) => editar(
    (a) => a.copyWith(
      itens: [
        for (final i in a.itens)
          i.area == area && i.estado == EstadoItem.pendente
              ? i.copyWith(estado: EstadoItem.ok)
              : i,
      ],
    ),
  );

  Future<bool> salvar() => executar(_salvar);

  Future<void> _salvar() async {
    auditoria = await _repo.salvar(auditoria);
    alterada = false;
  }

  /// Salva antes, se preciso (mídias e ações exigem a auditoria no servidor).
  Future<void> _garantirSalva() async {
    if (auditoria.nova || alterada) await _salvar();
  }

  Future<bool> anexar({
    required ArquivoEscolhido arquivo,
    required TipoMidia tipo,
    String titulo = '',
    String? itemId,
  }) => executar(() async {
    await _garantirSalva();
    auditoria = await _anexar(
      auditoria,
      arquivo: arquivo,
      tipo: tipo,
      titulo: titulo,
      itemId: itemId,
    );
  });

  Future<bool> removerMidia(MidiaAuditoria m) => executar(() async {
    auditoria = await _repo.removerMidia(auditoria.id, m.id);
  });

  Future<bool> transcrever(MidiaAuditoria m) => executar(() async {
    await _garantirSalva();
    auditoria = await _repo.transcrever(auditoria.id, m.id);
    _acompanharTranscricoes();
  });

  /// Enquanto houver vídeo na fila, consulta o servidor de tempos em tempos
  /// e atualiza só as mídias (sem perder o que está sendo editado).
  void _acompanharTranscricoes() {
    final andamento = auditoria.midias.any(
      (m) => m.transcricaoStatus.emAndamento,
    );
    if (!andamento) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    _timer ??= Timer.periodic(intervaloTranscricao, (_) => atualizarMidias());
  }

  Future<void> atualizarMidias() async {
    if (auditoria.nova || disposed) return;
    try {
      final r = await _repo.obter(auditoria.id);
      if (disposed) return;
      auditoria = Auditoria(
        id: auditoria.id,
        numero: auditoria.numero,
        imovelId: auditoria.imovelId,
        contratoId: auditoria.contratoId,
        proprietarioId: auditoria.proprietarioId,
        corretorId: auditoria.corretorId,
        tipo: auditoria.tipo,
        status: auditoria.status,
        dataAgendada: auditoria.dataAgendada,
        dataRealizada: auditoria.dataRealizada,
        nota: auditoria.nota,
        resumo: auditoria.resumo,
        recomendacoes: auditoria.recomendacoes,
        publicada: auditoria.publicada,
        concluidaEm: auditoria.concluidaEm,
        itens: auditoria.itens,
        midias: r.midias,
        criadoEm: auditoria.criadoEm,
      );
      _acompanharTranscricoes();
      notificar();
    } on Exception {
      // Sem conexão: tenta de novo no próximo ciclo.
    }
  }

  Future<bool> concluir({required bool publicar}) => executar(() async {
    validarConclusao(auditoria);
    await _garantirSalva();
    auditoria = await _repo.concluir(auditoria.id, publicar: publicar);
  });

  Future<bool> reabrir() => executar(() async {
    auditoria = await _repo.reabrir(auditoria.id);
  });

  Future<bool> publicar(bool publicada) => executar(() async {
    auditoria = await _repo.publicar(auditoria.id, publicada);
  });

  /// Quantas pautas de manutenção foram criadas na última vez.
  int manutencoesCriadas = 0;

  Future<bool> gerarManutencoes() => executar(() async {
    await _garantirSalva();
    final r = await _repo.gerarManutencoes(auditoria.id);
    auditoria = r.auditoria;
    manutencoesCriadas = r.criadas;
  });

  Uri? relatorio;

  Future<bool> abrirRelatorio() => executar(() async {
    await _garantirSalva();
    relatorio = await _repo.linkRelatorio(auditoria.id);
  });

  Future<bool> excluir() => executar(() => _repo.remover(auditoria.id));

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// ------------------------------------------------------------ Proprietários

class ProprietariosAuditoriaViewModel extends ViewModel {
  ProprietariosAuditoriaViewModel(
    ObservarContatos observarContatos,
    this._repo,
  ) {
    observar(
      observarContatos(),
      (l) => contatos = {for (final c in l) c.id: c},
    );
    recarregar();
  }

  final AuditoriaRepository _repo;
  Map<String, Contato> contatos = const {};
  List<ResumoProprietario> _todos = const [];
  bool carregado = false;
  String _busca = '';

  /// Senha provisória recém-gerada (mostrada uma vez).
  SenhaProvisoria? senhaGerada;

  Future<void> recarregar() async {
    await executar(() async => _todos = await _repo.proprietarios());
    carregado = true;
    notificar();
  }

  int contar(Saude s) => _todos.where((p) => p.saude == s).length;
  int get comAcesso => _todos.where((p) => p.acesso?.ativo ?? false).length;

  List<ResumoProprietario> get lista {
    final q = _busca.toLowerCase();
    return [
      for (final p in _todos)
        if (q.isEmpty ||
            p.nome.toLowerCase().contains(q) ||
            p.documento.contains(q))
          p,
    ]..sort((a, b) {
      final s = b.saude.index.compareTo(a.saude.index);
      return s != 0 ? s : a.nome.compareTo(b.nome);
    });
  }

  void buscar(String q) {
    _busca = q.trim();
    notificar();
  }

  Future<bool> liberarAcesso(ResumoProprietario p) => executar(() async {
    senhaGerada = await _repo.liberarAcesso(p.contatoId);
    _todos = await _repo.proprietarios();
  });

  Future<bool> revogarAcesso(ResumoProprietario p) => executar(() async {
    await _repo.revogarAcesso(p.contatoId);
    _todos = await _repo.proprietarios();
  });
}

// ------------------------------------------------------------ Configurações

class ConfiguracaoAuditoriaViewModel extends ViewModel {
  ConfiguracaoAuditoriaViewModel(this._repo) {
    recarregar();
  }

  final AuditoriaRepository _repo;
  ConfiguracaoAuditoria? configuracao;
  List<ModeloChecklist> modelos = const [];

  Future<void> recarregar() => executar(() async {
    configuracao = await _repo.configuracao();
    modelos = await _repo.modelos();
  });

  Future<bool> salvarConfiguracao(ConfiguracaoAuditoria c) =>
      executar(() async {
        await _repo.salvarConfiguracao(c);
        configuracao = c;
      });

  Future<bool> salvarModelo(ModeloChecklist m) => executar(() async {
    await _repo.salvarModelo(m);
    modelos = await _repo.modelos();
  });

  Future<bool> removerModelo(ModeloChecklist m) => executar(() async {
    await _repo.removerModelo(m.id);
    modelos = await _repo.modelos();
  });
}
