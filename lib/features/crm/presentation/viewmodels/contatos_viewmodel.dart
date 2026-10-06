import '../../../../core/presentation/view_model.dart';
import '../../domain/entities/contato.dart';
import '../../domain/entities/enums.dart';
import '../../domain/usecases/contato_usecases.dart';

class ContatosViewModel extends ViewModel {
  ContatosViewModel(ObservarContatos observarContatos, this._remover) {
    observar(observarContatos(), (lista) {
      _todos = lista;
      carregado = true;
    });
  }

  final RemoverContato _remover;

  List<Contato> _todos = const [];
  bool carregado = false;
  String query = '';
  PapelContato? papel;

  bool get semCadastro => _todos.isEmpty;

  List<Contato> get filtrados {
    final q = query.trim().toLowerCase();
    final digits = q.replaceAll(RegExp(r'\D'), '');
    final lista = _todos.where((c) {
      if (papel != null && !c.papeis.contains(papel)) return false;
      if (q.isEmpty) return true;
      return c.nome.toLowerCase().contains(q) ||
          c.email.toLowerCase().contains(q) ||
          (digits.isNotEmpty &&
              [
                c.telefone,
                c.celular,
                c.documento,
              ].any((e) => e.replaceAll(RegExp(r'\D'), '').contains(digits)));
    }).toList();
    return lista
      ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
  }

  void buscar(String texto) {
    query = texto;
    notificar();
  }

  void filtrarPapel(PapelContato? p) {
    papel = p;
    notificar();
  }

  Future<void> remover(String id) => executar(() => _remover(id));
}
