import 'declarante_dimob.dart';

enum GravidadePendencia {
  erro('Erro'),
  aviso('Aviso');

  const GravidadePendencia(this.label);
  final String label;
}

class PendenciaDimob {
  const PendenciaDimob(this.gravidade, this.referencia, this.mensagem);

  final GravidadePendencia gravidade;

  /// Contrato, venda ou "Declarante".
  final String referencia;
  final String mensagem;
}

class ParteDimob {
  const ParteDimob({
    required this.nome,
    required this.documento,
    this.percentual,
  });

  final String nome;
  final String documento;
  final double? percentual;
}

class ImovelDimob {
  const ImovelDimob({
    required this.descricao,
    required this.rural,
    this.logradouro = '',
    this.numero = '',
    this.complemento = '',
    this.bairro = '',
    this.cidade = '',
    this.uf = '',
    this.cep = '',
    this.matricula = '',
  });

  final String descricao;

  /// Imóvel rural (sítio, fazenda); os demais são urbanos.
  final bool rural;
  final String logradouro;
  final String numero;
  final String complemento;
  final String bairro;
  final String cidade;
  final String uf;
  final String cep;
  final String matricula;

  String get tipo => rural ? 'Rural' : 'Urbano';

  String get endereco => [
    [logradouro, numero].where((e) => e.isNotEmpty).join(', '),
    complemento,
    bairro,
    [cidade, uf].where((e) => e.isNotEmpty).join('/'),
    if (cep.isNotEmpty) 'CEP $cep',
  ].where((e) => e.isNotEmpty).join(', ');

  bool get enderecoCompleto =>
      logradouro.isNotEmpty && cidade.isNotEmpty && uf.isNotEmpty;
}

double _soma(List<double> v) => v.fold(0, (s, x) => s + x);

/// Contrato de locação com os valores recebidos mês a mês (índice 0 = janeiro).
class DimobLocacao {
  const DimobLocacao({
    required this.numero,
    required this.dataContrato,
    required this.locadores,
    required this.locatario,
    required this.imovel,
    required this.aluguel,
    required this.encargos,
    required this.comissao,
    required this.irrf,
  });

  final String numero;
  final DateTime dataContrato;
  final List<ParteDimob> locadores;
  final ParteDimob locatario;
  final ImovelDimob imovel;

  /// Aluguel recebido no mês (regime de caixa).
  final List<double> aluguel;

  /// Multa e juros de mora, menos descontos de pontualidade.
  final List<double> encargos;

  /// Taxa de administração e intermediação retidas pela imobiliária.
  final List<double> comissao;

  /// Imposto de Renda retido na fonte (locatário pessoa jurídica).
  final List<double> irrf;

  double get totalAluguel => _soma(aluguel);
  double get totalEncargos => _soma(encargos);
  double get totalComissao => _soma(comissao);
  double get totalIrrf => _soma(irrf);
  double get totalRecebido => totalAluguel + totalEncargos;
  bool get semRecebimento => totalRecebido == 0;
}

/// Venda com os valores recebidos mês a mês.
class DimobVenda {
  const DimobVenda({
    required this.numero,
    required this.dataContrato,
    required this.valorOperacao,
    required this.vendedores,
    required this.compradores,
    required this.imovel,
    required this.recebido,
    required this.presumido,
  });

  final String numero;
  final DateTime dataContrato;
  final double valorOperacao;
  final List<ParteDimob> vendedores;
  final List<ParteDimob> compradores;
  final ImovelDimob imovel;
  final List<double> recebido;

  /// Verdadeiro quando o recebimento foi presumido (venda à vista ou com
  /// financiamento bancário, sem parcelas controladas no sistema).
  final bool presumido;

  double get totalRecebido => _soma(recebido);
}

class DeclaracaoDimob {
  const DeclaracaoDimob({
    required this.ano,
    required this.declarante,
    required this.locacoes,
    required this.vendas,
    required this.pendencias,
  });

  /// Ano-calendário.
  final int ano;
  final DeclaranteDimob declarante;
  final List<DimobLocacao> locacoes;
  final List<DimobVenda> vendas;
  final List<PendenciaDimob> pendencias;

  bool get semMovimento => locacoes.isEmpty && vendas.isEmpty;

  int get erros =>
      pendencias.where((p) => p.gravidade == GravidadePendencia.erro).length;
  int get avisos =>
      pendencias.where((p) => p.gravidade == GravidadePendencia.aviso).length;

  /// Pronta para gerar: sem erros de preenchimento.
  bool get pronta => erros == 0;

  double get totalAluguel => locacoes.fold(0, (s, l) => s + l.totalAluguel);
  double get totalEncargos => locacoes.fold(0, (s, l) => s + l.totalEncargos);
  double get totalComissao => locacoes.fold(0, (s, l) => s + l.totalComissao);
  double get totalIrrf => locacoes.fold(0, (s, l) => s + l.totalIrrf);
  double get totalVendas => vendas.fold(0, (s, v) => s + v.totalRecebido);
}
