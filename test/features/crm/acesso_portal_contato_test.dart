import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marceloimob_gestao/core/di/injector.dart';
import 'package:marceloimob_gestao/core/theme/app_theme.dart';
import 'package:marceloimob_gestao/features/auditoria/data/repositories/auditoria_repositories.dart';
import 'package:marceloimob_gestao/features/auditoria/domain/entities/auditoria.dart';
import 'package:marceloimob_gestao/features/auditoria/domain/repositories/auditoria_repository.dart';
import 'package:marceloimob_gestao/features/crm/domain/entities/contato.dart';
import 'package:marceloimob_gestao/features/crm/domain/entities/enums.dart';
import 'package:marceloimob_gestao/features/crm/presentation/pages/contato_form_page.dart';
import 'package:marceloimob_gestao/features/locacao/domain/entities/contrato_locacao.dart';
import 'package:marceloimob_gestao/features/locacao/domain/repositories/contrato_locacao_repository.dart';
import 'package:marceloimob_gestao/features/portal_inquilino/domain/repositories/portal_repository.dart';

Contato _contato(
  String id,
  String nome,
  Set<PapelContato> papeis, {
  String doc = '',
}) => Contato(
  id: id,
  nome: nome,
  papeis: papeis,
  documento: doc,
  criadoEm: DateTime(2026),
);

Future<void> _abrir(WidgetTester tester, Contato c, {Size? tamanho}) async {
  tester.view.physicalSize = tamanho ?? const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: ContatoFormPage(contato: c),
    ),
  );
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.text('Acesso ao portal (site)'),
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    await configurarDependencias();
    await sl<ContratoLocacaoRepository>().salvar(
      ContratoLocacao(
        id: 'c1',
        numero: 'LOC-0001',
        imovelId: 'i1',
        locatarioId: 'ana',
        beneficiarios: const [Beneficiario(contatoId: 'beto', percentual: 100)],
        dataInicio: DateTime(2026),
        valorAluguel: 3000,
      ),
    );
    (sl<AuditoriaRepository>() as AuditoriaMemoryRepository)
        .proprietariosLista = [
      const ResumoProprietario(
        contatoId: 'beto',
        nome: 'Beto Dono',
        documento: '111.444.777-35',
      ),
    ];
  });

  testWidgets('inquilino com contrato: libera, mostra a senha e revoga', (
    tester,
  ) async {
    await _abrir(
      tester,
      _contato('ana', 'Ana Inquilina', {
        PapelContato.locatario,
      }, doc: '529.982.247-25'),
    );
    expect(find.text('Área do inquilino'), findsOneWidget);
    expect(find.text('Área do proprietário'), findsNothing);
    expect(find.text('Sem acesso'), findsOneWidget);

    await tester.tap(find.text('Liberar acesso'));
    await tester.pumpAndSettle();
    expect(find.text('Acesso liberado'), findsOneWidget);
    expect(find.textContaining('Provisoria23'), findsWidgets);
    await tester.tap(find.text('Concluir'));
    await tester.pumpAndSettle();
    expect(
      (await sl<PortalInquilinoRepository>().acessos()).single.contatoId,
      'ana',
    );
    expect(find.text('Gerar nova senha'), findsOneWidget);

    await tester.tap(find.text('Revogar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    expect(await sl<PortalInquilinoRepository>().acessos(), isEmpty);
    expect(find.text('Liberar acesso'), findsOneWidget);
  });

  testWidgets('proprietário beneficiário libera a Área do proprietário', (
    tester,
  ) async {
    await _abrir(
      tester,
      _contato('beto', 'Beto Dono', {
        PapelContato.proprietario,
      }, doc: '111.444.777-35'),
    );
    expect(find.text('Área do proprietário'), findsOneWidget);
    await tester.tap(find.text('Liberar acesso'));
    await tester.pumpAndSettle();
    expect(find.text('Acesso liberado'), findsOneWidget);
    expect(
      (await sl<AuditoriaRepository>().proprietarios()).single.acesso,
      isNotNull,
    );
  });

  testWidgets('sem contrato: basta o CPF/CNPJ para liberar', (tester) async {
    await _abrir(
      tester,
      _contato('caio', 'Caio Sem Contrato', {
        PapelContato.locatario,
        PapelContato.proprietario,
      }, doc: '390.533.447-05'),
      tamanho: const Size(360, 2400),
    );
    expect(find.text('Área do inquilino'), findsOneWidget);
    expect(find.text('Área do proprietário'), findsOneWidget);
    expect(
      find.textContaining('Sem contrato de locação: no portal ele vê'),
      findsNWidgets(2),
    );
    await tester.tap(find.text('Liberar acesso').first);
    await tester.pumpAndSettle();
    expect(find.text('Acesso liberado'), findsOneWidget);
    await tester.tap(find.text('Concluir'));
    await tester.pumpAndSettle();
    expect(
      (await sl<PortalInquilinoRepository>().acessos()).single.contatoId,
      'caio',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('sem CPF/CNPJ salvo não libera', (tester) async {
    await _abrir(
      tester,
      _contato('dani', 'Dani Sem CPF', {PapelContato.proprietario}),
    );
    expect(
      find.text('Cadastre e salve o CPF/CNPJ: ele é o login.'),
      findsOneWidget,
    );
    final botao = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Liberar acesso'),
        matching: find.byWidgetPredicate((w) => w is FilledButton),
      ),
    );
    expect(botao.onPressed, isNull);
  });

  testWidgets('lead sem perfil de locatário/proprietário só recebe a dica', (
    tester,
  ) async {
    await _abrir(tester, _contato('lia', 'Lia Lead', {PapelContato.lead}));
    expect(
      find.textContaining('Marque o perfil "Locatário" e/ou "Proprietário"'),
      findsOneWidget,
    );
    expect(find.text('Liberar acesso'), findsNothing);
  });
}
