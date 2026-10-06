import 'equipe_enums.dart';

/// Percentuais de comissão de um corretor.
class RegraComissao {
  const RegraComissao({
    required this.usuarioId,
    this.percentualVenda = 30,
    this.percentualLocacao = 50,
    this.percentualCaptacao = 10,
    this.metaMensal = 0,
  });

  final String usuarioId;

  /// % da comissão da imobiliária que cabe ao corretor, por tipo.
  final double percentualVenda;
  final double percentualLocacao;
  final double percentualCaptacao;

  /// Meta mensal de comissões (R$); zero = sem meta.
  final double metaMensal;

  double percentualDe(TipoComissao t) => switch (t) {
    TipoComissao.venda => percentualVenda,
    TipoComissao.locacao => percentualLocacao,
    TipoComissao.captacao => percentualCaptacao,
    _ => 0,
  };
}

class LancamentoComissao {
  const LancamentoComissao({
    required this.id,
    required this.usuarioId,
    required this.tipo,
    required this.competencia,
    required this.valor,
    this.referencia = '',
    this.baseValor = 0,
    this.percentual = 0,
    this.observacao = '',
    this.status = StatusComissao.pendente,
    this.dataPagamento,
  });

  final String id;
  final String usuarioId;
  final TipoComissao tipo;

  /// Primeiro dia do mês de competência.
  final DateTime competencia;
  final double valor;

  /// Contrato, venda ou captação que originou a comissão (ex.: VEN-0001).
  final String referencia;

  /// Comissão da imobiliária sobre a qual o percentual incide.
  final double baseValor;
  final double percentual;
  final String observacao;
  final StatusComissao status;
  final DateTime? dataPagamento;

  LancamentoComissao copyWith({
    StatusComissao? status,
    DateTime? dataPagamento,
    bool limparPagamento = false,
  }) => LancamentoComissao(
    id: id,
    usuarioId: usuarioId,
    tipo: tipo,
    competencia: competencia,
    valor: valor,
    referencia: referencia,
    baseValor: baseValor,
    percentual: percentual,
    observacao: observacao,
    status: status ?? this.status,
    dataPagamento: limparPagamento
        ? null
        : (dataPagamento ?? this.dataPagamento),
  );
}

/// Comissões de um corretor em um mês.
class ResumoCorretor {
  const ResumoCorretor({
    required this.usuarioId,
    required this.aprovar,
    required this.pagar,
    required this.pago,
    required this.meta,
  });

  final String usuarioId;
  final double aprovar;
  final double pagar;
  final double pago;
  final double meta;

  double get total => aprovar + pagar + pago;
  double get progressoMeta => meta <= 0 ? 0 : total / meta;
}
