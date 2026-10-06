import '../../../../core/errors/domain_exception.dart';
import '../entities/contato.dart';
import '../repositories/contato_repository.dart';
import '../repositories/evento_repository.dart';

class ObservarContatos {
  const ObservarContatos(this._repo);
  final ContatoRepository _repo;

  Stream<List<Contato>> call() => _repo.observar();
}

class ListarContatos {
  const ListarContatos(this._repo);
  final ContatoRepository _repo;

  Future<List<Contato>> call() async {
    final lista = [...await _repo.listar()];
    return lista
      ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
  }
}

class SalvarContato {
  const SalvarContato(this._repo);
  final ContatoRepository _repo;

  Future<void> call(Contato contato) {
    if (contato.nome.trim().isEmpty) {
      throw const DomainException('Informe o nome do contato.');
    }
    final p = contato.perfil;
    if (p != null &&
        p.valorMin != null &&
        p.valorMax != null &&
        p.valorMin! > p.valorMax!) {
      throw const DomainException('O valor mínimo é maior que o máximo.');
    }
    return _repo.salvar(contato);
  }
}

/// Remove o contato e desvincula os itens da agenda que apontavam para ele.
class RemoverContato {
  const RemoverContato(this._repo, this._eventos);
  final ContatoRepository _repo;
  final EventoRepository _eventos;

  Future<void> call(String id) async {
    await _repo.remover(id);
    for (final e in await _eventos.listar()) {
      if (e.contatoId == id) {
        await _eventos.salvar(e.copyWith(semContato: true));
      }
    }
  }
}
