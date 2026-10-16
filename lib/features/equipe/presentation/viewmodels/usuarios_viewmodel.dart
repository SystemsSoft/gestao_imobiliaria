import '../../../../core/presentation/view_model.dart';
import '../../domain/entities/equipe_enums.dart';
import '../../domain/entities/sessao.dart';
import '../../domain/entities/usuario_sistema.dart';
import '../../domain/usecases/usuario_usecases.dart';

/// Usuários, sessões simultâneas e limites de segurança.
class UsuariosViewModel extends ViewModel {
  UsuariosViewModel(
    ObservarUsuarios observarUsuarios,
    ObservarSessoes observarSessoes,
    ObservarConfiguracaoSeguranca observarConfig,
    ObservarUsuarioAtual observarAtual,
    this._salvar,
    this._alternarAtivo,
    this._remover,
    this._encerrar,
    this._salvarConfig, {
    DateTime Function()? agora,
  }) : _agora = agora ?? DateTime.now {
    observar(observarUsuarios(), (l) {
      _usuarios = l;
      carregado = true;
    });
    observar(observarSessoes(), (l) => _sessoes = l);
    observar(observarConfig(), (c) => config = c);
    observar(observarAtual(), (id) => usuarioAtualId = id);
  }

  final SalvarUsuario _salvar;
  final AlternarAtivoUsuario _alternarAtivo;
  final RemoverUsuario _remover;
  final EncerrarSessao _encerrar;
  final SalvarConfiguracaoSeguranca _salvarConfig;
  final DateTime Function() _agora;

  List<UsuarioSistema> _usuarios = const [];
  List<SessaoUsuario> _sessoes = const [];
  ConfiguracaoSeguranca config = const ConfiguracaoSeguranca();
  String? usuarioAtualId;
  bool carregado = false;
  String query = '';
  PerfilAcesso? perfil;

  DateTime get hoje => _agora();

  List<SessaoUsuario> get sessoesAtivas => _filtrarAtivas();

  List<SessaoUsuario> _filtrarAtivas() =>
      _sessoes
          .where(
            (s) =>
                hoje.difference(s.ultimaAtividade).inMinutes <
                config.inatividadeMinutos,
          )
          .toList()
        ..sort((a, b) => b.inicio.compareTo(a.inicio));

  /// Quantos usuários estão conectados agora e quantos podem estar.
  int get conectados => sessoesAtivas.length;
  int get limite => config.limiteSessoes;
  bool get limiteAtingido => conectados >= limite;

  bool online(UsuarioSistema u) =>
      sessoesAtivas.any((s) => s.usuarioId == u.id);

  UsuarioSistema? usuario(String id) =>
      _usuarios.where((u) => u.id == id).firstOrNull;

  List<UsuarioSistema> get filtrados {
    final q = query.trim().toLowerCase();
    return _usuarios
        .where(
          (u) =>
              (perfil == null || u.perfil == perfil) &&
              (q.isEmpty ||
                  u.nome.toLowerCase().contains(q) ||
                  u.login.toLowerCase().contains(q) ||
                  u.email.toLowerCase().contains(q)),
        )
        .toList()
      ..sort((a, b) {
        if (a.ativo != b.ativo) return a.ativo ? -1 : 1;
        return a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
      });
  }

  void buscar(String t) {
    query = t;
    notificar();
  }

  void filtrarPerfil(PerfilAcesso? p) {
    perfil = p;
    notificar();
  }

  Future<bool> salvar(UsuarioSistema u, {String? senha}) =>
      executar(() => _salvar(u, senha: senha));
  Future<bool> alternarAtivo(UsuarioSistema u) =>
      executar(() => _alternarAtivo(u));
  Future<bool> remover(UsuarioSistema u) => executar(() => _remover(u));
  Future<bool> encerrarSessao(SessaoUsuario s) => executar(() => _encerrar(s));
  Future<bool> salvarConfig(ConfiguracaoSeguranca c) =>
      executar(() => _salvarConfig(c));
}
