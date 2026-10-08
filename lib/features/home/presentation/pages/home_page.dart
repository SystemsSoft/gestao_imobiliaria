import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/visual_marca.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../contratos/presentation/pages/contratos_relatorios_page.dart';
import '../../../crm/presentation/pages/cadastros_crm_page.dart';
import '../../../equipe/presentation/pages/equipe_seguranca_page.dart';
import '../../../financeiro/presentation/pages/financeiro_page.dart';
import '../../../fiscal/presentation/pages/fiscal_page.dart';
import '../../../locacao/presentation/pages/administracao_locacao_page.dart';
import '../../../vendas/presentation/pages/administracao_vendas_page.dart';
import '../viewmodels/home_viewmodel.dart';
import '../widgets/cabecalho_modulo.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _vm = sl<HomeViewModel>();

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Widget _conteudo(ModuloMenu modulo) => switch (modulo) {
    ModuloMenu.cadastrosCrm => CadastrosCrmPage(abaInicial: _vm.abaInicial),
    ModuloMenu.locacao => const AdministracaoLocacaoPage(),
    ModuloMenu.vendas => const AdministracaoVendasPage(),
    ModuloMenu.financeiro => const FinanceiroPage(),
    ModuloMenu.fiscal => const FiscalPage(),
    ModuloMenu.contratosRelatorios => const ContratosRelatoriosPage(),
    ModuloMenu.equipeSeguranca => const EquipeSegurancaPage(),
    _ => Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(modulo.icon, size: 64, color: AppColors.gold),
          const SizedBox(height: 16),
          Text(
            modulo.label,
            style: const TextStyle(
              color: AppColors.gold,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  };

  final _scaffold = GlobalKey<ScaffoldState>();

  void _sair() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final modulo = _vm.selecionado;
        return Scaffold(
          key: _scaffold,
          backgroundColor: AppColors.navyDark,
          drawer: _buildDrawer(context),
          body: FundoMarca(
            child: SafeArea(
              child: Column(
                children: [
                  CabecalhoModulo(
                    vm: _vm,
                    onMenu: () => _scaffold.currentState?.openDrawer(),
                    onSair: _sair,
                  ),
                  Expanded(
                    child: KeyedSubtree(
                      key: ValueKey('${modulo.name}-${_vm.versao}'),
                      child: _conteudo(modulo),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.navyDark,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/logo_marcelo_bonifacio.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Divider(color: AppColors.gold.withValues(alpha: 0.3)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  for (final m in ModuloMenu.values)
                    ListTile(
                      leading: Icon(m.icon),
                      title: Text(m.label),
                      selected: m == _vm.selecionado,
                      selectedColor: AppColors.gold,
                      selectedTileColor: AppColors.gold.withValues(alpha: 0.12),
                      iconColor: Colors.white70,
                      textColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onTap: () {
                        _vm.selecionar(m);
                        Navigator.of(context).pop();
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
