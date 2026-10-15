import '../../../../core/api/json.dart';
import '../../domain/entities/parcela.dart';
import '../../domain/entities/venda.dart';
import '../../domain/entities/venda_enums.dart';

Map<String, Object?> _participacaoParaJson(Participacao p) => {
  'contatoId': p.contatoId,
  'percentual': p.percentual,
  'pagaEm': escreverData(p.pagaEm),
};

Participacao _participacaoDeJson(Map<String, dynamic> j) => Participacao(
  contatoId: j['contatoId'] as String?,
  percentual: lerDouble(j['percentual']) ?? 0,
  pagaEm: lerData(j['pagaEm']),
);

// ------------------------------------------------------------------ Venda

Map<String, Object?> vendaParaJson(Venda v) => {
  'imovelId': v.imovelId,
  'compradores': v.compradores,
  'vendedores': [for (final p in v.vendedores) _participacaoParaJson(p)],
  'dataVenda': escreverData(v.dataVenda),
  'valorVenda': v.valorVenda,
  'valorEntrada': v.valorEntrada,
  'vencimentoEntrada': escreverData(v.vencimentoEntrada),
  'formaPagamento': v.formaPagamento.name,
  'plano': v.plano == null
      ? null
      : {
          'numeroParcelas': v.plano!.numeroParcelas,
          'taxaJurosMes': v.plano!.taxaJurosMes,
          'sistema': v.plano!.sistema.name,
          'primeiroVencimento': escreverData(v.plano!.primeiroVencimento),
        },
  'credor': v.credor.name,
  'multaAtraso': v.multaAtraso,
  'jurosMes': v.jurosMes,
  'comissaoPercentual': v.comissaoPercentual,
  'corretores': [for (final p in v.corretores) _participacaoParaJson(p)],
  'status': v.status.name,
  'clausulasAdicionais': v.clausulasAdicionais,
  'observacoes': v.observacoes,
};

Venda vendaDeJson(Map<String, dynamic> j) {
  final plano = j['plano'] as Map<String, dynamic>?;
  return Venda(
    id: j['id'] as String,
    numero: lerTexto(j['numero']),
    imovelId: lerTexto(j['imovelId']),
    compradores: ((j['compradores'] as List?) ?? const []).cast<String>(),
    vendedores: [
      for (final p in (j['vendedores'] as List?) ?? const [])
        _participacaoDeJson(p as Map<String, dynamic>),
    ],
    dataVenda: lerData(j['dataVenda'])!,
    valorVenda: lerDouble(j['valorVenda']) ?? 0,
    valorEntrada: lerDouble(j['valorEntrada']) ?? 0,
    vencimentoEntrada: lerData(j['vencimentoEntrada']),
    formaPagamento: lerEnum(
      FormaPagamento.values,
      j['formaPagamento'],
      FormaPagamento.aVista,
    ),
    plano: plano == null
        ? null
        : PlanoFinanciamento(
            numeroParcelas: lerInt(plano['numeroParcelas']),
            taxaJurosMes: lerDouble(plano['taxaJurosMes']) ?? 0,
            sistema: lerEnum(
              SistemaAmortizacao.values,
              plano['sistema'],
              SistemaAmortizacao.price,
            ),
            primeiroVencimento: lerData(plano['primeiroVencimento'])!,
          ),
    credor: lerEnum(
      CredorParcelas.values,
      j['credor'],
      CredorParcelas.vendedor,
    ),
    multaAtraso: lerDouble(j['multaAtraso']) ?? 0,
    jurosMes: lerDouble(j['jurosMes']) ?? 0,
    comissaoPercentual: lerDouble(j['comissaoPercentual']) ?? 0,
    corretores: [
      for (final p in (j['corretores'] as List?) ?? const [])
        _participacaoDeJson(p as Map<String, dynamic>),
    ],
    status: lerEnum(StatusVenda.values, j['status'], StatusVenda.ativa),
    clausulasAdicionais: lerTexto(j['clausulasAdicionais']),
    observacoes: lerTexto(j['observacoes']),
  );
}

// ---------------------------------------------------------------- Parcela

Map<String, Object?> parcelaParaJson(Parcela p) => {
  'vendaId': p.vendaId,
  'numero': p.numero,
  'totalParcelas': p.totalParcelas,
  'tipo': p.tipo.name,
  'vencimento': escreverData(p.vencimento),
  'valor': p.valor,
  'amortizacao': p.amortizacao,
  'juros': p.juros,
  'saldoDevedor': p.saldoDevedor,
  'status': p.status.name,
  'dataPagamento': escreverData(p.dataPagamento),
  'valorPago': p.valorPago,
  'multa': p.multa,
  'jurosMora': p.jurosMora,
  'desconto': p.desconto,
};

Parcela parcelaDeJson(Map<String, dynamic> j) => Parcela(
  id: j['id'] as String,
  vendaId: lerTexto(j['vendaId']),
  numero: lerInt(j['numero']),
  totalParcelas: lerInt(j['totalParcelas']),
  tipo: lerEnum(TipoParcela.values, j['tipo'], TipoParcela.mensal),
  vencimento: lerData(j['vencimento'])!,
  valor: lerDouble(j['valor']) ?? 0,
  amortizacao: lerDouble(j['amortizacao']) ?? 0,
  juros: lerDouble(j['juros']) ?? 0,
  saldoDevedor: lerDouble(j['saldoDevedor']) ?? 0,
  status: lerEnum(StatusParcela.values, j['status'], StatusParcela.aberta),
  dataPagamento: lerData(j['dataPagamento']),
  valorPago: lerDouble(j['valorPago']),
  multa: lerDouble(j['multa']) ?? 0,
  jurosMora: lerDouble(j['jurosMora']) ?? 0,
  desconto: lerDouble(j['desconto']) ?? 0,
);
