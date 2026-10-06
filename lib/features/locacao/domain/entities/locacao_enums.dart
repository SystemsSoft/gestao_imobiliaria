enum FinalidadeLocacao {
  residencial('Residencial'),
  comercial('Comercial');

  const FinalidadeLocacao(this.label);
  final String label;
}

enum GarantiaLocacao {
  fiador('Fiador'),
  caucao('Caução'),
  seguroFianca('Seguro-fiança'),
  tituloCapitalizacao('Título de capitalização'),
  semGarantia('Sem garantia');

  const GarantiaLocacao(this.label);
  final String label;
}

enum IndiceReajuste {
  igpm('IGP-M (FGV)'),
  ipca('IPCA (IBGE)'),
  inpc('INPC (IBGE)'),
  ivar('IVAR (FGV)');

  const IndiceReajuste(this.label);
  final String label;
}

enum StatusContrato {
  ativo('Ativo'),
  encerrado('Encerrado'),
  rescindido('Rescindido');

  const StatusContrato(this.label);
  final String label;
}

enum NaturezaDespesa {
  fixa('Fixa (mensal)'),
  extraordinaria('Extraordinária');

  const NaturezaDespesa(this.label);
  final String label;
}

enum ResponsavelDespesa {
  locatario('Locatário', 'cobrada no boleto'),
  proprietario('Proprietário', 'descontada no repasse');

  const ResponsavelDespesa(this.label, this.efeito);
  final String label;
  final String efeito;
}

enum TipoItemCobranca { aluguel, despesa, outro }

enum StatusCobranca {
  aberta('Em aberto'),
  paga('Paga'),
  cancelada('Cancelada');

  const StatusCobranca(this.label);
  final String label;
}

/// Primeiro dia do mês: usado como competência (mês/ano de referência).
DateTime competenciaDe(DateTime d) => DateTime(d.year, d.month);

String competenciaLabel(DateTime c) =>
    '${c.month.toString().padLeft(2, '0')}/${c.year}';

double arredondar(double v) => (v * 100).roundToDouble() / 100;
