import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/pwa/instalacao_app.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/form_widgets.dart';

/// "Baixar app": instala o app (PWA) na tela inicial do Android. Quando o
/// navegador não oferece a instalação direta, mostra como fazer.
Future<void> baixarApp(BuildContext context) async {
  final app = sl<InstalacaoApp>();
  if (app.disponivel) {
    final r = await app.instalar();
    if (!context.mounted) return;
    switch (r) {
      case ResultadoInstalacao.instalado:
        mostrarMensagem(
          context,
          'App instalado! Abra pelo ícone "MB Gestão" na tela inicial.',
        );
        return;
      case ResultadoInstalacao.recusado:
        return;
      case ResultadoInstalacao.indisponivel:
        break;
    }
  }
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.navy,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _Instrucoes(enderecoOficial: app.enderecoOficial),
  );
}

class _Instrucoes extends StatelessWidget {
  const _Instrucoes({required this.enderecoOficial});

  final bool enderecoOficial;

  @override
  Widget build(BuildContext context) {
    Widget passo(int n, String texto, IconData icone) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: AppColors.gold,
            foregroundColor: AppColors.navyDark,
            child: Text(
              '$n',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(texto, style: const TextStyle(fontSize: 15))),
          Icon(icone, color: Colors.white54),
        ],
      ),
    );
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset('assets/logo_icone.png', height: 52),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MB Gestão', style: estiloTitulo(tamanho: 22)),
                      const Text(
                        'Instale o app na tela inicial: abre em tela cheia, '
                        'sem barra do navegador, e está sempre atualizado.',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            if (!enderecoOficial) ...[
              passo(1, 'Abra o endereço oficial no Chrome', Icons.public),
              passo(
                2,
                'Toque em ⋮ e depois em "Instalar app"',
                Icons.more_vert,
              ),
              const SizedBox(height: 4),
              FilledButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse(enderecoAppWeb),
                  webOnlyWindowName: '_blank',
                ),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Abrir endereço oficial'),
              ),
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(
                    const ClipboardData(text: enderecoAppWeb),
                  );
                  if (context.mounted) {
                    mostrarMensagem(context, 'Endereço copiado.');
                  }
                },
                icon: const Icon(Icons.copy, size: 18),
                label: const Text(enderecoAppWeb),
              ),
            ] else ...[
              passo(1, 'Toque em ⋮ no canto do Chrome', Icons.more_vert),
              passo(
                2,
                'Escolha "Instalar app" ou "Adicionar à tela inicial"',
                Icons.add_to_home_screen,
              ),
              passo(3, 'Confirme em "Instalar"', Icons.download_done),
              const SizedBox(height: 4),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendi'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
