import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/pdf/pdf_kit.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/dimob.dart';
import '../../domain/repositories/dimob_gateway.dart';

const _mesesAbrev = [
  'Jan',
  'Fev',
  'Mar',
  'Abr',
  'Mai',
  'Jun',
  'Jul',
  'Ago',
  'Set',
  'Out',
  'Nov',
  'Dez',
];
const _direita = pw.Alignment.centerRight;

/// Conferência da DIMOB em PDF. Não é o arquivo de transmissão: reúne os
/// dados para conferir e digitar/importar no programa da Receita Federal.
class PdfDimobGateway implements DimobGateway {
  @override
  Future<void> imprimirConferencia(DeclaracaoDimob d) =>
      PdfKit.imprimir('DIMOB ${d.ano} - conferência', () => gerar(d));

  String _n(double v) => v == 0 ? '—' : formatMoney(v);

  Future<Uint8List> gerar(DeclaracaoDimob d) async {
    final doc = pw.Document(theme: await PdfKit.tema());
    final logo = await PdfKit.logo();
    final dec = d.declarante;
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        header: (_) => PdfKit.cabecalho(logo, 'DIMOB ${d.ano} • CONFERÊNCIA'),
        footer: (ctx) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Documento de conferência. A transmissão é feita pelo programa DIMOB da Receita Federal.',
              style: const pw.TextStyle(fontSize: 7, color: PdfKit.cinza),
            ),
            pw.Text(
              'Página ${ctx.pageNumber} de ${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 7, color: PdfKit.cinza),
            ),
          ],
        ),
        build: (_) => [
          PdfKit.caixa(
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                PdfKit.rotuloValor('Declarante', dec.nome),
                PdfKit.rotuloValor('CNPJ/CPF', dec.documento),
                PdfKit.rotuloValor(
                  'Responsável',
                  '${dec.responsavelNome} ${dec.responsavelCpf}'.trim(),
                ),
                PdfKit.rotuloValor(
                  'Tipo',
                  dec.retificadora
                      ? 'Retificadora (recibo ${dec.numeroRecibo})'
                      : 'Original',
                ),
                PdfKit.rotuloValor('Ano-calendário', '${d.ano}'),
              ],
            ),
          ),
          if (d.semMovimento)
            pw.Text(
              'DECLARAÇÃO SEM MOVIMENTO: nenhum contrato de locação ou venda no ano.',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          if (d.locacoes.isNotEmpty) ..._locacoes(d),
          if (d.vendas.isNotEmpty) ..._vendas(d),
          pw.SizedBox(height: 10),
          pw.Text(
            'Pendências (${d.erros} erro(s), ${d.avisos} aviso(s))',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfKit.azul,
            ),
          ),
          pw.SizedBox(height: 4),
          if (d.pendencias.isEmpty)
            pw.Text(
              'Nenhuma pendência.',
              style: const pw.TextStyle(fontSize: 9),
            )
          else
            for (final p in d.pendencias)
              pw.Bullet(
                text: '[${p.gravidade.label}] ${p.referencia}: ${p.mensagem}',
                style: const pw.TextStyle(fontSize: 8.5),
              ),
        ],
      ),
    );
    return doc.save();
  }

  pw.Widget _titulo(String t) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 10, bottom: 4),
    child: pw.Text(
      t,
      style: pw.TextStyle(
        fontSize: 12,
        fontWeight: pw.FontWeight.bold,
        color: PdfKit.azul,
      ),
    ),
  );

  String _partes(List<ParteDimob> p) => p
      .map(
        (x) =>
            '${x.nome} (${x.documento.isEmpty ? 'sem documento' : x.documento}'
            '${x.percentual == null ? '' : ', ${decimalToText(x.percentual)}%'})',
      )
      .join('; ');

  List<pw.Widget> _locacoes(DeclaracaoDimob d) => [
    _titulo('Locações'),
    for (final l in d.locacoes)
      pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              '${l.numero} • contrato de ${formatDate(l.dataContrato)} • imóvel ${l.imovel.tipo.toLowerCase()}: ${l.imovel.endereco}',
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Locador(es): ${_partes(l.locadores)}',
              style: const pw.TextStyle(fontSize: 8.5),
            ),
            pw.Text(
              'Locatário: ${_partes([l.locatario])}',
              style: const pw.TextStyle(fontSize: 8.5),
            ),
            pw.SizedBox(height: 3),
            PdfKit.tabela(
              cabecalhos: ['', ..._mesesAbrev, 'Total'],
              linhas: [
                [
                  'Aluguel',
                  for (final v in l.aluguel) _n(v),
                  _n(l.totalAluguel),
                ],
                [
                  'Encargos',
                  for (final v in l.encargos) _n(v),
                  _n(l.totalEncargos),
                ],
                [
                  'Comissão',
                  for (final v in l.comissao) _n(v),
                  _n(l.totalComissao),
                ],
                ['IRRF', for (final v in l.irrf) _n(v), _n(l.totalIrrf)],
              ],
              alinhamentos: {for (var i = 1; i <= 13; i++) i: _direita},
            ),
          ],
        ),
      ),
    pw.Text(
      'Totais: aluguel ${formatMoney(d.totalAluguel)} • encargos ${formatMoney(d.totalEncargos)} '
      '• comissão ${formatMoney(d.totalComissao)} • IRRF ${formatMoney(d.totalIrrf)}',
      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
    ),
  ];

  List<pw.Widget> _vendas(DeclaracaoDimob d) => [
    _titulo('Compra e venda'),
    for (final v in d.vendas)
      pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              '${v.numero} • contrato de ${formatDate(v.dataContrato)} • valor da operação ${formatMoney(v.valorOperacao)}'
              ' • imóvel ${v.imovel.tipo.toLowerCase()}: ${v.imovel.endereco}',
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Vendedor(es): ${_partes(v.vendedores)}',
              style: const pw.TextStyle(fontSize: 8.5),
            ),
            pw.Text(
              'Comprador(es): ${_partes(v.compradores)}',
              style: const pw.TextStyle(fontSize: 8.5),
            ),
            pw.SizedBox(height: 3),
            PdfKit.tabela(
              cabecalhos: ['', ..._mesesAbrev, 'Total'],
              linhas: [
                [
                  v.presumido ? 'Recebido*' : 'Recebido',
                  for (final x in v.recebido) _n(x),
                  _n(v.totalRecebido),
                ],
              ],
              alinhamentos: {for (var i = 1; i <= 13; i++) i: _direita},
            ),
            if (v.presumido)
              pw.Text(
                '* Valor presumido na data da venda: confirme.',
                style: const pw.TextStyle(fontSize: 7.5, color: PdfKit.cinza),
              ),
          ],
        ),
      ),
  ];
}
