import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marceloimob_gestao/core/di/injector.dart';
import 'package:marceloimob_gestao/features/equipe/domain/entities/equipe_enums.dart';
import 'package:marceloimob_gestao/features/equipe/domain/entities/permissoes.dart';
import 'package:marceloimob_gestao/features/equipe/domain/entities/usuario_sistema.dart';
import 'package:marceloimob_gestao/features/equipe/domain/repositories/equipe_repositories.dart';
import 'package:marceloimob_gestao/features/equipe/presentation/pages/equipe_seguranca_page.dart';
import 'package:marceloimob_gestao/features/home/presentation/viewmodels/home_viewmodel.dart';
import 'package:marceloimob_gestao/features/home/presentation/widgets/menu_lateral.dart';

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

  test('administrador vê tudo, menos Financeiro e Integração Sicoob', () async {
    final vm = await vmDe(PerfilAcesso.administrador);
    expect(vm.modulosPermitidos, [
      for (final m in ModuloMenu.values)
        if (!HomeViewModel.foraDoMenu.contains(m)) m,
    ]);
    expect(vm.modulosPermitidos, isNot(contains(ModuloMenu.financeiro)));
    expect(vm.podeAbrirSicoob, true);
    vm.dispose();
  });

  test('corretor não vê o Abrir Sicoob', () async {
    final vm = await vmDe(PerfilAcesso.corretor);
    expect(vm.podeAbrirSicoob, false);
    vm.dispose();
  });

  testWidgets('menu mostra "Abrir Sicoob" depois de Fiscal', (tester) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var aberto = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MenuLateral(
            selecionado: ModuloMenu.dashboard,
            modulos: [
              for (final m in ModuloMenu.values)
                if (!HomeViewModel.foraDoMenu.contains(m)) m,
            ],
            onSelecionar: (_) {},
            onAbrirSicoob: () => aberto++,
          ),
        ),
      ),
    );
    expect(find.text('Financeiro'), findsNothing);
    expect(find.text('Integração Sicoob'), findsNothing);
    final fiscal = tester.getTopLeft(find.text('Fiscal')).dy;
    final sicoob = tester.getTopLeft(find.text('Abrir Sicoob')).dy;
    final contratos = tester.getTopLeft(find.text('Contratos e Relatórios')).dy;
    expect(fiscal < sicoob && sicoob < contratos, true);
    await tester.tap(find.text('Abrir Sicoob'));
    expect(aberto, 1);
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
