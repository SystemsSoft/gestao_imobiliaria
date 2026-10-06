import '../../../../core/presentation/view_model.dart';
import '../../domain/entities/equipe_enums.dart';
import '../../domain/entities/permissoes.dart';
import '../../domain/entities/usuario_sistema.dart';
import '../../domain/usecases/permissao_usecases.dart';
import '../../domain/usecases/usuario_usecases.dart';

/// Edição das permissões de um usuário, com rascunho até salvar.
class PermissoesViewModel extends ViewModel {
  PermissoesViewModel(ObservarUsuarios observarUsuarios, this._salvar) {
    observar(observarUsuarios(), (l) {
      usuarios = [...l]
        ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
      carregado = true;
      // Mantém o rascunho se o usuário selecionado continua igual.
      if (_selecionadoId != null && !alterado) {
        _rascunho = selecionado?.permissoes;
      }
    });
  }

  final SalvarPermissoes _salvar;

  List<UsuarioSistema> usuarios = const [];
  bool carregado = false;
  String? _selecionadoId;
  Permissoes? _rascunho;
  PerfilAcesso? _perfilRascunho;
  bool alterado = false;

  UsuarioSistema? get selecionado =>
      usuarios.where((u) => u.id == _selecionadoId).firstOrNull ??
      usuarios.firstOrNull;

  /// Permissões em edição (ainda não salvas).
  Permissoes get permissoes =>
      _rascunho ?? selecionado?.permissoes ?? const Permissoes();

  PerfilAcesso? get perfil => _perfilRascunho ?? selecionado?.perfil;

  void selecionar(String? id) {
    _selecionadoId = id;
    _rascunho = selecionado?.permissoes;
    _perfilRascunho = null;
    alterado = false;
    notificar();
  }

  void _mudar(Permissoes p) {
    _rascunho = p;
    alterado = true;
    notificar();
  }

  void alternarAcao(ModuloSistema m, AcaoPermissao a, bool liberada) =>
      _mudar(permissoes.comAcao(m, a, liberada));

  /// Libera ou bloqueia todas as ações do módulo.
  void alternarModulo(ModuloSistema m, bool liberado) => _mudar(
    permissoes.comModulo(
      m,
      liberado ? AcaoPermissao.values.toSet() : <AcaoPermissao>{},
    ),
  );

  void alternarEspecial(PermissaoEspecial e, bool liberada) =>
      _mudar(permissoes.comEspecial(e, liberada));

  void aplicarPerfil(PerfilAcesso p) {
    _perfilRascunho = p;
    _mudar(Permissoes.perfil(p));
  }

  void copiarDe(UsuarioSistema origem) => _mudar(origem.permissoes);

  void descartar() {
    _rascunho = selecionado?.permissoes;
    _perfilRascunho = null;
    alterado = false;
    notificar();
  }

  Future<bool> salvar() async {
    final u = selecionado;
    if (u == null) return false;
    final ok = await executar(
      () => _salvar(u, permissoes, perfil: _perfilRascunho),
    );
    if (ok) {
      alterado = false;
      _perfilRascunho = null;
    }
    return ok;
  }
}
