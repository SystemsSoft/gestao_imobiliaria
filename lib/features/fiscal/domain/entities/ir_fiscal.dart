import '../../../crm/domain/entities/contato.dart';
import '../../../locacao/domain/entities/ir_mensal.dart';

/// Imposto de Renda sobre aluguéis de um beneficiário no ano.
class IrBeneficiario {
  const IrBeneficiario({
    required this.beneficiario,
    required this.meses,
    required this.pessoaJuridica,
  });

  final Contato beneficiario;
  final List<IrMensal> meses;

  /// Pessoa jurídica: o aluguel entra na apuração da empresa.
  final bool pessoaJuridica;

  double _s(double Function(IrMensal) f) => meses.fold(0, (s, m) => s + f(m));

  double get bruto => _s((m) => m.rendimentoBruto);
  double get deducoes => _s((m) => m.deducoes);
  double get baseCarneLeao => _s((m) => m.baseCarneLeao);
  double get carneLeao => _s((m) => m.impostoCarneLeao);
  double get baseIrrf => _s((m) => m.baseIrrf);
  double get irrf => _s((m) => m.irrfRetido);
  bool get semMovimento => bruto == 0;
}

/// DARF do carnê-leão de um mês.
class DarfCarneLeao {
  const DarfCarneLeao({
    required this.beneficiario,
    required this.mes,
    required this.ano,
    required this.valor,
    required this.vencimento,
  });

  final Contato beneficiario;
  final int mes;
  final int ano;
  final double valor;
  final DateTime vencimento;

  /// Código de receita do carnê-leão.
  static const codigoReceita = '0190';
}
