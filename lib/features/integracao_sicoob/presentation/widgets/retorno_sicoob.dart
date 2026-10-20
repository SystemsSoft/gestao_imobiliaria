import 'package:flutter/material.dart';
import '../../../financeiro/presentation/widgets/abrir_sicoob.dart';

import '../../../../core/arquivos/escolher_arquivos.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/sicoob.dart';
import '../viewmodels/integracao_sicoob_viewmodel.dart';

/// Envio do arquivo de retorno de cobrança (CNAB 240) baixado no Sicoob:
/// mostra o que será feito e, confirmado, dá baixa nas cobranças do aluguel.
class RetornoSicoobCard extends StatelessWidget {
  const RetornoSicoobCard({super.key, required this.vm});

  final IntegracaoSicoobViewModel vm;

  Future<void> _enviar(BuildContext context) async {
    final escolhidos = await escolherArquivos(
      extensoes: const ['ret', 'txt', 'cnab', 'rem', 'dat'],
    );
    if (escolhidos.isEmpty || !context.mounted) return;
    final arquivo = await escolhidos.first.ler();
    final previa = await vm.processarRetorno(arquivo, aplicar: false);
    if (!context.mounted) return;
    if (previa == null) {
      mostrarMensagem(context, vm.erro ?? 'Erro ao ler o arquivo.');
      return;
    }
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) =>
          _PreviaRetornoDialog(nome: escolhidos.first.nome, resultado: previa),
    );
    if (confirmar != true || !context.mounted) return;
    final feito = await vm.processarRetorno(arquivo, aplicar: true);
    if (!context.mounted) return;
    mostrarMensagem(
      context,
      feito == null
          ? (vm.erro ?? 'Erro ao dar baixa.')
          : '${feito.baixas} cobrança(s) do aluguel marcada(s) como paga(s).',
    );
  }

  @override
  Widget build(BuildContext context) {
    return CardPadrao(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.upload_file, color: AppColors.gold),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Retorno de cobrança',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'No Sicoob, baixe o arquivo de retorno da cobrança (CNAB 240) e '
            'envie aqui. O sistema mostra os pagamentos encontrados e, ao '
            'confirmar, marca as cobranças do aluguel como pagas.',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => abrirSicoob(
                  context,
                  link: vm.configuracao?.linkInternetBanking ?? linkSicoob,
                ),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Abrir Sicoob'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.navyDark,
                ),
                onPressed: vm.ocupado ? null : () => _enviar(context),
                icon: const Icon(Icons.upload_file),
                label: const Text('Enviar arquivo de retorno'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviaRetornoDialog extends StatelessWidget {
  const _PreviaRetornoDialog({required this.nome, required this.resultado});

  final String nome;
  final ResultadoRetornoSicoob resultado;

  static (IconData, Color) _visual(ItemRetornoSicoob i) => switch (i.situacao) {
    'baixar' || 'aplicada' => (Icons.check_circle, Colors.greenAccent),
    'divergente' || 'sem_boleto' => (Icons.warning_amber, Colors.orangeAccent),
    _ => (Icons.remove_circle_outline, Colors.white38),
  };

  @override
  Widget build(BuildContext context) {
    final r = resultado;
    final atencao = r.itens.where((i) => i.precisaAtencao).length;
    return AlertDialog(
      backgroundColor: AppColors.navy,
      title: Text('Retorno: $nome'),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${r.itens.length} título(s) no arquivo · ${r.baixas} baixa(s)'
              '${atencao > 0 ? ' · $atencao para conferir' : ''}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            if (r.itens.isEmpty)
              const Text('Nenhum título no arquivo.')
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final i in r.itens)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(_visual(i).$1, color: _visual(i).$2),
                        title: Text(
                          [
                            if (i.locatario.isNotEmpty) i.locatario,
                            if (i.descricao.isNotEmpty) i.descricao,
                            if (i.locatario.isEmpty && i.descricao.isEmpty)
                              'Nosso número ${i.nossoNumero}',
                          ].join(' · '),
                        ),
                        subtitle: Text(
                          [
                            if (i.valorPago > 0) formatMoney(i.valorPago),
                            if (i.dataCredito != null)
                              formatDate(i.dataCredito!),
                            i.mensagem,
                          ].join(' · '),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: r.baixas == 0 ? null : () => Navigator.pop(context, true),
          child: Text(
            r.baixas == 0 ? 'Nada para baixar' : 'Dar baixa em ${r.baixas}',
          ),
        ),
      ],
    );
  }
}
