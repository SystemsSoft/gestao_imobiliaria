import '../../../../core/presentation/view_model.dart';
import '../../domain/entities/comissao_equipe.dart';
import '../../domain/entities/equipe_enums.dart';
import '../../domain/entities/usuario_sistema.dart';
import '../../domain/usecases/comissao_equipe_usecases.dart';
import '../../domain/usecases/usuario_usecases.dart';

/// Gestão de comissões de corretagem da equipe.
class ComissoesEquipeViewModel extends ViewModel {
  ComissoesEquipeViewModel(
    ObservarLancamentosComissao observarLancamentos,
    ObservarRegrasComissao observarRegras,
    ObservarUsuarios observarUsuarios,
    ObservarUsuarioAtual observarAtual,
    this._salvarRegra,
    this._salvarLancamento,
    this._alterarStatus,
    this._remover,
    this._resumir, {
    DateTime Function()? agora,
  }) : _agora = agora ?? DateTime.now {
    mes = DateTime(_agora().year, _agora().month);
    observar(observarLancamentos(), (l) {
      _lancamentos = l;
      carregado = true;
    });
    observar(observarRegras(), (l) => regras = l);
    observar(observarUsuarios(), (l) => _usuarios = l);
    observar(observarAtual(), (id) => usuarioAtualId = id);
  }

  final SalvarRegraComissao _salvarRegra;
  final SalvarLancamentoComissao _salvarLancamento;
  final AlterarStatusComissao _alterarStatus;
  final RemoverLancamentoComissao _remover;
  final ResumirComissoes _resumir;
  final DateTime Function() _agora;

  List<LancamentoComissao> _lancamentos = const [];
  List<UsuarioSistema> _usuarios = const [];
  List<RegraComissao> regras = const [];
  String? usuarioAtualId;
  bool carregado = false;
  late DateTime mes;
  StatusComissao? status;
  String? corretorId;

  DateTime get hoje => _agora();

  UsuarioSistema? get atual =>
      _usuarios.where((u) => u.id == usuarioAtualId).firstOrNull;

  /// Quem não tem a permissão vê só as próprias comissões.
  bool get veTodos =>
      atual?.permissoes.temEspecial(PermissaoEspecial.verComissoesDeTodos) ??
      false;

  List<UsuarioSistema> get corretores {
    final l = _usuarios
        .where((u) => u.ativo && (veTodos || u.id == usuarioAtualId))
        .toList();
    return l..sort((a, b) => a.nome.compareTo(b.nome));
  }

  String nome(String id) =>
      _usuarios.where((u) => u.id == id).firstOrNull?.nome ??
      'Usuário removido';

  RegraComissao regra(String usuarioId) =>
      regras.where((r) => r.usuarioId == usuarioId).firstOrNull ??
      RegraComissao(usuarioId: usuarioId);

  List<LancamentoComissao> get _visiveis => _lancamentos
      .where((l) => veTodos || l.usuarioId == usuarioAtualId)
      .toList();

  List<ResumoCorretor> get ranking => _resumir(
    lancamentos: _visiveis,
    regras: regras,
    competencia: mes,
    usuarios: corretores.map((u) => u.id),
  );

  List<LancamentoComissao> get lancamentos =>
      _visiveis
          .where(
            (l) =>
                l.competencia == mes &&
                (status == null || l.status == status) &&
                (corretorId == null || l.usuarioId == corretorId),
          )
          .toList()
        ..sort((a, b) => b.valor.compareTo(a.valor));

  double _soma(StatusComissao s) => _visiveis
      .where((l) => l.competencia == mes && l.status == s)
      .fold(0, (a, l) => a + l.valor);

  double get totalAprovar => _soma(StatusComissao.pendente);
  double get totalPagar => _soma(StatusComissao.aprovada);
  double get totalPago => _soma(StatusComissao.paga);

  void mudarMes(DateTime m) {
    mes = DateTime(m.year, m.month);
    notificar();
  }

  void filtrarStatus(StatusComissao? s) {
    status = s;
    notificar();
  }

  void filtrarCorretor(String? id) {
    corretorId = id;
    notificar();
  }

  Future<bool> salvarRegra(RegraComissao r) => executar(() => _salvarRegra(r));

  Future<bool> salvarLancamento(LancamentoComissao l) => executar(() async {
    await _salvarLancamento(l);
  });

  Future<bool> aprovar(LancamentoComissao l) =>
      executar(() => _alterarStatus(l, StatusComissao.aprovada));
  Future<bool> pagar(LancamentoComissao l) =>
      executar(() => _alterarStatus(l, StatusComissao.paga));
  Future<bool> estornar(LancamentoComissao l) =>
      executar(() => _alterarStatus(l, StatusComissao.aprovada));
  Future<bool> cancelar(LancamentoComissao l) =>
      executar(() => _alterarStatus(l, StatusComissao.cancelada));
  Future<bool> reabrir(LancamentoComissao l) =>
      executar(() => _alterarStatus(l, StatusComissao.pendente));
  Future<bool> remover(LancamentoComissao l) => executar(() => _remover(l));
}
