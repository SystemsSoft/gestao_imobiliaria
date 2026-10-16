import '../../../../core/arquivos/arquivo_repository.dart';
import '../../../../core/errors/domain_exception.dart';
import '../entities/enums.dart';
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
/// código sequencial de quem grava (servidor ou memória).
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
    return _repo.salvar(imovel);
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

/// Envia do computador uma foto, vídeo ou arquivo e devolve o anexo que
/// aponta para ele (link escolhido como tipo vira arquivo).
class EnviarAnexo {
  const EnviarAnexo(this._arquivos);
  final ArquivoRepository _arquivos;

  Future<Anexo> call(
    AnexoTipo tipo,
    ArquivoEscolhido arquivo, {
    String titulo = '',
  }) async {
    final (tipoFinal, categoria) = switch (tipo) {
      AnexoTipo.foto => (tipo, CategoriaArquivo.foto),
      AnexoTipo.video => (tipo, CategoriaArquivo.video),
      AnexoTipo.arquivo ||
      AnexoTipo.link => (AnexoTipo.arquivo, CategoriaArquivo.arquivo),
    };
    categoria.validar(arquivo.nome, arquivo.tamanho);
    final enviado = await _arquivos.enviar(
      bytes: await arquivo.ler(),
      nome: arquivo.nome,
      categoria: categoria,
    );
    final ponto = arquivo.nome.lastIndexOf('.');
    return Anexo(
      tipo: tipoFinal,
      titulo: titulo.trim().isNotEmpty
          ? titulo.trim()
          : ponto > 0
          ? arquivo.nome.substring(0, ponto)
          : arquivo.nome,
      url: enviado.referencia,
    );
  }
}
