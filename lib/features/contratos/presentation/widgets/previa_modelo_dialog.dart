import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

final _marcador = RegExp(r'\{\{\w+\}\}');

/// Texto do contrato com aparência de papel. Campos que não foram
/// substituídos aparecem em vermelho.
class FolhaContrato extends StatelessWidget {
  const FolhaContrato({super.key, required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final linhas = texto.trim().split('\n');
    final titulo = linhas.first.trim();
    final corpo = linhas.skip(1).join('\n').trim();
    const tinta = Color(0xFF1B1B1B);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8F2),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: tinta,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 16),
          SelectableText.rich(
            TextSpan(
              style: const TextStyle(color: tinta, fontSize: 13, height: 1.55),
              children: _trechos(corpo),
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  List<InlineSpan> _trechos(String t) {
    final spans = <InlineSpan>[];
    var pos = 0;
    for (final m in _marcador.allMatches(t)) {
      if (m.start > pos) spans.add(TextSpan(text: t.substring(pos, m.start)));
      spans.add(
        TextSpan(
          text: m.group(0),
          style: const TextStyle(
            color: Color(0xFFB3261E),
            fontWeight: FontWeight.w700,
            backgroundColor: Color(0x22B3261E),
          ),
        ),
      );
      pos = m.end;
    }
    if (pos < t.length) spans.add(TextSpan(text: t.substring(pos)));
    return spans;
  }
}

/// Visualização do modelo com dados de exemplo.
Future<void> mostrarPreviaDialog(
  BuildContext context, {
  required String titulo,
  required String texto,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: AppColors.navy,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 720),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      titulo,
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Visualização com dados de exemplo. Campos em vermelho não existem para este tipo.',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: FolhaContrato(texto: texto),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
