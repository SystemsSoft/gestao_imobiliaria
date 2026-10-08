import '../../../../core/errors/domain_exception.dart';
import '../entities/imovel.dart';
import '../repositories/evento_repository.dart';
import '../repositories/imovel_repository.dart';

class ObservarImoveis {
  const ObservarImoveis(this._repo);
  final ImovelRepository _repo;

  Stream<List<Imovel>> call() => _repo.observar();
}

class ListarImoveis {
  const ListarImoveis(this._repo);
  final ImovelRepository _repo;

  Future<List<Imovel>> call() => _repo.listar();
}

/// Valida e salva o imóvel; imóveis novos (código vazio) recebem o próximo
/// código sequencial.
class SalvarImovel {
  const SalvarImovel(this._repo);
  final ImovelRepository _repo;

  Future<Imovel> call(Imovel imovel) async {
    if (imovel.titulo.trim().isEmpty) {
      throw const DomainException('Informe o título do imóvel.');
    }
    if (imovel.finalidades.isEmpty) {
      throw const DomainException('Selecione ao menos uma finalidade.');
    }
    final salvo = imovel.codigo.isEmpty
        ? imovel.copyWith(
            codigo: await _repo.proximoCodigo(),
            criadoEm: imovel.criadoEm ?? DateTime.now(),
          )
        : imovel;
    await _repo.salvar(salvo);
    return salvo;
  }
}

/// Remove o imóvel e desvincula os itens da agenda que apontavam para ele.
class RemoverImovel {
  const RemoverImovel(this._repo, this._eventos);
  final ImovelRepository _repo;
  final EventoRepository _eventos;

  Future<void> call(String id) async {
    await _repo.remover(id);
    for (final e in await _eventos.listar()) {
      if (e.imovelId == id) await _eventos.salvar(e.copyWith(semImovel: true));
    }
  }
}
