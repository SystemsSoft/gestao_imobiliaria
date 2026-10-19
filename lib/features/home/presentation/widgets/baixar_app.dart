import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/pwa/instalacao_app.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/form_widgets.dart';

/// "Baixar app" (Android) / "Baixar para desktop" (Windows, Mac, Linux):
/// instala o app (PWA). Chrome e Edge abrem a própria janela de instalação;
/// nos demais casos mostra o passo a passo do navegador em uso.
Future<void> baixarApp(BuildContext context) async {
  final app = sl<InstalacaoApp>();
  if (app.disponivel) {
    final r = await app.instalar();
    if (!context.mounted) return;
    switch (r) {
      case ResultadoInstalacao.instalado:
        mostrarMensagem(
          context,
          app.computador
              ? 'App instalado! Ele abre em janela própria pelo atalho '
                    '"MB Gestão".'
              : 'App instalado! Abra pelo ícone "MB Gestão" na tela inicial.',
        );
        return;
      case ResultadoInstalacao.recusado:
        return;
      case ResultadoInstalacao.indisponivel:
        break;
    }
  }
  if (!context.mounted) return;
  final conteudo = _Instrucoes(app: app);
  if (MediaQuery.sizeOf(context).width >= 700) {
    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.navy,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.only(top: 24),
            child: conteudo,
          ),
        ),
      ),
    );
  } else {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.navy,
      isScrollControlled: true,
      builder: (_) => conteudo,
    );
  }
}

typedef PassoInstalacao = (String texto, IconData icone);

/// Passos de instalação para o sistema e o navegador em uso.
List<PassoInstalacao> passosInstalacao(Sistema sistema, Navegador navegador) {
  if (sistema == Sistema.android) {
    return const [
      ('Toque em ⋮ no canto do Chrome', Icons.more_vert),
      (
        'Escolha "Instalar app" ou "Adicionar à tela inicial"',
        Icons.add_to_home_screen,
      ),
      ('Confirme em "Instalar"', Icons.download_done),
    ];
  }
  return switch (navegador) {
    Navegador.chrome => const [
      (
        'Clique no ícone de instalar, no fim da barra de endereço',
        Icons.install_desktop,
      ),
      (
        'Ou: ⋮ › Transmitir, salvar e compartilhar › Instalar página como app',
        Icons.more_vert,
      ),
      ('Confirme em "Instalar"', Icons.download_done),
    ],
    Navegador.edge => const [
      (
        'Clique no ícone de instalar, no fim da barra de endereço',
        Icons.install_desktop,
      ),
      ('Ou: ··· › Apps › Instalar este site como app', Icons.more_horiz),
      ('Confirme em "Instalar"', Icons.download_done),
    ],
    Navegador.safari => const [
      (
        'No menu Arquivo, escolha "Adicionar ao Dock" (macOS Sonoma ou mais novo)',
        Icons.desktop_mac_outlined,
      ),
      ('Confirme em "Adicionar"', Icons.download_done),
      ('Abra pelo ícone "MB Gestão" no Dock ou no Launchpad', Icons.apps),
    ],
    Navegador.firefox || Navegador.outro => [
      (
        'O ${navegador.label} não instala apps assim. Abra o endereço no '
            'Google Chrome ou no Microsoft Edge'
            '${sistema == Sistema.mac ? ' (ou use o Safari: Arquivo › Adicionar ao Dock)' : ''}',
        Icons.public,
      ),
      (
        'Clique no ícone de instalar, no fim da barra de endereço',
        Icons.install_desktop,
      ),
      ('Confirme em "Instalar"', Icons.download_done),
    ],
  };
}

class _Instrucoes extends StatelessWidget {
  const _Instrucoes({required this.app});

  final InstalacaoApp app;

  @override
  Widget build(BuildContext context) {
    final computador = app.computador;
    final passos = [
      if (!app.enderecoOficial)
        ('Abra o endereço oficial (botão abaixo)', Icons.open_in_new),
      ...passosInstalacao(app.sistema, app.navegador),
    ];
    Widget passo(int n, PassoInstalacao p) => Padding(
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
          Expanded(child: Text(p.$1, style: const TextStyle(fontSize: 15))),
          const SizedBox(width: 8),
          Icon(p.$2, color: Colors.white54),
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
                      Text(
                        computador
                            ? 'MB Gestão para ${app.sistema.label.isEmpty ? 'o computador' : app.sistema.label}'
                            : 'MB Gestão',
                        style: estiloTitulo(tamanho: 22),
                      ),
                      Text(
                        computador
                            ? 'Instale o app no computador: abre em janela '
                                  'própria, com atalho na área de trabalho, e '
                                  'está sempre atualizado.'
                            : 'Instale o app na tela inicial: abre em tela '
                                  'cheia, sem barra do navegador, e está '
                                  'sempre atualizado.',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            for (final (i, p) in passos.indexed) passo(i + 1, p),
            const SizedBox(height: 4),
            if (!app.enderecoOficial) ...[
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
            ] else
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendi'),
              ),
          ],
        ),
      ),
    );
  }
}
