import '../../../../core/presentation/view_model.dart';
import '../../domain/entities/atividade.dart';
import '../../domain/entities/equipe_enums.dart';
import '../../domain/entities/usuario_sistema.dart';
import '../../domain/usecases/usuario_usecases.dart';

/// Histórico de atividades dos usuários.
class AtividadesViewModel extends ViewModel {
  AtividadesViewModel(
    ObservarAtividades observarAtividades,
    ObservarUsuarios observarUsuarios,
  ) {
    observar(observarAtividades(), (l) {
      _todas = l;
      carregado = true;
    });
    observar(observarUsuarios(), (l) => usuarios = l);
  }

  List<Atividade> _todas = const [];
  List<UsuarioSistema> usuarios = const [];
  bool carregado = false;

  String? usuarioId;
  TipoAtividade? tipo;
  ModuloSistema? modulo;
  String query = '';

  /// Mês filtrado; nulo mostra todo o período.
  DateTime? mes;

  List<Atividade> get filtradas {
    final q = query.trim().toLowerCase();
    return _todas
        .where(
          (a) =>
              (usuarioId == null || a.usuarioId == usuarioId) &&
              (tipo == null || a.tipo == tipo) &&
              (modulo == null || a.modulo == modulo) &&
              (mes == null ||
                  (a.quando.year == mes!.year &&
                      a.quando.month == mes!.month)) &&
              (q.isEmpty ||
                  a.descricao.toLowerCase().contains(q) ||
                  nome(a.usuarioId).toLowerCase().contains(q)),
        )
        .toList()
      ..sort((a, b) => b.quando.compareTo(a.quando));
  }

  String nome(String id) =>
      usuarios.where((u) => u.id == id).firstOrNull?.nome ?? 'Usuário removido';

  /// Quantidade de ações por usuário no filtro atual.
  Map<String, int> get porUsuario {
    final m = <String, int>{};
    for (final a in filtradas) {
      m[a.usuarioId] = (m[a.usuarioId] ?? 0) + 1;
    }
    return m;
  }

  void filtrarUsuario(String? id) {
    usuarioId = id;
    notificar();
  }

  void filtrarTipo(TipoAtividade? t) {
    tipo = t;
    notificar();
  }

  void filtrarModulo(ModuloSistema? m) {
    modulo = m;
    notificar();
  }

  void filtrarMes(DateTime? m) {
    mes = m == null ? null : DateTime(m.year, m.month);
    notificar();
  }

  void buscar(String t) {
    query = t;
    notificar();
  }

  /// Texto do log em CSV para copiar.
  String csv() {
    final b = StringBuffer('data;usuario;tipo;modulo;descricao\n');
    for (final a in filtradas) {
      b.writeln(
        [
          a.quando.toIso8601String(),
          nome(a.usuarioId),
          a.tipo.label,
          a.modulo?.label ?? '',
          a.descricao.replaceAll(';', ','),
        ].join(';'),
      );
    }
    return b.toString();
  }
}
