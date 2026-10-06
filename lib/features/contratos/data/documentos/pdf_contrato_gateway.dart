import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/pdf/pdf_kit.dart';
import '../../domain/entities/contrato_documento.dart';
import '../../domain/repositories/contrato_impressao_gateway.dart';

/// Gera o contrato em PDF e abre a impressão.
class PdfContratoGateway implements ContratoImpressaoGateway {
  @override
  Future<void> imprimirContrato(ContratoDocumento d) =>
      PdfKit.imprimir(d.titulo, () => gerarContrato(d));

  Future<Uint8List> gerarContrato(ContratoDocumento d) async {
    final doc = pw.Document(theme: await PdfKit.tema());
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
}
