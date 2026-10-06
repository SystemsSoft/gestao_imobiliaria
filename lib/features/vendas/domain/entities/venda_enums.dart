enum FormaPagamento {
  aVista('À vista'),
  financiamentoBancario('Financiamento bancário'),
  financiamentoProprio('Financiamento próprio');

  const FormaPagamento(this.label);
  final String label;
}

enum SistemaAmortizacao {
  price('Tabela Price', 'parcelas fixas'),
  sac('SAC', 'amortização constante, parcelas decrescentes'),
  semJuros('Sem juros', 'parcelas iguais, sem juros');

  const SistemaAmortizacao(this.label, this.descricao);
  final String label;
  final String descricao;
}

enum StatusVenda {
  ativa('Em andamento'),
  quitada('Quitada'),
  distratada('Distratada');

  const StatusVenda(this.label);
  final String label;
}

enum StatusParcela {
  aberta('Em aberto'),
  paga('Paga'),
  cancelada('Cancelada');

  const StatusParcela(this.label);
  final String label;
}

enum TipoParcela {
  entrada('Entrada'),
  mensal('Parcela');

  const TipoParcela(this.label);
  final String label;
}

/// Quem recebe as parcelas do financiamento próprio.
enum CredorParcelas {
  vendedor('Vendedor(es)'),
  imobiliaria('Imobiliária');

  const CredorParcelas(this.label);
  final String label;
}

double arredondar(double v) => (v * 100).roundToDouble() / 100;
