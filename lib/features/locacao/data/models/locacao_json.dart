import '../../../../core/api/json.dart';
import '../../domain/entities/cobranca.dart';
import '../../domain/entities/contrato_locacao.dart';
import '../../domain/entities/despesa.dart';
import '../../domain/entities/locacao_enums.dart';

// ---------------------------------------------------------------- Contrato

Map<String, Object?> contratoParaJson(ContratoLocacao c) => {
  'imovelId': c.imovelId,
  'locatarioId': c.locatarioId,
  'fiadorId': c.fiadorId,
  'beneficiarios': [
    for (final b in c.beneficiarios)
      {'contatoId': b.contatoId, 'percentual': b.percentual},
  ],
  'finalidade': c.finalidade.name,
  'garantia': c.garantia.name,
  'valorGarantia': c.valorGarantia,
  'dataInicio': escreverData(c.dataInicio),
  'prazoMeses': c.prazoMeses,
  'diaVencimento': c.diaVencimento,
  'valorAluguel': c.valorAluguel,
  'taxaAdministracao': c.taxaAdministracao,
  'taxaIntermediacao': c.taxaIntermediacao,
  'indiceReajuste': c.indiceReajuste.name,
  'multaAtraso': c.multaAtraso,
  'jurosMes': c.jurosMes,
  'descontoPontualidade': c.descontoPontualidade,
  'status': c.status.name,
  'clausulasAdicionais': c.clausulasAdicionais,
  'observacoes': c.observacoes,
};

ContratoLocacao contratoDeJson(Map<String, dynamic> j) => ContratoLocacao(
  id: j['id'] as String,
  numero: lerTexto(j['numero']),
  imovelId: lerTexto(j['imovelId']),
  locatarioId: lerTexto(j['locatarioId']),
  fiadorId: j['fiadorId'] as String?,
  beneficiarios: [
    for (final b in (j['beneficiarios'] as List?) ?? const [])
      Beneficiario(
        contatoId: lerTexto(b['contatoId']),
        percentual: lerDouble(b['percentual']) ?? 0,
      ),
  ],
  finalidade: lerEnum(
    FinalidadeLocacao.values,
    j['finalidade'],
    FinalidadeLocacao.residencial,
  ),
  garantia: lerEnum(
    GarantiaLocacao.values,
    j['garantia'],
    GarantiaLocacao.semGarantia,
  ),
  valorGarantia: lerDouble(j['valorGarantia']),
  dataInicio: lerData(j['dataInicio'])!,
  prazoMeses: lerInt(j['prazoMeses'], 30),
  diaVencimento: lerInt(j['diaVencimento'], 10),
  valorAluguel: lerDouble(j['valorAluguel']) ?? 0,
  taxaAdministracao: lerDouble(j['taxaAdministracao']) ?? 0,
  taxaIntermediacao: lerDouble(j['taxaIntermediacao']) ?? 0,
  indiceReajuste: lerEnum(
    IndiceReajuste.values,
    j['indiceReajuste'],
    IndiceReajuste.igpm,
  ),
  multaAtraso: lerDouble(j['multaAtraso']) ?? 0,
  jurosMes: lerDouble(j['jurosMes']) ?? 0,
  descontoPontualidade: lerDouble(j['descontoPontualidade']) ?? 0,
  status: lerEnum(StatusContrato.values, j['status'], StatusContrato.ativo),
  clausulasAdicionais: lerTexto(j['clausulasAdicionais']),
  observacoes: lerTexto(j['observacoes']),
);

// ----------------------------------------------------------------- Despesa

Map<String, Object?> despesaParaJson(Despesa d) => {
  'contratoId': d.contratoId,
  'descricao': d.descricao,
  'valor': d.valor,
  'natureza': d.natureza.name,
  'responsavel': d.responsavel.name,
  'competenciaInicio': escreverData(d.competenciaInicio),
  'competenciaFim': escreverData(d.competenciaFim),
  'dedutivelIr': d.dedutivelIR,
};

Despesa despesaDeJson(Map<String, dynamic> j) => Despesa(
  id: j['id'] as String,
  contratoId: lerTexto(j['contratoId']),
  descricao: lerTexto(j['descricao']),
  valor: lerDouble(j['valor']) ?? 0,
  natureza: lerEnum(
    NaturezaDespesa.values,
    j['natureza'],
    NaturezaDespesa.fixa,
  ),
  responsavel: lerEnum(
    ResponsavelDespesa.values,
    j['responsavel'],
    ResponsavelDespesa.locatario,
  ),
  competenciaInicio: lerData(j['competenciaInicio'])!,
  competenciaFim: lerData(j['competenciaFim']),
  dedutivelIR: j['dedutivelIr'] as bool? ?? false,
);

// ---------------------------------------------------------------- Cobrança

Map<String, Object?> cobrancaParaJson(Cobranca c) => {
  'contratoId': c.contratoId,
  'competencia': escreverData(c.competencia),
  'vencimento': escreverData(c.vencimento),
  'itens': [
    for (final i in c.itens)
      {'descricao': i.descricao, 'valor': i.valor, 'tipo': i.tipo.name},
  ],
  'status': c.status.name,
  'dataPagamento': escreverData(c.dataPagamento),
  'valorPago': c.valorPago,
  'multa': c.multa,
  'juros': c.juros,
  'desconto': c.desconto,
};

Cobranca cobrancaDeJson(Map<String, dynamic> j) => Cobranca(
  id: j['id'] as String,
  contratoId: lerTexto(j['contratoId']),
  competencia: lerData(j['competencia'])!,
  vencimento: lerData(j['vencimento'])!,
  itens: [
    for (final i in (j['itens'] as List?) ?? const [])
      ItemCobranca(
        descricao: lerTexto(i['descricao']),
        valor: lerDouble(i['valor']) ?? 0,
        tipo: lerEnum(
          TipoItemCobranca.values,
          i['tipo'],
          TipoItemCobranca.outro,
        ),
      ),
  ],
  status: lerEnum(StatusCobranca.values, j['status'], StatusCobranca.aberta),
  dataPagamento: lerData(j['dataPagamento']),
  valorPago: lerDouble(j['valorPago']),
  multa: lerDouble(j['multa']) ?? 0,
  juros: lerDouble(j['juros']) ?? 0,
  desconto: lerDouble(j['desconto']) ?? 0,
);

// ---------------------------------------------------------------- Repasse

/// Repasse já feito a um beneficiário (cobrança + contato + data).
class RepasseRealizado {
  const RepasseRealizado(this.cobrancaId, this.contatoId, this.data);

  final String cobrancaId;
  final String contatoId;
  final DateTime data;

  factory RepasseRealizado.deJson(Map<String, dynamic> j) => RepasseRealizado(
    lerTexto(j['cobrancaId']),
    lerTexto(j['contatoId']),
    lerData(j['data'])!,
  );
}
