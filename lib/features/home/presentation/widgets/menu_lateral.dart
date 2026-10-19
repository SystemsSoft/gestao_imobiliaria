import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/skyline.dart';
import '../viewmodels/home_viewmodel.dart';

/// Menu de módulos com a logo e a ilustração da orla no rodapé.
class MenuLateral extends StatelessWidget {
  const MenuLateral({
    super.key,
    required this.selecionado,
    required this.onSelecionar,
    this.modulos = ModuloMenu.values,
    this.compacto = false,
    this.onBaixarApp,
    this.baixarParaDesktop = false,
  });

  /// Módulos que o usuário pode ver.
  final List<ModuloMenu> modulos;

  final ModuloMenu selecionado;
  final ValueChanged<ModuloMenu> onSelecionar;

  /// Celular: logo menor e sem a ilustração, para caberem mais itens.
  final bool compacto;

  /// Última opção ("Baixar app"); só aparece quando informada.
  final VoidCallback? onBaixarApp;

  /// No computador a opção vira "Baixar para desktop".
  final bool baixarParaDesktop;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF071430), AppColors.navyDark],
        ),
        border: Border(
          right: BorderSide(color: AppColors.blueGlow.withValues(alpha: 0.18)),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(18, compacto ? 10 : 18, 18, 6),
            child: Image.asset(
              'assets/logo_marcelo_bonifacio.png',
              height: compacto ? 84 : 130,
              fit: BoxFit.contain,
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              children: [
                for (final m in modulos)
                  _ItemMenu(
                    modulo: m,
                    selecionado: m == selecionado,
                    onTap: () => onSelecionar(m),
                  ),
                if (onBaixarApp case final baixar?) ...[
                  Divider(color: Colors.white.withValues(alpha: 0.12)),
                  _ItemAcao(
                    icone: baixarParaDesktop
                        ? Icons.install_desktop
                        : Icons.install_mobile,
                    texto: baixarParaDesktop
                        ? 'Baixar para desktop'
                        : 'Baixar app',
                    onTap: baixar,
                  ),
                ],
              ],
            ),
          ),
          if (!compacto)
            SizedBox(
              height: 150,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: (r) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black],
                      stops: [0, 0.4],
                    ).createShader(r),
                    child: const Skyline(semente: 5, densidade: 0.8),
                  ),
                  Align(
                    alignment: const Alignment(0, 0.55),
                    child: Text(
                      'Mais que imóveis,\nrealizamos sonhos.',
                      textAlign: TextAlign.center,
                      style: estiloManuscrito(tamanho: 21),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ItemMenu extends StatelessWidget {
  const _ItemMenu({
    required this.modulo,
    required this.selecionado,
    required this.onTap,
  });

  final ModuloMenu modulo;
  final bool selecionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cor = selecionado ? AppColors.navyDark : Colors.white;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: selecionado
                ? const LinearGradient(
                    colors: [AppColors.goldLight, AppColors.gold],
                  )
                : null,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(modulo.icon, size: 22, color: cor),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      modulo.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: cor,
                        fontSize: 14,
                        fontWeight: selecionado
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Item de ação do menu (não é um módulo), com destaque dourado.
class _ItemAcao extends StatelessWidget {
  const _ItemAcao({
    required this.icone,
    required this.texto,
    required this.onTap,
  });

  final IconData icone;
  final String texto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Material(
        color: AppColors.gold.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppColors.gold.withValues(alpha: 0.45)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icone, size: 22, color: AppColors.gold),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    texto,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
