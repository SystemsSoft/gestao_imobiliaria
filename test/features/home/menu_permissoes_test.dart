import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marceloimob_gestao/core/di/injector.dart';
import 'package:marceloimob_gestao/features/equipe/domain/entities/equipe_enums.dart';
import 'package:marceloimob_gestao/features/equipe/domain/entities/permissoes.dart';
import 'package:marceloimob_gestao/features/equipe/domain/entities/usuario_sistema.dart';
import 'package:marceloimob_gestao/features/equipe/domain/repositories/equipe_repositories.dart';
import 'package:marceloimob_gestao/features/equipe/presentation/pages/equipe_seguranca_page.dart';
import 'package:marceloimob_gestao/features/home/presentation/viewmodels/home_viewmodel.dart';

void main() {
  setUp(configurarDependencias);

  Future<List<ModuloMenu>> menuDe(PerfilAcesso perfil) async {
    final u = UsuarioSistema(
      id: 'u-${perfil.name}',
      nome: perfil.label,
      email: '${perfil.name}@x.com',
      perfil: perfil,
      permissoes: Permissoes.perfil(perfil),
      criadoEm: DateTime(2026),
    );
    await sl<UsuarioRepository>().salvar(u);
    await sl<UsuarioAtualRepository>().definir(u.id);
    final vm = sl<HomeViewModel>();
    await Future<void>.delayed(Duration.zero);
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
      ModuloMenu.contratosRelatorios,
      ModuloMenu.equipeSeguranca, // só fila e chat
    ]);
  });

  test('administrador vê tudo', () async {
    expect(await menuDe(PerfilAcesso.administrador), ModuloMenu.values);
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
