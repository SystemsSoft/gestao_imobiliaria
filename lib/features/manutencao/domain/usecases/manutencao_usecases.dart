import '../../../../core/errors/domain_exception.dart';
import '../../../crm/domain/repositories/contato_repository.dart';
import '../../../crm/domain/repositories/imovel_repository.dart';
import '../entities/diario_documento.dart';
import '../entities/manutencao.dart';
import '../repositories/documentos_manutencao_gateway.dart';
import '../repositories/manutencao_repository.dart';

/// Pauta de manutenção de um módulo (locação ou venda).
class ObservarManutencoes {
  const ObservarManutencoes(this._repo);
  final ManutencaoRepository _repo;

  Stream<List<Manutencao>> call(ContextoManutencao contexto) => _repo
      .observar()
      .map((l) => l.where((m) => m.contexto == contexto).toList());
}

class SalvarManutencao {
  const SalvarManutencao(this._repo);
  final ManutencaoRepository _repo;

  Future<void> call(Manutencao m) {
    if (m.imovelId.isEmpty) throw const DomainException('Selecione o imóvel.');
    if (m.tipo == TipoManutencao.outros && m.tipoOutro.trim().isEmpty) {
      throw const DomainException('Informe qual o tipo de manutenção.');
    }
    if (m.descricao.trim().isEmpty) {
      throw const DomainException('Descreva a manutenção.');
    }
    // Mantém o diário e o vínculo com o contrato (chamado do inquilino) ao
    // editar os dados da pauta.
    final atual = _repo.porId(m.id);
    return _repo.salvar(
      atual == null
          ? m
          : m.copyWith(
              diario: atual.diario,
              contratoId: atual.contratoId,
              origem: atual.origem,
            ),
    );
  }
}

class RemoverManutencao {
  const RemoverManutencao(this._repo);
  final ManutencaoRepository _repo;

  Future<void> call(String id) => _repo.remover(id);
}

/// Inclui ou atualiza um lançamento no diário da manutenção.
class RegistrarDiario {
  const RegistrarDiario(this._repo);
  final ManutencaoRepository _repo;

  Future<void> call(String manutencaoId, RegistroDiario r) {
    final m = _repo.porId(manutencaoId);
    if (m == null) throw const DomainException('Manutenção não encontrada.');
    if (r.profissional.trim().isEmpty) {
      throw const DomainException('Informe o profissional.');
    }
    if (r.servico.trim().isEmpty) {
      throw const DomainException('Informe o serviço a ser executado.');
    }
    if (r.valorMaterial < 0 || r.valorMaoDeObra < 0 || r.valorTaxa < 0) {
      throw const DomainException('Os valores não podem ser negativos.');
    }
    final diario = [...m.diario.where((e) => e.id != r.id), r];
    // O primeiro lançamento tira a manutenção de "pendente".
    final status = m.status == StatusManutencao.pendente
        ? StatusManutencao.emAndamento
        : m.status;
    return _repo.salvar(m.copyWith(diario: diario, status: status));
  }
}

class RemoverRegistroDiario {
  const RemoverRegistroDiario(this._repo);
  final ManutencaoRepository _repo;

  Future<void> call(String manutencaoId, String registroId) async {
    final m = _repo.porId(manutencaoId);
    if (m == null) return;
    await _repo.salvar(
      m.copyWith(diario: m.diario.where((r) => r.id != registroId).toList()),
    );
  }
}

class AlterarStatusManutencao {
  const AlterarStatusManutencao(this._repo);
  final ManutencaoRepository _repo;

  Future<void> call(String manutencaoId, StatusManutencao status) async {
    final m = _repo.porId(manutencaoId);
    if (m == null) return;
    await _repo.salvar(m.copyWith(status: status));
  }
}

/// Emite o diário da manutenção em PDF.
class ImprimirDiarioManutencao {
  ImprimirDiarioManutencao(
    this._gateway,
    this._repo,
    this._imoveis,
    this._contatos, {
    DateTime Function()? agora,
  }) : _agora = agora ?? DateTime.now;

  final DocumentosManutencaoGateway _gateway;
  final ManutencaoRepository _repo;
  final ImovelRepository _imoveis;
  final ContatoRepository _contatos;
  final DateTime Function() _agora;

  Future<DiarioDocumento> montar(String manutencaoId) async {
    final m = _repo.porId(manutencaoId);
    if (m == null) throw const DomainException('Manutenção não encontrada.');
    if (m.diario.isEmpty) {
      throw const DomainException(
        'Registre ao menos um serviço no diário antes de gerar o PDF.',
      );
    }
    final imovel = await _imoveis.obter(m.imovelId);
    final proprietarioId = imovel?.proprietarioId;
    return DiarioDocumento(
      manutencao: m,
      imovel: imovel,
      proprietario: proprietarioId == null
          ? null
          : await _contatos.obter(proprietarioId),
      emitidoEm: _agora(),
    );
  }

  Future<void> call(String manutencaoId) async =>
      _gateway.imprimirDiario(await montar(manutencaoId));
}
