import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_imobiliaria/core/di/injector.dart';
import 'package:gestao_imobiliaria/features/equipe/domain/entities/equipe_enums.dart';
import 'package:gestao_imobiliaria/features/equipe/domain/entities/permissoes.dart';
import 'package:gestao_imobiliaria/features/equipe/domain/entities/usuario_sistema.dart';
import 'package:gestao_imobiliaria/features/equipe/domain/repositories/equipe_repositories.dart';
import 'package:gestao_imobiliaria/features/equipe/presentation/pages/equipe_seguranca_page.dart';
import 'package:gestao_imobiliaria/features/home/presentation/viewmodels/home_viewmodel.dart';
import 'package:gestao_imobiliaria/features/financeiro/presentation/pages/financeiro_page.dart';
import 'package:gestao_imobiliaria/features/financeiro/presentation/widgets/abrir_sicoob.dart';

void main() {
  setUp(configurarDependencias);

  Future<HomeViewModel> vmDe(PerfilAcesso perfil) async {
    final u = UsuarioSistema(
      id: 'u-${perfil.name}',
      nome: perfil.label,
      login: perfil.name,
      perfil: perfil,
      permissoes: Permissoes.perfil(perfil),
      criadoEm: DateTime(2026),
    );
    await sl<UsuarioRepository>().salvar(u);
    await sl<UsuarioAtualRepository>().definir(u.id);
    final vm = sl<HomeViewModel>();
    await Future<void>.delayed(Duration.zero);
    return vm;
  }

  Future<List<ModuloMenu>> menuDe(PerfilAcesso perfil) async {
    final vm = await vmDe(perfil);
    final menu = vm.modulosPermitidos;
    vm.dispose();
    return menu;
  }

  test('corretor vê só os módulos liberados', () async {
    expect(await menuDe(PerfilAcesso.corretor), [
      ModuloMenu.dashboard,
      ModuloMenu.cadastrosCrm,
      ModuloMenu.locacao,
      ModuloMenu.vendas,
      ModuloMenu.temporada,
      ModuloMenu.auditorias,
      ModuloMenu.contratosRelatorios,
      ModuloMenu.equipeSeguranca, // só fila e chat
      ModuloMenu.site, // só vê os leads
    ]);
  });

  test('administrador vê tudo, menos a Integração Sicoob', () async {
    final vm = await vmDe(PerfilAcesso.administrador);
    expect(vm.modulosPermitidos, [
      for (final m in ModuloMenu.values)
        if (m != ModuloMenu.integracaoSicoob) m,
    ]);
    vm.dispose();
  });

  testWidgets('Financeiro tem o botão Abrir banco (Sicoob por padrão)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: FinanceiroPage())),
    );
    await tester.pump();
    expect(find.text('Abrir banco'), findsOneWidget);
    expect(find.byTooltip('Editar link do banco'), findsOneWidget);
    expect(find.text('Abrir Sicoob'), findsNothing);
    expect(linkSicoob, 'https://ib.sicoob.com.br/sicoobnet/ib/#/login');
  });

  testWidgets('corretor vê só a fila e o chat na Equipe', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EquipeSegurancaPage(abaInicial: 5, completo: false),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Fila de atendimento'), findsOneWidget);
    expect(find.text('Chat interno'), findsOneWidget);
    expect(find.text('Usuários e sessões'), findsNothing);
    expect(find.text('Comissões'), findsNothing);
    expect(
      DefaultTabController.of(tester.element(find.byType(TabBar))).index,
      1,
    );
  });
}
