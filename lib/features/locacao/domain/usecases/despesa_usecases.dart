import '../../../../core/errors/domain_exception.dart';
import '../entities/despesa.dart';
import '../entities/locacao_enums.dart';
import '../repositories/despesa_repository.dart';

class ObservarDespesas {
  const ObservarDespesas(this._repo);
  final DespesaRepository _repo;

  Stream<List<Despesa>> call() => _repo.observar();
}

class SalvarDespesa {
  const SalvarDespesa(this._repo);
  final DespesaRepository _repo;

  Future<void> call(Despesa d) {
    if (d.contratoId.isEmpty) {
      throw const DomainException('Selecione o contrato.');
    }
    if (d.descricao.trim().isEmpty) {
      throw const DomainException('Informe a descrição.');
    }
    if (d.valor <= 0) throw const DomainException('Informe o valor.');
    final fim = d.competenciaFim;
    if (d.natureza == NaturezaDespesa.fixa &&
        fim != null &&
        competenciaDe(fim).isBefore(competenciaDe(d.competenciaInicio))) {
      throw const DomainException('O fim deve ser posterior ao início.');
    }
    return _repo.salvar(d);
  }
}

class RemoverDespesa {
  const RemoverDespesa(this._repo);
  final DespesaRepository _repo;

  Future<void> call(String id) => _repo.remover(id);
}
