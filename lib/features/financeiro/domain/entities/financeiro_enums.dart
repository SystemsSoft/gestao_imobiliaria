enum TipoLancamento {
  receber('A receber', 'Recebido', 'Receita', 1),
  pagar('A pagar', 'Pago', 'Despesa', -1);

  const TipoLancamento(
    this.label,
    this.baixadoLabel,
    this.natureza,
    this.sinal,
  );
  final String label;
  final String baixadoLabel;
  final String natureza;

  /// +1 para entradas, −1 para saídas.
  final int sinal;
}

enum StatusLancamento {
  aberto('Em aberto'),
  baixado('Baixado'),
  cancelado('Cancelado');

  const StatusLancamento(this.label);
  final String label;
}

enum MeioPagamento {
  pix('PIX'),
  boleto('Boleto'),
  transferencia('Transferência'),
  dinheiro('Dinheiro'),
  cartao('Cartão'),
  cheque('Cheque');

  const MeioPagamento(this.label);
  final String label;
}

enum IndiceMonetario {
  nenhum('Sem atualização'),
  igpm('IGP-M'),
  ipca('IPCA'),
  inpc('INPC');

  const IndiceMonetario(this.label);
  final String label;
}

enum StatusBoleto {
  emitido('Emitido'),
  pago('Pago'),
  cancelado('Cancelado');

  const StatusBoleto(this.label);
  final String label;
}

double arredondar(double v) => (v * 100).roundToDouble() / 100;

DateTime soData(DateTime d) => DateTime(d.year, d.month, d.day);

/// Categorias sugeridas ao lançar contas.
const categoriasReceber = [
  'Aluguel',
  'Comissão de venda',
  'Parcela de venda',
  'Taxa de administração',
  'Temporada',
  'Outras receitas',
];

const categoriasPagar = [
  'Condomínio',
  'IPTU',
  'Salários e encargos',
  'Impostos e taxas',
  'Marketing',
  'Manutenção',
  'Energia, água e internet',
  'Repasse a proprietário',
  'Comissão a corretor',
  'Outras despesas',
];
