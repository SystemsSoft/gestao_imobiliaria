import '../../../../core/errors/domain_exception.dart';
import '../../../../core/utils/documentos.dart';
import '../../../crm/domain/entities/enums.dart';
import '../../../crm/domain/repositories/contato_repository.dart';
import '../../../locacao/domain/entities/documentos.dart';
import '../../../locacao/domain/repositories/cobranca_repository.dart';
import '../../../locacao/domain/repositories/contrato_locacao_repository.dart';
import '../../../locacao/domain/repositories/despesa_repository.dart';
import '../../../locacao/domain/usecases/imposto_renda.dart';
import '../../../locacao/domain/usecases/imprimir_documentos.dart';
import '../entities/declarante_dimob.dart';
import '../entities/dimob.dart';
import '../entities/ir_fiscal.dart';
import '../repositories/declarante_repository.dart';
import '../repositories/dimob_gateway.dart';
import '../services/dimob_csv.dart';

class ObservarDeclarante {
  const ObservarDeclarante(this._repo);
  final DeclaranteRepository _repo;

  Stream<DeclaranteDimob> call() => _repo.observar();
}

class SalvarDeclarante {
  const SalvarDeclarante(this._repo);
  final DeclaranteRepository _repo;

  Future<void> call(DeclaranteDimob d) {
    if (d.nome.trim().isEmpty) {
      throw const DomainException('Informe o nome do declarante.');
    }
    if (d.documento.isNotEmpty && !validarCpfCnpj(d.documento)) {
      throw const DomainException('CNPJ/CPF do declarante inválido.');
    }
    if (d.responsavelCpf.isNotEmpty && !validarCpf(d.responsavelCpf)) {
      throw const DomainException('CPF do responsável inválido.');
    }
    return _repo.salvar(d);
  }
}

class ImprimirConferenciaDimob {
  const ImprimirConferenciaDimob(this._gateway);
  final DimobGateway _gateway;

  Future<void> call(DeclaracaoDimob d) => _gateway.imprimirConferencia(d);
}

class GerarCsvDimob {
  const GerarCsvDimob([this._csv = const DimobCsv()]);
  final DimobCsv _csv;

  String call(DeclaracaoDimob d) => _csv.gerar(d);
}

/// Imposto de Renda sobre aluguéis de todos os beneficiários no ano e os
/// DARFs de carnê-leão a recolher.
class CalcularIrConsolidado {
  const CalcularIrConsolidado(
    this._contratos,
    this._cobrancas,
    this._despesas,
    this._contatos, [
    this._resumo = const CalcularResumoIrAnual(),
  ]);

  final ContratoLocacaoRepository _contratos;
  final CobrancaRepository _cobrancas;
  final DespesaRepository _despesas;
  final ContatoRepository _contatos;
  final CalcularResumoIrAnual _resumo;

  Future<({List<IrBeneficiario> beneficiarios, List<DarfCarneLeao> darfs})>
  call(int ano) async {
    final contratos = await _contratos.listar();
    final cobrancas = await _cobrancas.listar();
    final despesas = await _despesas.listar();
    final contatos = await _contatos.listar();
    bool pj(String id) =>
        contatos.where((c) => c.id == id).firstOrNull?.tipoPessoa ==
        TipoPessoa.juridica;

    final ids = {
      for (final k in contratos)
        for (final b in k.beneficiarios) b.contatoId,
    };
    final beneficiarios = <IrBeneficiario>[];
    final darfs = <DarfCarneLeao>[];
    for (final c in contatos.where((c) => ids.contains(c.id))) {
      final meses = _resumo(
        beneficiarioId: c.id,
        ano: ano,
        cobrancas: cobrancas,
        contratos: contratos,
        despesas: despesas,
        pessoaJuridica: pj,
      );
      final ir = IrBeneficiario(
        beneficiario: c,
        meses: meses,
        pessoaJuridica: pj(c.id),
      );
      beneficiarios.add(ir);
      if (ir.pessoaJuridica) continue;
      for (final m in meses.where((m) => m.impostoCarneLeao > 0)) {
        // Vence no último dia útil do mês seguinte ao do recebimento.
        final ref = DateTime(ano, m.mes + 1);
        darfs.add(
          DarfCarneLeao(
            beneficiario: c,
            mes: m.mes,
            ano: ano,
            valor: m.impostoCarneLeao,
            vencimento: ultimoDiaUtil(ref.year, ref.month),
          ),
        );
      }
    }
    beneficiarios.sort(
      (a, b) => a.beneficiario.nome.compareTo(b.beneficiario.nome),
    );
    darfs.sort((a, b) => a.vencimento.compareTo(b.vencimento));
    return (beneficiarios: beneficiarios, darfs: darfs);
  }
}

class ImprimirInformeIr {
  const ImprimirInformeIr(this._imprimir);
  final ImprimirInformeRendimentos _imprimir;

  Future<void> call(IrBeneficiario ir, int ano) => _imprimir(
    InformeRendimentos(
      beneficiario: ir.beneficiario,
      ano: ano,
      meses: ir.meses,
    ),
  );
}
