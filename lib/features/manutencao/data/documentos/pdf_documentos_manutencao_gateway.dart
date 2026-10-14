import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/config/empresa_info.dart';
import '../../../../core/pdf/pdf_kit.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/diario_documento.dart';
import '../../domain/repositories/documentos_manutencao_gateway.dart';

const _direita = pw.Alignment.centerRight;

/// Gera o diário de manutenção em PDF e abre a impressão.
class PdfDocumentosManutencaoGateway implements DocumentosManutencaoGateway {
  @override
  Future<void> imprimirDiario(DiarioDocumento d) => PdfKit.imprimir(
    'Diário de manutenção ${d.imovel?.codigo ?? ''} '
            '${formatDate(d.emitidoEm)}'
        .trim(),
    () => gerarDiario(d),
  );

  Future<Uint8List> gerarDiario(DiarioDocumento d) async {
    final doc = pw.Document(theme: await PdfKit.tema());
    final logo = await PdfKit.logo();
    final m = d.manutencao;
    final imovel = d.imovel;
    final registros = [...m.diario]..sort((a, b) => a.data.compareTo(b.data));

    pw.Widget campo(String rotulo, String valor) =>
        pw.Expanded(child: PdfKit.rotuloValor(rotulo, valor));

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(32),
        header: (_) => PdfKit.cabecalho(logo, 'DIÁRIO DE MANUTENÇÃO'),
        footer: (ctx) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Emitido em ${formatDateTime(d.emitidoEm)}',
              style: const pw.TextStyle(fontSize: 8, color: PdfKit.cinza),
            ),
            pw.Text(
              'Página ${ctx.pageNumber} de ${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: PdfKit.cinza),
            ),
          ],
        ),
        build: (_) => [
          PdfKit.caixa(
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    campo(
                      'Imóvel',
                      imovel == null
                          ? 'Imóvel removido'
                          : [
                              imovel.codigo,
                              imovel.titulo,
                            ].where((s) => s.isNotEmpty).join(' • '),
                    ),
                    campo('Endereço', imovel?.enderecoResumo ?? ''),
                    campo('Proprietário', d.proprietario?.nome ?? ''),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  children: [
                    campo('Tipo de manutenção', m.tipoLabel),
                    campo('Módulo', m.contexto.label),
                    campo('Situação', m.status.label),
                    campo('Aberta em', formatDate(m.criadaEm)),
                    campo('Data prevista', formatDate(m.dataPrevista)),
                  ],
                ),
                pw.SizedBox(height: 8),
                PdfKit.rotuloValor('O que precisa ser feito', m.descricao),
              ],
            ),
          ),
          pw.SizedBox(height: 4),
          PdfKit.tabela(
            cabecalhos: const [
              'Data',
              'Profissional',
              'Serviço executado',
              'Material',
              'Valor material',
              'Mão de obra',
              'Total serviços',
              'Taxa manut.',
              'Total',
            ],
            linhas: [
              for (final r in registros)
                [
                  formatDate(r.data),
                  r.profissional,
                  r.servico,
                  r.material.isEmpty ? '—' : r.material,
                  formatMoney(r.valorMaterial),
                  formatMoney(r.valorMaoDeObra),
                  formatMoney(r.valorServicos),
                  formatMoney(r.valorTaxa),
                  formatMoney(r.valorTotal),
                ],
            ],
            alinhamentos: const {
              4: _direita,
              5: _direita,
              6: _direita,
              7: _direita,
              8: _direita,
            },
          ),
          pw.SizedBox(height: 12),
          pw.Align(
            alignment: _direita,
            child: pw.SizedBox(
              width: 300,
              child: PdfKit.caixa(
                pw.Column(
                  children: [
                    _linhaTotal(
                      'Material',
                      m.diario.fold(0.0, (s, r) => s + r.valorMaterial),
                    ),
                    _linhaTotal(
                      'Mão de obra',
                      m.diario.fold(0.0, (s, r) => s + r.valorMaoDeObra),
                    ),
                    _linhaTotal('Valor total dos serviços', m.totalServicos),
                    _linhaTotal('Taxas de manutenção', m.totalTaxas),
                    pw.Divider(color: PdfKit.dourado),
                    _linhaTotal('TOTAL GERAL', m.total, destaque: true),
                  ],
                ),
              ),
            ),
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              PdfKit.assinatura('${EmpresaInfo.nome} • ${EmpresaInfo.creci}'),
              PdfKit.assinatura(
                d.proprietario == null
                    ? 'Proprietário'
                    : 'Proprietário: ${d.proprietario!.nome}',
              ),
            ],
          ),
        ],
      ),
    );
    return doc.save();
  }

  pw.Widget _linhaTotal(String rotulo, double valor, {bool destaque = false}) {
    final estilo = pw.TextStyle(
      fontSize: destaque ? 12 : 10,
      fontWeight: destaque ? pw.FontWeight.bold : pw.FontWeight.normal,
      color: destaque ? PdfKit.azul : PdfColors.black,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(rotulo, style: estilo),
          pw.Text(formatMoney(valor), style: estilo),
        ],
      ),
    );
  }
}
