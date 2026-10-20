import 'package:flutter/material.dart';

import '../../../../core/api/status_conexao.dart';
import '../../../../core/config/empresa_info.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/errors/domain_exception.dart';
import '../../../../core/pwa/instalacao_app.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/visual_marca.dart';
import '../../../auditoria/presentation/pages/auditorias_page.dart';
import '../../../auth/domain/usecases/entrar.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../contratos/presentation/pages/contratos_relatorios_page.dart';
import '../../../crm/presentation/pages/cadastros_crm_page.dart';
import '../../../dashboard/presentation/pages/dashboard_page.dart';
import '../../../equipe/presentation/pages/equipe_seguranca_page.dart';
import '../../../financeiro/presentation/pages/financeiro_page.dart';
import '../../../fiscal/presentation/pages/fiscal_page.dart';
import '../../../integracao_sicoob/presentation/pages/integracao_sicoob_page.dart';
import '../../../integracao_sicoob/presentation/widgets/retorno_sicoob.dart';
import '../../../locacao/presentation/pages/administracao_locacao_page.dart';
import '../../../personalizacao/domain/usecases/personalizacao_usecases.dart';
import '../../../personalizacao/presentation/pages/personalizacao_page.dart';
import '../../../temporada/presentation/pages/temporada_page.dart';
import '../../../vendas/presentation/pages/administracao_vendas_page.dart';
import '../viewmodels/home_viewmodel.dart';
import '../widgets/baixar_app.dart';
import '../widgets/cabecalho_modulo.dart';
import '../widgets/menu_lateral.dart';
import '../widgets/navegacao_inferior.dart';
import '../../../site/presentation/pages/site_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

/// Largura a partir da qual o menu fica fixo ao lado do conteúdo.
const _larguraMenuFixo = 1100.0;

/// Abaixo desta largura (celular): barra inferior e título na barra do topo.
const _larguraCelular = 760.0;

class _HomePageState extends State<HomePage> {
  final _vm = sl<HomeViewModel>();

  @override
  void initState() {
    super.initState();
    _carregarPersonalizacao();
  }

  /// Dados e logotipo da imobiliária usados em todos os documentos.
  Future<void> _carregarPersonalizacao() async {
    try {
      await sl<CarregarPersonalizacao>()();
    } on DomainException {
      // Sem conexão: os documentos usam os dados padrão até a próxima vez.
    }
    if (mounted) setState(() {});
  }

  final _scaffold = GlobalKey<ScaffoldState>();
  bool _menuAberto = true;

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Widget _conteudo(ModuloMenu modulo) {
    final aba = _vm.abaInicial;
    return switch (modulo) {
      ModuloMenu.dashboard => DashboardPage(onNavegar: _irPara),
      ModuloMenu.cadastrosCrm => CadastrosCrmPage(abaInicial: aba),
      ModuloMenu.locacao => AdministracaoLocacaoPage(abaInicial: aba),
      ModuloMenu.vendas => AdministracaoVendasPage(abaInicial: aba),
      ModuloMenu.temporada => const TemporadaPage(),
      ModuloMenu.auditorias => AuditoriasPage(abaInicial: aba),
      ModuloMenu.financeiro => FinanceiroPage(abaInicial: aba),
      ModuloMenu.fiscal => const FiscalPage(),
      ModuloMenu.integracaoSicoob => IntegracaoSicoobPage(abaInicial: aba),
      ModuloMenu.contratosRelatorios => const ContratosRelatoriosPage(),
      ModuloMenu.equipeSeguranca => EquipeSegurancaPage(
        abaInicial: aba,
        completo: _vm.equipeCompleta,
      ),
      ModuloMenu.personalizacao => const PersonalizacaoPage(),
      ModuloMenu.site => SitePage(abaInicial: aba),
    };
  }

  /// Atalhos do dashboard para o módulo/aba correspondente.
  void _irPara(DestinoDashboard destino) {
    final (modulo, aba) = switch (destino) {
      DestinoDashboard.imoveis => (ModuloMenu.cadastrosCrm, 0),
      DestinoDashboard.clientes => (ModuloMenu.cadastrosCrm, 1),
      DestinoDashboard.oportunidades => (ModuloMenu.cadastrosCrm, 2),
      DestinoDashboard.agenda => (
        ModuloMenu.cadastrosCrm,
        abaCentralRelacionamento,
      ),
      DestinoDashboard.vendas => (ModuloMenu.vendas, 0),
      DestinoDashboard.locacoes => (ModuloMenu.locacao, 0),
      DestinoDashboard.cobrancas => (ModuloMenu.locacao, 1),
      DestinoDashboard.repasses => (ModuloMenu.locacao, 3),
      DestinoDashboard.temporada => (ModuloMenu.temporada, 0),
      DestinoDashboard.financeiro => (ModuloMenu.financeiro, 0),
      DestinoDashboard.boletos => (ModuloMenu.financeiro, 3),
      DestinoDashboard.atividades => (ModuloMenu.equipeSeguranca, 2),
    };
    _vm.selecionar(modulo, aba: aba);
  }

  Future<void> _sair() async {
    await sl<Sair>()();
    if (!mounted) return;
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
        final largura = MediaQuery.sizeOf(context).width;
        final menuFixo = largura >= _larguraMenuFixo;
        final celular = largura < _larguraCelular;
        final instalacao = sl<InstalacaoApp>();
        final menu = MenuLateral(
          selecionado: modulo,
          modulos: _vm.modulosPermitidos,
          compacto: celular,
          onSelecionar: (m) {
            if (!menuFixo) Navigator.of(context).pop();
            _vm.selecionar(m);
          },
          onBaixarApp: instalacao.mostrarOpcao
              ? () {
                  if (!menuFixo) Navigator.of(context).pop();
                  baixarApp(context);
                }
              : null,
          baixarParaDesktop: instalacao.computador,
          onAbrirSicoob: _vm.podeAbrirSicoob
              ? () {
                  if (!menuFixo) Navigator.of(context).pop();
                  abrirSicoob(context);
                }
              : null,
        );
        return Scaffold(
          key: _scaffold,
          backgroundColor: AppColors.navyDark,
          drawer: menuFixo
              ? null
              : Drawer(
                  width: 280,
                  backgroundColor: AppColors.navyDark,
                  child: SafeArea(child: menu),
                ),
          bottomNavigationBar: celular
              ? NavegacaoInferior(
                  permitidos: _vm.modulosPermitidos,
                  selecionado: modulo,
                  onSelecionar: _vm.selecionar,
                  onMais: () => _scaffold.currentState?.openDrawer(),
                )
              : null,
          body: FundoMarca(
            child: SafeArea(
              child: Row(
                children: [
                  if (menuFixo && _menuAberto) menu,
                  Expanded(
                    child: Column(
                      children: [
                        CabecalhoModulo(
                          vm: _vm,
                          modulo: celular ? modulo : null,
                          onBaixarDesktop:
                              !celular &&
                                  instalacao.computador &&
                                  instalacao.mostrarOpcao
                              ? () => baixarApp(context)
                              : null,
                          onMenu: () => menuFixo
                              ? setState(() => _menuAberto = !_menuAberto)
                              : _scaffold.currentState?.openDrawer(),
                          onSair: _sair,
                          onBuscar: (_) =>
                              _vm.selecionar(ModuloMenu.cadastrosCrm),
                        ),
                        const _AvisoConexao(),
                        if (!celular && modulo != ModuloMenu.dashboard)
                          _TituloModulo(modulo: modulo),
                        Expanded(
                          child: KeyedSubtree(
                            key: ValueKey('${modulo.name}-${_vm.versao}'),
                            child: _conteudo(modulo),
                          ),
                        ),
                        if (largura >= 760) const _Rodape(),
                      ],
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
}

/// Ícone e nome do módulo aberto.
class _TituloModulo extends StatelessWidget {
  const _TituloModulo({required this.modulo});

  final ModuloMenu modulo;

  @override
  Widget build(BuildContext context) {
    final estreito = MediaQuery.sizeOf(context).width < 760;
    return Padding(
      padding: EdgeInsets.fromLTRB(estreito ? 14 : 28, 14, 16, 10),
      child: Row(
        children: [
          Container(
            width: estreito ? 36 : 46,
            height: estreito ? 36 : 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              color: Colors.white.withValues(alpha: 0.04),
            ),
            child: Icon(
              modulo.icon,
              color: AppColors.gold,
              size: estreito ? 20 : 24,
            ),
          ),
          SizedBox(width: estreito ? 10 : 16),
          Expanded(
            child: Text(
              modulo.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: estiloTitulo(tamanho: estreito ? 20 : 26),
            ),
          ),
        ],
      ),
    );
  }
}

class _Rodape extends StatelessWidget {
  const _Rodape();

  @override
  Widget build(BuildContext context) {
    const estilo = TextStyle(color: Colors.white60, fontSize: 12);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: EmpresaInfo.nome,
                    style: const TextStyle(color: AppColors.gold),
                  ),
                  TextSpan(
                    text:
                        ' · ${EmpresaInfo.atividade}  |  ${EmpresaInfo.creci}',
                  ),
                ],
              ),
              style: estilo,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Text('Sistema de Gestão Imobiliária v1.0.0', style: estilo),
        ],
      ),
    );
  }
}

/// Faixa exibida quando os dados do servidor não puderam ser carregados.
class _AvisoConexao extends StatelessWidget {
  const _AvisoConexao();

  @override
  Widget build(BuildContext context) {
    final status = sl<StatusConexao>();
    return ListenableBuilder(
      listenable: status,
      builder: (context, _) {
        final erro = status.erro;
        if (erro == null) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          color: const Color(0xFFB3261E).withValues(alpha: 0.9),
          child: Row(
            children: [
              const Icon(Icons.cloud_off, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(erro, style: const TextStyle(color: Colors.white)),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                onPressed: status.tentarNovamente,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        );
      },
    );
  }
}
