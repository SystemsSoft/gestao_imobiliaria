import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/config/empresa_info.dart';
import '../../../../core/pdf/pdf_kit.dart';
import '../../../../core/utils/extenso.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/competencia_selector.dart';
import '../../domain/entities/documentos.dart';
import '../../domain/entities/locacao_enums.dart';
import '../../domain/repositories/documentos_locacao_gateway.dart';

const _direita = pw.Alignment.centerRight;

/// Gera os documentos da locação em PDF e abre a impressão.
class PdfDocumentosLocacaoGateway implements DocumentosLocacaoGateway {
  @override
  Future<void> imprimirContrato(ContratoDocumento d) =>
      PdfKit.imprimir(d.titulo, () => gerarContrato(d));

  @override
  Future<void> imprimirBoleto(CobrancaDocumento d) => PdfKit.imprimir(
    'Boleto ${d.contrato.numero} ${competenciaLabel(d.cobranca.competencia)}',
    () => gerarBoleto(d),
  );

  @override
  Future<void> imprimirRecibo(CobrancaDocumento d) => PdfKit.imprimir(
    'Recibo ${d.contrato.numero} ${competenciaLabel(d.cobranca.competencia)}',
    () => gerarRecibo(d),
  );

  @override
  Future<void> imprimirDemonstrativo(DemonstrativoRepasse d) => PdfKit.imprimir(
    'Repasse ${d.beneficiario.nome} ${competenciaLabel(d.competencia)}',
    () => gerarDemonstrativo(d),
  );

  @override
  Future<void> imprimirInforme(InformeRendimentos i) => PdfKit.imprimir(
    'Informe ${i.beneficiario.nome} ${i.ano}',
    () => gerarInforme(i),
  );

  Future<pw.Document> _documento() async =>
      pw.Document(theme: await PdfKit.tema());

  Future<Uint8List> gerarContrato(ContratoDocumento d) async {
    final doc = await _documento();
    final logo = await PdfKit.logo();
    final paragrafos = d.texto
        .split(RegExp(r'\n\s*\n'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty);
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(48),
        header: (_) => PdfKit.cabecalho(logo, 'CONTRATO'),
        footer: (ctx) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Página ${ctx.pageNumber} de ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfKit.cinza),
          ),
        ),
        build: (_) => [
          pw.Center(
            child: pw.Text(
              d.titulo,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 16),
          for (final p in paragrafos)
            pw.Paragraph(
              text: p,
              textAlign: pw.TextAlign.justify,
              style: const pw.TextStyle(fontSize: 10.5, lineSpacing: 2),
            ),
          pw.Wrap(
            spacing: 24,
            children: [for (final a in d.assinaturas) PdfKit.assinatura(a)],
          ),
        ],
      ),
    );
    return doc.save();
  }

  List<List<String>> _itens(CobrancaDocumento d) => [
    for (final i in d.cobranca.itens) [i.descricao, formatMoney(i.valor)],
  ];

  String _endereco(CobrancaDocumento d) => d.imovel?.enderecoResumo ?? '';

  Future<Uint8List> gerarBoleto(CobrancaDocumento d) async {
    final doc = await _documento();
    final logo = await PdfKit.logo();
    final c = d.cobranca;
    final k = d.contrato;
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            PdfKit.cabecalho(logo, 'BOLETO DE ALUGUEL'),
            PdfKit.caixa(
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  PdfKit.rotuloValor(
                    'Beneficiário',
                    '${EmpresaInfo.nome} • ${EmpresaInfo.creci}',
                  ),
                  PdfKit.rotuloValor('Contrato', k.numero),
                  PdfKit.rotuloValor(
                    'Competência',
                    competenciaLabel(c.competencia),
                  ),
                ],
              ),
            ),
            PdfKit.caixa(
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  PdfKit.rotuloValor(
                    'Pagador',
                    [
                      d.locatario?.nome ?? '',
                      if (d.locatario?.documento.isNotEmpty ?? false)
                        d.locatario!.documento,
                    ].join(' • '),
                  ),
                  pw.SizedBox(height: 6),
                  PdfKit.rotuloValor('Imóvel', _endereco(d)),
                ],
              ),
            ),
            PdfKit.tabela(
              cabecalhos: ['Discriminação', 'Valor'],
              linhas: _itens(d),
              alinhamentos: {1: _direita},
            ),
            pw.SizedBox(height: 12),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                PdfKit.rotuloValor(
                  'Vencimento',
                  formatDate(c.vencimento),
                  destaque: true,
                ),
                PdfKit.rotuloValor(
                  'Valor do documento',
                  formatMoney(c.total),
                  destaque: true,
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              'Instruções',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Bullet(
              text: k.descontoPontualidade > 0
                  ? 'Até o vencimento, conceder desconto de ${formatMoney(k.descontoPontualidade)}.'
                  : 'Pagável até o vencimento sem acréscimos.',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.Bullet(
              text:
                  'Após o vencimento, cobrar multa de ${decimalToText(k.multaAtraso)}% '
                  'e juros de ${decimalToText(k.jurosMes)}% ao mês (pro rata die).',
              style: const pw.TextStyle(fontSize: 9),
            ),
            if (EmpresaInfo.chavePix.isNotEmpty)
              pw.Bullet(
                text: 'Pagamento também por PIX: ${EmpresaInfo.chavePix}',
                style: const pw.TextStyle(fontSize: 9),
              ),
            pw.Spacer(),
            pw.Divider(color: PdfKit.cinza, borderStyle: pw.BorderStyle.dashed),
            pw.Text(
              'Documento de cobrança emitido pela administradora, sem registro '
              'bancário e sem código de barras. A emissão de boleto registrado '
              'depende de integração com o banco.',
              style: const pw.TextStyle(fontSize: 8, color: PdfKit.cinza),
            ),
          ],
        ),
      ),
    );
    return doc.save();
  }

  Future<Uint8List> gerarRecibo(CobrancaDocumento d) async {
    final doc = await _documento();
    final logo = await PdfKit.logo();
    final c = d.cobranca;
    final pago = c.valorPago ?? (c.total + c.multa + c.juros - c.desconto);
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            PdfKit.cabecalho(logo, 'RECIBO DE ALUGUEL'),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                PdfKit.rotuloValor(
                  'Recibo',
                  '${d.contrato.numero}/${competenciaLabel(c.competencia)}',
                ),
                PdfKit.rotuloValor('Valor', formatMoney(pago), destaque: true),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Paragraph(
              textAlign: pw.TextAlign.justify,
              style: const pw.TextStyle(fontSize: 11, lineSpacing: 3),
              text:
                  'Recebemos de ${d.locatario?.nome ?? ''}'
                  '${(d.locatario?.documento.isNotEmpty ?? false) ? ', ${d.locatario!.documento}' : ''}, '
                  'a importância de ${formatMoney(pago)} (${valorPorExtenso(pago)}), '
                  'referente ao aluguel e encargos do imóvel situado em ${_endereco(d)}, '
                  'competência ${competenciaLabel(c.competencia)}, com vencimento em '
                  '${formatDate(c.vencimento)}, conforme discriminação abaixo.',
            ),
            PdfKit.tabela(
              cabecalhos: ['Discriminação', 'Valor'],
              linhas: [
                ..._itens(d),
                if (c.multa > 0) ['Multa por atraso', formatMoney(c.multa)],
                if (c.juros > 0) ['Juros de mora', formatMoney(c.juros)],
                if (c.desconto > 0)
                  ['Desconto de pontualidade', '- ${formatMoney(c.desconto)}'],
                ['TOTAL PAGO', formatMoney(pago)],
              ],
              alinhamentos: {1: _direita},
            ),
            pw.SizedBox(height: 12),
            pw.Text('Pagamento efetuado em ${formatDate(c.dataPagamento)}.'),
            pw.SizedBox(height: 8),
            pw.Text(
              'Por ser verdade, firmamos o presente recibo, dando plena quitação '
              'dos valores acima discriminados.',
            ),
            pw.SizedBox(height: 24),
            pw.Text(
              '${d.imovel?.cidade.isNotEmpty ?? false ? '${d.imovel!.cidade}, ' : ''}'
              '${formatDate(DateTime.now())}',
            ),
            PdfKit.assinatura('${EmpresaInfo.nome} • ${EmpresaInfo.creci}'),
          ],
        ),
      ),
    );
    return doc.save();
  }

  Future<Uint8List> gerarDemonstrativo(DemonstrativoRepasse d) async {
    final doc = await _documento();
    final logo = await PdfKit.logo();
    final b = d.beneficiario;
    double soma(double Function(dynamic) f) =>
        d.linhas.fold(0, (s, l) => s + f(l));
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(32),
        header: (_) => PdfKit.cabecalho(logo, 'DEMONSTRATIVO DE REPASSE'),
        build: (_) => [
          PdfKit.caixa(
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                PdfKit.rotuloValor('Beneficiário', '${b.nome} ${b.documento}'),
                PdfKit.rotuloValor(
                  'Competência',
                  competenciaLabel(d.competencia),
                ),
                PdfKit.rotuloValor(
                  'Dados bancários',
                  [
                    if (b.banco.isNotEmpty) 'Banco ${b.banco}',
                    if (b.agencia.isNotEmpty) 'Ag. ${b.agencia}',
                    if (b.conta.isNotEmpty) 'C/C ${b.conta}',
                    if (b.pix.isNotEmpty) 'PIX ${b.pix}',
                  ].join(' • '),
                ),
              ],
            ),
          ),
          PdfKit.tabela(
            cabecalhos: [
              'Contrato',
              'Imóvel',
              'Cota',
              'Aluguel',
              'Encargos',
              'Taxa adm.', //
              'Intermed.', 'Despesas', 'IRRF', 'Líquido',
            ],
            linhas: [
              for (final l in d.linhas)
                [
                  l.contrato.numero,
                  d.imovelPorContrato[l.contrato.id] ?? '',
                  '${decimalToText(l.beneficiario.percentual)}%',
                  formatMoney(l.aluguel),
                  formatMoney(l.encargos),
                  formatMoney(l.taxaAdministracao),
                  formatMoney(l.taxaIntermediacao),
                  formatMoney(l.despesasProprietario),
                  formatMoney(l.irrf),
                  formatMoney(l.liquido),
                ],
              [
                'TOTAL',
                '',
                '',
                formatMoney(soma((l) => l.aluguel)),
                formatMoney(soma((l) => l.encargos)),
                formatMoney(soma((l) => l.taxaAdministracao)),
                formatMoney(soma((l) => l.taxaIntermediacao)),
                formatMoney(soma((l) => l.despesasProprietario)),
                formatMoney(soma((l) => l.irrf)),
                formatMoney(soma((l) => l.liquido)),
              ],
            ],
            alinhamentos: {for (var i = 2; i <= 9; i++) i: _direita},
          ),
        ],
      ),
    );
    return doc.save();
  }

  Future<Uint8List> gerarInforme(InformeRendimentos i) async {
    final doc = await _documento();
    final logo = await PdfKit.logo();
    double soma(double Function(dynamic) f) =>
        i.meses.fold(0, (s, m) => s + f(m));
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (_) => PdfKit.cabecalho(logo, 'INFORME DE RENDIMENTOS'),
        build: (_) => [
          PdfKit.caixa(
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                PdfKit.rotuloValor('Beneficiário', i.beneficiario.nome),
                PdfKit.rotuloValor('CPF/CNPJ', i.beneficiario.documento),
                PdfKit.rotuloValor('Ano-calendário', '${i.ano}'),
              ],
            ),
          ),
          PdfKit.tabela(
            cabecalhos: [
              'Mês', 'Rend. bruto', 'Deduções', 'Base carnê-leão', //
              'Carnê-leão (estim.)', 'Base IRRF', 'IRRF retido',
            ],
            linhas: [
              for (final m in i.meses)
                [
                  nomeMes(m.mes),
                  formatMoney(m.rendimentoBruto),
                  formatMoney(m.deducoes),
                  formatMoney(m.baseCarneLeao),
                  formatMoney(m.impostoCarneLeao),
                  formatMoney(m.baseIrrf),
                  formatMoney(m.irrfRetido),
                ],
              [
                'TOTAL',
                formatMoney(soma((m) => m.rendimentoBruto)),
                formatMoney(soma((m) => m.deducoes)),
                formatMoney(soma((m) => m.baseCarneLeao)),
                formatMoney(soma((m) => m.impostoCarneLeao)),
                formatMoney(soma((m) => m.baseIrrf)),
                formatMoney(soma((m) => m.irrfRetido)),
              ],
            ],
            alinhamentos: {for (var c = 1; c <= 6; c++) c: _direita},
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Deduções: taxa de administração e despesas dedutíveis pagas pelo '
            'locador (IPTU, condomínio etc.). Regime de caixa (mês do '
            'recebimento). Valores de carnê-leão são estimativas com base na '
            'tabela progressiva mensal; confira com seu contador.',
            style: const pw.TextStyle(fontSize: 8, color: PdfKit.cinza),
          ),
        ],
      ),
    );
    return doc.save();
  }
}
