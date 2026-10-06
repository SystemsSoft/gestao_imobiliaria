import '../../../../core/errors/domain_exception.dart';
import '../entities/contrato_locacao.dart';
import '../repositories/cobranca_repository.dart';
import '../repositories/contrato_locacao_repository.dart';
import '../repositories/despesa_repository.dart';

class ObservarContratos {
  const ObservarContratos(this._repo);
  final ContratoLocacaoRepository _repo;

  Stream<List<ContratoLocacao>> call() => _repo.observar();
}

/// Valida e salva o contrato; contratos novos recebem número sequencial.
class SalvarContrato {
  const SalvarContrato(this._repo);
  final ContratoLocacaoRepository _repo;

  Future<ContratoLocacao> call(ContratoLocacao c) async {
    if (c.imovelId.isEmpty) throw const DomainException('Selecione o imóvel.');
    if (c.locatarioId.isEmpty) {
      throw const DomainException('Selecione o locatário.');
    }
    if (c.valorAluguel <= 0) {
      throw const DomainException('Informe o valor do aluguel.');
    }
    if (c.prazoMeses <= 0) throw const DomainException('Informe o prazo.');
    if (c.diaVencimento < 1 || c.diaVencimento > 31) {
      throw const DomainException('Dia de vencimento deve ser de 1 a 31.');
    }
    if (c.beneficiarios.isEmpty) {
      throw const DomainException('Informe ao menos um beneficiário.');
    }
    final soma = c.beneficiarios.fold<double>(0, (s, b) => s + b.percentual);
    if ((soma - 100).abs() > 0.01) {
      throw DomainException(
        'Os percentuais dos beneficiários somam ${soma.toStringAsFixed(2)}%; '
        'devem somar 100%.',
      );
    }
    if (c.beneficiarios.any((b) => b.contatoId == c.locatarioId)) {
      throw const DomainException(
        'O locatário não pode ser beneficiário do próprio contrato.',
      );
    }
    final salvo = c.numero.isEmpty
        ? c.copyWith(numero: await _repo.proximoNumero())
        : c;
    await _repo.salvar(salvo);
    return salvo;
  }
}

/// Remove o contrato com suas despesas e cobranças.
class RemoverContrato {
  const RemoverContrato(this._repo, this._despesas, this._cobrancas);
  final ContratoLocacaoRepository _repo;
  final DespesaRepository _despesas;
  final CobrancaRepository _cobrancas;

  Future<void> call(String id) async {
    await _despesas.removerDoContrato(id);
    await _cobrancas.removerDoContrato(id);
    await _repo.remover(id);
  }
}
