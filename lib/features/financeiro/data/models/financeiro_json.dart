import '../../../../core/api/json.dart';
import '../../domain/entities/boleto_bancario.dart';
import '../../domain/entities/conta_bancaria.dart';
import '../../domain/entities/financeiro_enums.dart';
import '../../domain/entities/indice_mensal.dart';
import '../../domain/entities/lancamento.dart';
import '../../domain/entities/linha_extrato.dart';

// ---------------------------------------------------------- Conta bancária

Map<String, Object?> contaBancariaParaJson(ContaBancaria c) => {
  'nome': c.nome,
  'banco': c.banco,
  'agencia': c.agencia,
  'conta': c.conta,
  'saldoInicial': c.saldoInicial,
  'convenio': c.convenio,
  'carteira': c.carteira,
};

ContaBancaria contaBancariaDeJson(Map<String, dynamic> j) => ContaBancaria(
  id: j['id'] as String,
  nome: lerTexto(j['nome']),
  banco: lerTexto(j['banco']),
  agencia: lerTexto(j['agencia']),
  conta: lerTexto(j['conta']),
  saldoInicial: lerDouble(j['saldoInicial']) ?? 0,
  convenio: lerTexto(j['convenio']),
  carteira: lerTexto(j['carteira']),
);

// --------------------------------------------------------------- Lançamento

Map<String, Object?> lancamentoParaJson(Lancamento l) => {
  'tipo': l.tipo.name,
  'descricao': l.descricao,
  'categoria': l.categoria,
  'contatoId': l.contatoId,
  'documento': l.documento,
  'observacoes': l.observacoes,
  'valor': l.valor,
  'vencimento': escreverData(l.vencimento),
  'multaPercentual': l.multaPercentual,
  'jurosMesPercentual': l.jurosMesPercentual,
  'indice': l.indice.name,
  'status': l.status.name,
  'parcelaNumero': l.parcelaNumero,
  'parcelaTotal': l.parcelaTotal,
  'grupoId': l.grupoId,
  'dataBaixa': escreverData(l.dataBaixa),
  'valorBaixa': l.valorBaixa,
  'multa': l.multa,
  'juros': l.juros,
  'correcao': l.correcao,
  'desconto': l.desconto,
  'meio': l.meio?.name,
  'contaBaixaId': l.contaBaixaId,
};

Lancamento lancamentoDeJson(Map<String, dynamic> j) => Lancamento(
  id: j['id'] as String,
  tipo: lerEnum(TipoLancamento.values, j['tipo'], TipoLancamento.receber),
  descricao: lerTexto(j['descricao']),
  categoria: lerTexto(j['categoria']),
  contatoId: j['contatoId'] as String?,
  documento: lerTexto(j['documento']),
  observacoes: lerTexto(j['observacoes']),
  valor: lerDouble(j['valor']) ?? 0,
  vencimento: lerData(j['vencimento'])!,
  multaPercentual: lerDouble(j['multaPercentual']) ?? 0,
  jurosMesPercentual: lerDouble(j['jurosMesPercentual']) ?? 0,
  indice: lerEnum(IndiceMonetario.values, j['indice'], IndiceMonetario.nenhum),
  status: lerEnum(
    StatusLancamento.values,
    j['status'],
    StatusLancamento.aberto,
  ),
  parcelaNumero: lerInt(j['parcelaNumero'], 1),
  parcelaTotal: lerInt(j['parcelaTotal'], 1),
  grupoId: j['grupoId'] as String?,
  dataBaixa: lerData(j['dataBaixa']),
  valorBaixa: lerDouble(j['valorBaixa']),
  multa: lerDouble(j['multa']) ?? 0,
  juros: lerDouble(j['juros']) ?? 0,
  correcao: lerDouble(j['correcao']) ?? 0,
  desconto: lerDouble(j['desconto']) ?? 0,
  meio: MeioPagamento.values.asNameMap()[j['meio']],
  contaBaixaId: j['contaBaixaId'] as String?,
);

// ------------------------------------------------------------------ Extrato

Map<String, Object?> linhaExtratoParaJson(LinhaExtrato l) => {
  'contaId': l.contaId,
  'data': escreverData(l.data),
  'descricao': l.descricao,
  'valor': l.valor,
  'documento': l.documento,
  'lancamentoId': l.lancamentoId,
};

LinhaExtrato linhaExtratoDeJson(Map<String, dynamic> j) => LinhaExtrato(
  id: j['id'] as String,
  contaId: lerTexto(j['contaId']),
  data: lerData(j['data'])!,
  descricao: lerTexto(j['descricao']),
  valor: lerDouble(j['valor']) ?? 0,
  documento: lerTexto(j['documento']),
  lancamentoId: j['lancamentoId'] as String?,
);

// ------------------------------------------------------------------ Boleto

Map<String, Object?> boletoParaJson(BoletoBancario b) => {
  'lancamentoId': b.lancamentoId,
  'contaId': b.contaId,
  'nossoNumero': b.nossoNumero,
  'valor': b.valor,
  'vencimento': escreverData(b.vencimento),
  'emissao': escreverData(b.emissao),
  'status': b.status.name,
  'dataPagamento': escreverData(b.dataPagamento),
  'valorPago': b.valorPago,
};

BoletoBancario boletoDeJson(Map<String, dynamic> j) => BoletoBancario(
  id: j['id'] as String,
  lancamentoId: lerTexto(j['lancamentoId']),
  contaId: lerTexto(j['contaId']),
  nossoNumero: lerTexto(j['nossoNumero']),
  valor: lerDouble(j['valor']) ?? 0,
  vencimento: lerData(j['vencimento'])!,
  emissao: lerData(j['emissao'])!,
  status: lerEnum(StatusBoleto.values, j['status'], StatusBoleto.emitido),
  dataPagamento: lerData(j['dataPagamento']),
  valorPago: lerDouble(j['valorPago']),
);

// ------------------------------------------------- Índice e configuração

Map<String, Object?> indiceParaJson(IndiceMensal i) => {
  'indice': i.indice.name,
  'ano': i.ano,
  'mes': i.mes,
  'percentual': i.percentual,
};

IndiceMensal indiceDeJson(Map<String, dynamic> j) => IndiceMensal(
  indice: lerEnum(IndiceMonetario.values, j['indice'], IndiceMonetario.nenhum),
  ano: lerInt(j['ano']),
  mes: lerInt(j['mes']),
  percentual: lerDouble(j['percentual']) ?? 0,
);

Map<String, Object?> configuracaoParaJson(ConfiguracaoFinanceira c) => {
  'multaPercentual': c.multaPercentual,
  'jurosMesPercentual': c.jurosMesPercentual,
  'indicePadrao': c.indicePadrao.name,
  'linkBanco': c.linkBanco,
};

ConfiguracaoFinanceira configuracaoDeJson(Map<String, dynamic> j) =>
    ConfiguracaoFinanceira(
      multaPercentual: lerDouble(j['multaPercentual']) ?? 2,
      jurosMesPercentual: lerDouble(j['jurosMesPercentual']) ?? 1,
      indicePadrao: lerEnum(
        IndiceMonetario.values,
        j['indicePadrao'],
        IndiceMonetario.nenhum,
      ),
      linkBanco: lerTexto(j['linkBanco']),
    );
