import '../../../../core/presentation/view_model.dart';
import '../../domain/entities/chat.dart';
import '../../domain/entities/sessao.dart';
import '../../domain/entities/usuario_sistema.dart';
import '../../domain/usecases/chat_usecases.dart';
import '../../domain/usecases/usuario_usecases.dart';

class ConversaResumo {
  const ConversaResumo({
    required this.id,
    required this.titulo,
    required this.naoLidas,
    this.usuario,
    this.ultima,
  });

  final String id;
  final String titulo;

  /// Nulo na conversa geral.
  final UsuarioSistema? usuario;
  final Mensagem? ultima;
  final int naoLidas;
}

/// Chat interno: canal geral e conversas diretas entre os usuários.
class ChatViewModel extends ViewModel {
  ChatViewModel(
    ObservarMensagens observarMensagens,
    ObservarUsuarios observarUsuarios,
    ObservarSessoes observarSessoes,
    ObservarConfiguracaoSeguranca observarConfig,
    ObservarUsuarioAtual observarAtual,
    this._enviar,
    this._marcarLida,
    this._apagar,
    this._definirAtual, {
    DateTime Function()? agora,
  }) : _agora = agora ?? DateTime.now {
    observar(observarMensagens(), (l) {
      _mensagens = l;
      carregado = true;
      _marcarAberta();
    });
    observar(observarUsuarios(), (l) => usuarios = l);
    observar(observarSessoes(), (l) => _sessoes = l);
    observar(observarConfig(), (c) => _config = c);
    observar(observarAtual(), (id) {
      usuarioAtualId = id;
      conversaId = conversaGeral;
    });
  }

  final EnviarMensagem _enviar;
  final MarcarConversaLida _marcarLida;
  final ApagarMensagem _apagar;
  final DefinirUsuarioAtual _definirAtual;
  final DateTime Function() _agora;

  List<Mensagem> _mensagens = const [];
  List<SessaoUsuario> _sessoes = const [];
  ConfiguracaoSeguranca _config = const ConfiguracaoSeguranca();
  List<UsuarioSistema> usuarios = const [];
  String? usuarioAtualId;
  String conversaId = conversaGeral;
  bool carregado = false;

  UsuarioSistema? get atual =>
      usuarios.where((u) => u.id == usuarioAtualId).firstOrNull;

  UsuarioSistema? usuario(String id) =>
      usuarios.where((u) => u.id == id).firstOrNull;
  String nome(String id) => usuario(id)?.nome ?? 'Usuário removido';

  bool online(String usuarioId) => _sessoes.any(
    (s) =>
        s.usuarioId == usuarioId &&
        _agora().difference(s.ultimaAtividade).inMinutes <
            _config.inatividadeMinutos,
  );

  List<UsuarioSistema> get outros =>
      usuarios.where((u) => u.ativo && u.id != usuarioAtualId).toList()
        ..sort((a, b) {
          final o = (online(b.id) ? 1 : 0) - (online(a.id) ? 1 : 0);
          return o != 0 ? o : a.nome.compareTo(b.nome);
        });

  int _naoLidas(String conv) {
    final id = usuarioAtualId;
    if (id == null) return 0;
    return _mensagens
        .where((m) => m.conversaId == conv && !m.lidaPorUsuario(id))
        .length;
  }

  Mensagem? _ultima(String conv) {
    final l = _mensagens.where((m) => m.conversaId == conv).toList()
      ..sort((a, b) => b.enviadaEm.compareTo(a.enviadaEm));
    return l.firstOrNull;
  }

  List<ConversaResumo> get conversas {
    final id = usuarioAtualId;
    return [
      ConversaResumo(
        id: conversaGeral,
        titulo: 'Geral (todos)',
        naoLidas: _naoLidas(conversaGeral),
        ultima: _ultima(conversaGeral),
      ),
      if (id != null)
        for (final u in outros)
          ConversaResumo(
            id: conversaDireta(id, u.id),
            titulo: u.nome,
            usuario: u,
            naoLidas: _naoLidas(conversaDireta(id, u.id)),
            ultima: _ultima(conversaDireta(id, u.id)),
          ),
    ];
  }

  int get totalNaoLidas => conversas.fold(0, (s, c) => s + c.naoLidas);

  ConversaResumo get conversaAtual =>
      conversas.where((c) => c.id == conversaId).firstOrNull ?? conversas.first;

  List<Mensagem> get mensagens =>
      _mensagens.where((m) => m.conversaId == conversaId).toList()
        ..sort((a, b) => a.enviadaEm.compareTo(b.enviadaEm));

  void selecionar(String id) {
    conversaId = id;
    _marcarAberta();
    notificar();
  }

  /// Marca como lida a conversa aberta, para o usuário atual.
  void _marcarAberta() {
    final id = usuarioAtualId;
    if (id == null) return;
    final pendente = _mensagens.any(
      (m) => m.conversaId == conversaId && !m.lidaPorUsuario(id),
    );
    if (pendente) _marcarLida(conversaId, id);
  }

  Future<bool> enviar(String texto) {
    final id = usuarioAtualId;
    if (id == null) return Future.value(false);
    return executar(
      () => _enviar(conversaId: conversaId, remetenteId: id, texto: texto),
    );
  }

  Future<bool> apagar(Mensagem m) {
    final id = usuarioAtualId;
    if (id == null) return Future.value(false);
    return executar(() => _apagar(m, id));
  }

  /// Simula entrar no sistema como outro usuário (abre uma sessão).
  Future<bool> entrarComo(String usuarioId) =>
      executar(() => _definirAtual(usuarioId));
}
