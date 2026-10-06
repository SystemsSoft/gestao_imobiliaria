import '../../../../core/config/empresa_info.dart';
import '../../../../core/utils/extenso.dart';
import '../../../../core/utils/formatters.dart';
import '../../../contratos/domain/entities/contrato_documento.dart';
import '../../../contratos/domain/entities/modelo_contrato.dart';
import '../../../contratos/domain/usecases/modelo_usecases.dart';
import '../../../contratos/domain/usecases/qualificacao.dart';
import '../../../crm/domain/entities/contato.dart';
import '../../../crm/domain/entities/imovel.dart';
import '../entities/venda.dart';
import '../entities/venda_enums.dart';
import '../services/calculadora_financiamento.dart';

/// Texto das condições de pagamento usado no contrato.
String condicoesPagamento(
  Venda v, [
  CalculadoraFinanciamento calc = const CalculadoraFinanciamento(),
]) {
  String m(double x) => '${formatMoney(x)} (${valorPorExtenso(x)})';
  final entrada = v.valorEntrada > 0
      ? 'a) ${m(v.valorEntrada)} a título de entrada/sinal, pagos em '
            '${formatDate(v.vencimentoEntrada ?? v.dataVenda)}; '
      : '';
  final b = v.valorEntrada > 0 ? 'b) ' : '';
  switch (v.formaPagamento) {
    case FormaPagamento.aVista:
      return v.valorEntrada > 0
          ? '$entrada${b}o saldo de ${m(v.valorFinanciado)} à vista, na assinatura da escritura.'
          : 'à vista, no ato da assinatura deste instrumento.';
    case FormaPagamento.financiamentoBancario:
      return '$entrada${b}o saldo de ${m(v.valorFinanciado)} por meio de '
          'financiamento bancário a ser obtido pelo(s) COMPRADOR(ES), cuja '
          'aprovação é condição para a conclusão do negócio.';
    case FormaPagamento.financiamentoProprio:
      final p = v.plano!;
      final tabela = calc.calcular(v.valorFinanciado, p);
      final parcela = tabela.isEmpty ? 0.0 : tabela.first.valor;
      final juros = p.sistema == SistemaAmortizacao.semJuros
          ? 'sem incidência de juros'
          : 'com juros de ${decimalToText(p.taxaJurosMes)}% ao mês pelo '
                'sistema ${p.sistema.label} (${p.sistema.descricao})';
      final valorParcela = p.sistema == SistemaAmortizacao.sac
          ? 'a primeira no valor de ${m(parcela)}'
          : 'no valor de ${m(parcela)} cada';
      return '$entrada${b}o saldo de ${m(v.valorFinanciado)} em '
          '${p.numeroParcelas} parcelas mensais e sucessivas, $valorParcela, '
          '$juros, vencendo a primeira em ${formatDate(p.primeiroVencimento)} '
          'e as demais no mesmo dia dos meses subsequentes.';
  }
}

/// Preenche um modelo de compra e venda com os dados da venda.
class MontarContratoVenda {
  const MontarContratoVenda([
    this._preencher = const PreencherModelo(),
    this._calc = const CalculadoraFinanciamento(),
  ]);
  final PreencherModelo _preencher;
  final CalculadoraFinanciamento _calc;

  ContratoDocumento call({
    required ModeloContrato modelo,
    required Venda venda,
    required Contato? Function(String id) contato,
    required Imovel? imovel,
    DateTime? data,
  }) {
    final vendedores = [
      for (final p in venda.vendedores) ?contato(p.contatoId!),
    ];
    final compradores = [for (final id in venda.compradores) ?contato(id)];
    final plano = venda.plano;
    final tabela = plano == null || !venda.financiamentoProprio
        ? const <ParcelaPlano>[]
        : _calc.calcular(venda.valorFinanciado, plano);
    final credor = venda.credor == CredorParcelas.imobiliaria
        ? '${EmpresaInfo.nome}, ${EmpresaInfo.creci}'
        : vendedores.map((c) => c.nome).join(', ');

    return _preencher(
      modelo: modelo,
      valores: {
        'numero_contrato': venda.numero,
        'vendedor_nome': vendedores.map((c) => c.nome).join(', '),
        'vendedor_qualificacao': vendedores.map(qualificacaoContato).join('; '),
        'comprador_nome': compradores.map((c) => c.nome).join(', '),
        'comprador_qualificacao': compradores
            .map(qualificacaoContato)
            .join('; '),
        'imovel_tipo': imovel?.tipo.label ?? '',
        'imovel_endereco': imovel == null ? '' : enderecoCompleto(imovel),
        'imovel_matricula': (imovel?.matricula.isEmpty ?? true)
            ? '—'
            : imovel!.matricula,
        'imovel_inscricao': (imovel?.inscricaoMunicipal.isEmpty ?? true)
            ? '—'
            : imovel!.inscricaoMunicipal,
        'data_venda': formatDate(venda.dataVenda),
        'valor_venda': moneyToText(venda.valorVenda),
        'valor_venda_extenso': valorPorExtenso(venda.valorVenda),
        'valor_entrada': moneyToText(venda.valorEntrada),
        'valor_entrada_extenso': valorPorExtenso(venda.valorEntrada),
        'forma_pagamento': venda.formaPagamento.label,
        'condicoes_pagamento': condicoesPagamento(venda, _calc),
        'valor_financiado': moneyToText(venda.valorFinanciado),
        'numero_parcelas': '${plano?.numeroParcelas ?? 0}',
        'valor_parcela': tabela.isEmpty ? '—' : moneyToText(tabela.first.valor),
        'taxa_juros': decimalToText(plano?.taxaJurosMes ?? 0),
        'sistema_amortizacao': plano?.sistema.label ?? '—',
        'primeiro_vencimento': formatDate(plano?.primeiroVencimento),
        'credor': credor,
        'multa_atraso': decimalToText(venda.multaAtraso),
        'juros_mes': decimalToText(venda.jurosMes),
        'comissao_percentual': decimalToText(venda.comissaoPercentual),
        'clausulas_adicionais': venda.clausulasAdicionais.isEmpty
            ? 'Não há.'
            : venda.clausulasAdicionais,
        'empresa_nome': EmpresaInfo.nome,
        'empresa_creci': EmpresaInfo.creci,
        'cidade_data': cidadeData(imovel?.cidade ?? '', data ?? DateTime.now()),
      },
      assinaturas: [
        for (final c in vendedores) 'VENDEDOR: ${c.nome}',
        for (final c in compradores) 'COMPRADOR: ${c.nome}',
        'INTERVENIENTE: ${EmpresaInfo.nome}',
        'TESTEMUNHA 1',
        'TESTEMUNHA 2',
      ],
    );
  }
}
