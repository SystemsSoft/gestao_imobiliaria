import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../viewmodels/home_viewmodel.dart';

/// Barra inferior do celular: Início, os módulos mais usados que o usuário
/// pode ver e "Mais" (abre o menu completo). Fica ao alcance do polegar.
class NavegacaoInferior extends StatelessWidget {
  const NavegacaoInferior({
    super.key,
    required this.permitidos,
    required this.selecionado,
    required this.onSelecionar,
    required this.onMais,
  });

  final List<ModuloMenu> permitidos;
  final ModuloMenu selecionado;
  final ValueChanged<ModuloMenu> onSelecionar;
  final VoidCallback onMais;

  /// Em ordem de preferência; entram os 3 primeiros permitidos.
  static const _favoritos = [
    ModuloMenu.cadastrosCrm,
    ModuloMenu.locacao,
    ModuloMenu.auditorias,
    ModuloMenu.vendas,
    ModuloMenu.financeiro,
    ModuloMenu.site,
  ];

  static List<ModuloMenu> atalhos(List<ModuloMenu> permitidos) => [
    if (permitidos.contains(ModuloMenu.dashboard)) ModuloMenu.dashboard,
    ..._favoritos.where(permitidos.contains).take(3),
  ];

  static String rotulo(ModuloMenu m) => switch (m) {
    ModuloMenu.dashboard => 'Início',
    ModuloMenu.cadastrosCrm => 'CRM',
    ModuloMenu.site => 'Site',
    _ => m.curto,
  };

  @override
  Widget build(BuildContext context) {
    final itens = atalhos(permitidos);
    final atual = itens.indexOf(selecionado);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.blueGlow.withValues(alpha: 0.22)),
        ),
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.resolveWith(
            (s) => TextStyle(
              fontSize: 12,
              fontWeight: s.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: s.contains(WidgetState.selected)
                  ? AppColors.gold
                  : Colors.white70,
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith(
            (s) => IconThemeData(
              size: 24,
              color: s.contains(WidgetState.selected)
                  ? AppColors.gold
                  : Colors.white70,
            ),
          ),
        ),
        child: NavigationBar(
          height: 66,
          backgroundColor: const Color(0xFF040F2B),
          indicatorColor: AppColors.gold.withValues(alpha: 0.16),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          selectedIndex: atual < 0 ? itens.length : atual,
          onDestinationSelected: (i) =>
              i == itens.length ? onMais() : onSelecionar(itens[i]),
          destinations: [
            for (final m in itens)
              NavigationDestination(icon: Icon(m.icon), label: rotulo(m)),
            const NavigationDestination(
              icon: Icon(Icons.apps_rounded),
              label: 'Mais',
            ),
          ],
        ),
      ),
    );
  }
}
