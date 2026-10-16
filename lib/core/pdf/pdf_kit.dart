import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../config/empresa_info.dart';

/// Fontes, cores e cabeçalho comuns aos documentos em PDF.
class PdfKit {
  PdfKit._();

  static const azul = PdfColor.fromInt(0xFF061A48);
  static const dourado = PdfColor.fromInt(0xFFC8921A);
  static const cinza = PdfColor.fromInt(0xFF666666);
  static const fundo = PdfColor.fromInt(0xFFF3F5FA);

  static pw.ThemeData? _tema;
  static pw.MemoryImage? _logo;

  /// Roboto embutida para suportar acentuação.
  static Future<pw.ThemeData> tema() async => _tema ??= pw.ThemeData.withFont(
    base: pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf')),
    bold: pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Bold.ttf')),
  );

  /// Logotipo da Personalização ou, sem ele, o logotipo padrão do sistema.
  static Future<pw.MemoryImage> logo() async {
    final personalizado = EmpresaInfo.logo;
    if (personalizado != null) return pw.MemoryImage(personalizado);
    return _logo ??= pw.MemoryImage(
      (await rootBundle.load(
        'assets/logo_marcelo_bonifacio.png',
      )).buffer.asUint8List(),
    );
  }

  static pw.Widget cabecalho(pw.MemoryImage logo, String titulo) {
    final empresa = EmpresaInfo.atual;
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      margin: const pw.EdgeInsets.only(bottom: 16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: dourado, width: 2)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Image(logo, width: 48, height: 48, fit: pw.BoxFit.contain),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  empresa.nome.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: azul,
                  ),
                ),
                if (empresa.atividadeECreci.isNotEmpty)
                  pw.Text(
                    empresa.atividadeECreci,
                    style: const pw.TextStyle(fontSize: 9, color: cinza),
                  ),
                if (empresa.contatos.isNotEmpty)
                  pw.Text(
                    empresa.contatos,
                    maxLines: 2,
                    style: const pw.TextStyle(fontSize: 7.5, color: cinza),
                  ),
              ],
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Text(
            titulo,
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: dourado,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget rotuloValor(
    String rotulo,
    String valor, {
    bool destaque = false,
  }) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(rotulo, style: const pw.TextStyle(fontSize: 8, color: cinza)),
      pw.Text(
        valor.isEmpty ? '—' : valor,
        style: pw.TextStyle(
          fontSize: destaque ? 13 : 10,
          fontWeight: destaque ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    ],
  );

  static pw.Widget caixa(pw.Widget child) => pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(10),
    margin: const pw.EdgeInsets.only(bottom: 10),
    decoration: pw.BoxDecoration(
      color: fundo,
      borderRadius: pw.BorderRadius.circular(6),
    ),
    child: child,
  );

  static pw.Widget tabela({
    required List<String> cabecalhos,
    required List<List<String>> linhas,
    Map<int, pw.Alignment>? alinhamentos,
  }) => pw.TableHelper.fromTextArray(
    headers: cabecalhos,
    data: linhas,
    headerStyle: pw.TextStyle(
      fontSize: 9,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    ),
    headerDecoration: const pw.BoxDecoration(color: azul),
    cellStyle: const pw.TextStyle(fontSize: 9),
    cellAlignments: alinhamentos ?? const {},
    oddRowDecoration: const pw.BoxDecoration(color: fundo),
    border: null,
  );

  static pw.Widget assinatura(String rotulo) => pw.Container(
    width: 220,
    margin: const pw.EdgeInsets.only(top: 36),
    padding: const pw.EdgeInsets.only(top: 4),
    decoration: const pw.BoxDecoration(
      border: pw.Border(top: pw.BorderSide(width: 0.8)),
    ),
    child: pw.Text(rotulo, style: const pw.TextStyle(fontSize: 9)),
  );

  /// Abre a visualização de impressão do navegador/sistema.
  static Future<void> imprimir(
    String nome,
    Future<Uint8List> Function() gerar,
  ) => Printing.layoutPdf(name: nome, onLayout: (_) => gerar());
}
