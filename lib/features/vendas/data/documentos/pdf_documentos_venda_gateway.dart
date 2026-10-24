import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/config/empresa_info.dart';
import '../../../../core/pdf/pdf_kit.dart';
import '../../../../core/utils/extenso.dart';
import '../../../../core/utils/formatters.dart';
import '../../../contratos/domain/usecases/qualificacao.dart';
import '../../domain/entities/documentos_venda.dart';
import '../../domain/entities/parcela.dart';
import '../../domain/repositories/documentos_venda_gateway.dart';

/// Carnê, notas promissórias e recibo de comissão em PDF.
class PdfDocumentosVendaGateway implements DocumentosVendaGateway {
  @override
  Future<void> imprimirCarne(ParcelasDocumento d) =>
      PdfKit.imprimir('Carnê ${d.venda.numero}', () => gerarCarne(d));

  @override
  Future<void> imprimirPromissorias(ParcelasDocumento d) => PdfKit.imprimir(
    'Promissórias ${d.venda.numero}',
    () => gerarPromissorias(d),
  );

  @override
  Future<void> imprimirReciboComissao(ReciboComissaoDocumento d) =>
      PdfKit.imprimir(
        'Recibo de comissão ${d.venda.numero}',
        () => gerarReciboComissao(d),
      );

  static final _corte = pw.Divider(
    color: PdfKit.cinza,
    borderStyle: pw.BorderStyle.dashed,
    height: 24,
  );

  String _compradores(ParcelasDocumento d) =>
      d.compradores.map((c) => c.nome).join(' e ');

  String _instrucoes(ParcelasDocumento d) =>
      'Após o vencimento: multa de ${decimalToText(d.venda.multaAtraso)}% e '
      'juros de ${decimalToText(d.venda.jurosMes)}% ao mês (pro rata die).';

  pw.Widget _campo(String rotulo, String valor, {bool destaque = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: PdfKit.rotuloValor(rotulo, valor, destaque: destaque),
      );

  pw.Widget _cupom(ParcelasDocumento d, Parcela p, pw.MemoryImage? logo) {
    final canhoto = pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.only(right: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          right: pw.BorderSide(
            color: PdfKit.cinza,
            style: pw.BorderStyle.dashed,
          ),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'CANHOTO',
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: PdfKit.dourado,
            ),
          ),
          pw.SizedBox(height: 6),
          _campo('Contrato', d.venda.numero),
          _campo('Parcela', p.rotulo),
          _campo('Vencimento', formatDate(p.vencimento)),
          _campo('Valor', formatMoney(p.valor), destaque: true),
          _campo('Pagador', _compradores(d)),
          pw.Spacer(),
          pw.Text(
            'Recebido em ___/___/______',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ],
      ),
    );
    final ficha = pw.Expanded(
      child: pw.Padding(
        padding: const pw.EdgeInsets.only(left: 10),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              children: [
                if (logo != null) ...[
                  pw.Image(logo, width: 28, height: 28),
                  pw.SizedBox(width: 6),
                ],
                pw.Expanded(
                  child: pw.Text(
                    '${EmpresaInfo.nome.toUpperCase()} • ${EmpresaInfo.creci}',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfKit.azul,
                    ),
                  ),
                ),
                pw.Text(
                  'CARNÊ DE PAGAMENTO',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfKit.dourado,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _campo('Credor', d.credor.nome),
                      _campo('Pagador', _compradores(d)),
                      _campo('Imóvel', d.imovel?.enderecoResumo ?? ''),
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    _campo('Contrato', d.venda.numero),
                    _campo('Parcela', p.rotulo),
                    _campo(
                      'Vencimento',
                      formatDate(p.vencimento),
                      destaque: true,
                    ),
                    _campo(
                      'Valor do documento',
                      formatMoney(p.valor),
                      destaque: true,
                    ),
                  ],
                ),
              ],
            ),
            pw.Spacer(),
            pw.Text(_instrucoes(d), style: const pw.TextStyle(fontSize: 8)),
            if (EmpresaInfo.chavePix.isNotEmpty)
              pw.Text(
                'PIX: ${EmpresaInfo.chavePix}',
                style: const pw.TextStyle(fontSize: 8),
              ),
          ],
        ),
      ),
    );
    return pw.Container(
      height: 200,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [canhoto, ficha],
      ),
    );
  }

  Future<Uint8List> gerarCarne(ParcelasDocumento d) async {
    final doc = pw.Document(theme: await PdfKit.tema());
    final logo = await PdfKit.logo();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (_) => [
          for (final p in d.parcelas) ...[_cupom(d, p, logo), _corte],
          pw.Text(
            'Documento de cobrança emitido pela administradora, sem registro bancário.',
            style: const pw.TextStyle(fontSize: 7, color: PdfKit.cinza),
          ),
        ],
      ),
    );
    return doc.save();
  }

  pw.Widget _promissoria(ParcelasDocumento d, Parcela p) {
    final cidade = d.imovel?.cidade ?? '';
    final emitentes = d.compradores;
    return pw.Container(
      height: 230,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfKit.azul, width: 1.2),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'NOTA PROMISSÓRIA  Nº ${p.rotulo}',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfKit.azul,
                ),
              ),
              pw.Text(
                'Vencimento: ${formatDate(p.vencimento)}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                color: PdfKit.fundo,
                child: pw.Text(
                  formatMoney(p.valor),
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Paragraph(
            textAlign: pw.TextAlign.justify,
            style: const pw.TextStyle(fontSize: 10, lineSpacing: 2),
            text:
                'Em ${dataPorExtenso(p.vencimento)}, pagarei(emos) por esta '
                'única via de NOTA PROMISSÓRIA a ${d.credor.nome}'
                '${d.credor.documento.isEmpty ? '' : ', ${d.credor.documento}'}, '
                'ou à sua ordem, a quantia de ${formatMoney(p.valor)} '
                '(${valorPorExtenso(p.valor)}) em moeda corrente deste país, '
                'referente à parcela ${p.rotulo} do contrato ${d.venda.numero}.',
          ),
          pw.Text(
            'Pagável em ${cidade.isEmpty ? '________________' : cidade}.',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 6),
          for (final e in emitentes)
            pw.Text(
              'Emitente: ${e.nome}${e.documento.isEmpty ? '' : ' • ${e.documento}'}',
              style: const pw.TextStyle(fontSize: 9),
            ),
          pw.Spacer(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Emissão: ${cidadeData(cidade, d.venda.dataVenda)}',
                style: const pw.TextStyle(fontSize: 9),
              ),
              PdfKit.assinatura('Assinatura do(s) emitente(s)'),
            ],
          ),
        ],
      ),
    );
  }

  Future<Uint8List> gerarPromissorias(ParcelasDocumento d) async {
    final doc = pw.Document(theme: await PdfKit.tema());
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (_) => [
          for (final p in d.parcelas) ...[_promissoria(d, p), _corte],
        ],
      ),
    );
    return doc.save();
  }

  Future<Uint8List> gerarReciboComissao(ReciboComissaoDocumento d) async {
    final doc = pw.Document(theme: await PdfKit.tema());
    final logo = await PdfKit.logo();
    final v = d.venda;
    final pagadores = d.pagadores.map((c) => c.nome).join(' e ');
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            PdfKit.cabecalho(logo, 'RECIBO DE COMISSÃO'),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                PdfKit.rotuloValor('Venda', v.numero),
                PdfKit.rotuloValor(
                  'Valor',
                  formatMoney(d.valor),
                  destaque: true,
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Paragraph(
              textAlign: pw.TextAlign.justify,
              style: const pw.TextStyle(fontSize: 11, lineSpacing: 3),
              text:
                  'Recebi(emos) de $pagadores a importância de '
                  '${formatMoney(d.valor)} (${valorPorExtenso(d.valor)}), referente '
                  'à comissão de corretagem pela intermediação da venda do imóvel '
                  'situado em ${d.imovel == null ? '' : enderecoCompleto(d.imovel!)}, '
                  'conforme contrato ${v.numero}, pelo preço de ${formatMoney(v.valorVenda)}.',
            ),
            PdfKit.tabela(
              cabecalhos: ['Discriminação', 'Valor'],
              linhas: [
                ['Valor da venda', formatMoney(v.valorVenda)],
                [
                  'Comissão total (${decimalToText(v.comissaoPercentual)}%)',
                  formatMoney(v.valorComissao),
                ],
                [
                  'Participação de ${d.recebedor.nome} (${decimalToText(d.percentualParticipacao)}%)',
                  formatMoney(d.valor),
                ],
              ],
              alinhamentos: {1: pw.Alignment.centerRight},
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              'Por ser verdade, firmo(amos) o presente recibo, dando plena e '
              'geral quitação do valor acima.',
            ),
            pw.SizedBox(height: 24),
            pw.Text(cidadeData(d.imovel?.cidade ?? '', d.data)),
            PdfKit.assinatura(
              '${d.recebedor.nome}${d.recebedor.documento.isEmpty ? '' : ' • ${d.recebedor.documento}'}',
            ),
          ],
        ),
      ),
    );
    return doc.save();
  }
}
