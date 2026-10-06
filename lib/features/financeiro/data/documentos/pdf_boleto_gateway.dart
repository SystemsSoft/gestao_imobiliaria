import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/config/empresa_info.dart';
import '../../../../core/pdf/pdf_kit.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/repositories/boleto_impressao_gateway.dart';

/// Boleto em PDF para conferência. Sem registro bancário, o documento não
/// tem código de barras nem linha digitável: eles são gerados pelo banco.
class PdfBoletoGateway implements BoletoImpressaoGateway {
  @override
  Future<void> imprimirBoleto(BoletoDocumento d) =>
      PdfKit.imprimir('Boleto ${d.boleto.nossoNumero}', () => gerar(d));

  Future<Uint8List> gerar(BoletoDocumento d) async {
    final doc = pw.Document(theme: await PdfKit.tema());
    final logo = await PdfKit.logo();
    final b = d.boleto;
    final c = d.conta;
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            PdfKit.cabecalho(logo, 'BOLETO BANCÁRIO'),
            PdfKit.caixa(
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  PdfKit.rotuloValor(
                    'Beneficiário',
                    '${EmpresaInfo.nome} • ${EmpresaInfo.creci}',
                  ),
                  PdfKit.rotuloValor(
                    'Banco / Agência / Conta',
                    [
                      c.banco,
                      c.agencia,
                      c.conta,
                    ].where((e) => e.isNotEmpty).join(' / '),
                  ),
                  PdfKit.rotuloValor('Nosso número', b.nossoNumero),
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
                      d.pagador?.nome ?? '',
                      if (d.pagador?.documento.isNotEmpty ?? false)
                        d.pagador!.documento,
                    ].where((e) => e.isNotEmpty).join(' • '),
                  ),
                  pw.SizedBox(height: 6),
                  PdfKit.rotuloValor('Referente a', d.lancamento.descricao),
                ],
              ),
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                PdfKit.rotuloValor('Emissão', formatDate(b.emissao)),
                PdfKit.rotuloValor(
                  'Vencimento',
                  formatDate(b.vencimento),
                  destaque: true,
                ),
                PdfKit.rotuloValor(
                  'Valor do documento',
                  formatMoney(b.valor),
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
              text:
                  'Após o vencimento: multa de ${decimalToText(d.lancamento.multaPercentual)}% e '
                  'juros de ${decimalToText(d.lancamento.jurosMesPercentual)}% ao mês (pro rata die).',
              style: const pw.TextStyle(fontSize: 9),
            ),
            if (d.lancamento.indice.name != 'nenhum')
              pw.Bullet(
                text:
                    'Valor atualizado pelo ${d.lancamento.indice.label} após o vencimento.',
                style: const pw.TextStyle(fontSize: 9),
              ),
            pw.Spacer(),
            pw.Divider(color: PdfKit.cinza, borderStyle: pw.BorderStyle.dashed),
            pw.Text(
              'Pré-visualização do boleto. O código de barras e a linha digitável '
              'são gerados pelo banco após o registro da cobrança (integração pendente).',
              style: const pw.TextStyle(fontSize: 8, color: PdfKit.cinza),
            ),
          ],
        ),
      ),
    );
    return doc.save();
  }
}
