import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/form_widgets.dart';

/// Login do internet banking do Sicoob (Sicoobnet).
const linkSicoob = 'https://ib.sicoob.com.br/sicoobnet/ib/#/login';

/// Abre o Sicoob em outra aba. O banco não permite que o site seja exibido
/// dentro do sistema, e a integração é só por esse link.
Future<void> abrirSicoob(
  BuildContext context, {
  String link = linkSicoob,
}) async {
  final uri = Uri.tryParse(link);
  final ok = uri != null && await launchUrl(uri, webOnlyWindowName: '_blank');
  if (!ok && context.mounted) {
    mostrarMensagem(context, 'Não foi possível abrir $link.');
  }
}

/// Botão de abrir um site de banco no Financeiro (só o ícone em telas
/// menores, para não empurrar as abas).
class BotaoAbrirSite extends StatelessWidget {
  const BotaoAbrirSite({
    super.key,
    required this.rotulo,
    required this.icone,
    required this.onPressed,
  });

  final String rotulo;
  final IconData icone;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < 1500) {
      return IconButton(
        tooltip: rotulo,
        color: AppColors.gold,
        icon: Icon(icone),
        onPressed: onPressed,
      );
    }
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.gold,
        side: BorderSide(color: AppColors.gold),
      ),
      onPressed: onPressed,
      icon: const Icon(Icons.open_in_new, size: 18),
      label: Text(rotulo),
    );
  }
}

/// Botão "Abrir Sicoob" do Financeiro.
class BotaoAbrirSicoob extends StatelessWidget {
  const BotaoAbrirSicoob({super.key});

  @override
  Widget build(BuildContext context) => BotaoAbrirSite(
    rotulo: 'Abrir Sicoob',
    icone: Icons.account_balance_outlined,
    onPressed: () => abrirSicoob(context),
  );
}
