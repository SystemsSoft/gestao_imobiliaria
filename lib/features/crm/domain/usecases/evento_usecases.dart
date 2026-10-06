import '../../../../core/errors/domain_exception.dart';
import '../entities/enums.dart';
import '../entities/evento.dart';
import '../repositories/evento_repository.dart';

class ObservarEventos {
  const ObservarEventos(this._repo);
  final EventoRepository _repo;

  Stream<List<Evento>> call() => _repo.observar();
}

class SalvarEvento {
  const SalvarEvento(this._repo);
  final EventoRepository _repo;

  Future<void> call(Evento evento) {
    if (evento.titulo.trim().isEmpty) {
      throw const DomainException('Informe o título.');
    }
    if (evento.tipo != TipoEvento.anotacao && evento.dataHora == null) {
      throw const DomainException('Informe a data e hora.');
    }
    return _repo.salvar(evento);
  }
}

class RemoverEvento {
  const RemoverEvento(this._repo);
  final EventoRepository _repo;

  Future<void> call(String id) => _repo.remover(id);
}

class AlternarConclusaoEvento {
  const AlternarConclusaoEvento(this._repo);
  final EventoRepository _repo;

  Future<void> call(Evento evento) =>
      _repo.salvar(evento.copyWith(concluido: !evento.concluido));
}
