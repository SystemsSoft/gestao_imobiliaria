import '../../../../core/config/empresa_info.dart';

/// Dados de quem entrega a declaração (a imobiliária).
class DeclaranteDimob {
  /// Sem [nome], usa o da Personalização.
  DeclaranteDimob({
    this.documento = '',
    String? nome,
    this.responsavelNome = '',
    this.responsavelCpf = '',
    this.retificadora = false,
    this.numeroRecibo = '',
  }) : nome = nome ?? EmpresaInfo.nome;

  /// CNPJ ou CPF do declarante.
  final String documento;
  final String nome;
  final String responsavelNome;
  final String responsavelCpf;
  final bool retificadora;

  /// Número do recibo da declaração original, quando retificadora.
  final String numeroRecibo;
}
