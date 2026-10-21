import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marceloimob_gestao/core/arquivos/arquivo_repository.dart';
import 'package:marceloimob_gestao/core/di/injector.dart';
import 'package:marceloimob_gestao/core/theme/app_theme.dart';
import 'package:marceloimob_gestao/features/crm/domain/entities/contato.dart';
import 'package:marceloimob_gestao/features/crm/domain/entities/enums.dart';
import 'package:marceloimob_gestao/features/crm/domain/repositories/contato_repository.dart';
import 'package:marceloimob_gestao/features/financeiro/domain/repositories/documento_repository.dart';
import 'package:marceloimob_gestao/features/financeiro/presentation/viewmodels/documentos_viewmodel.dart';
import 'package:marceloimob_gestao/features/financeiro/presentation/widgets/documentos_tab.dart';

ArquivoEscolhido _arquivo(String nome, [int tamanho = 10]) => ArquivoEscolhido(
  nome: nome,
  tamanho: tamanho,
  ler: () async => Uint8List(tamanho),
);

Future<DocumentosViewModel> _vm() async {
  final vm = sl<DocumentosViewModel>();
  await Future<void>.delayed(Duration.zero);
  return vm;
}

Future<void> _contatos() async {
  final repo = sl<ContatoRepository>();
  for (final (id, nome, papeis) in [
    ('ana', 'Ana Inquilina', {PapelContato.locatario}),
    ('beto', 'Beto Dono', {PapelContato.proprietario}),
    (
      'caio',
      'Caio Dono e Inquilino',
      {PapelContato.locatario, PapelContato.proprietario},
    ),
    ('lead', 'Lead Qualquer', {PapelContato.lead}),
  ]) {
    await repo.salvar(
      Contato(id: id, nome: nome, papeis: papeis, criadoEm: DateTime(2026)),
    );
  }
}

void main() {
  setUp(configurarDependencias);

  test('compartilha a pasta com inquilinos e proprietários', () async {
    await _contatos();
    final vm = await _vm();
    await vm.salvarPasta('Boletos');
    expect(await vm.carregarDestinatarios(), isTrue);
    expect(vm.destinatarios.map((d) => d.nome), [
      'Ana Inquilina',
      'Beto Dono',
      'Caio Dono e Inquilino',
    ]);
    final caio = vm.destinatarios.last;
    expect((caio.inquilino, caio.proprietario), (true, true));

    expect(await vm.compartilhar(vm.pastaId!, {'ana', 'beto'}), isTrue);
    expect(vm.pasta!.compartilhadaCom.toSet(), {'ana', 'beto'});
    expect(vm.compartilhadaCom(vm.pasta!).map((d) => d.nome), [
      'Ana Inquilina',
      'Beto Dono',
    ]);
    expect(await vm.compartilhar(vm.pastaId!, {}), isTrue);
    expect(vm.pasta!.compartilhadaCom, isEmpty);
    vm.dispose();
  });

  for (final (nome, tamanho) in [
    ('celular', const Size(360, 740)),
    ('computador', const Size(1400, 900)),
  ]) {
    testWidgets('ícone de compartilhar abre a lista e marca a pasta ($nome)', (
      tester,
    ) async {
      tester.view.physicalSize = tamanho;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await _contatos();
      await sl<DocumentoRepository>().salvarPasta('p1', 'Boletos');

      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(body: DocumentosTab()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byTooltip('Compartilhar com inquilinos e proprietários'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Compartilhar "Boletos"'), findsOneWidget);
      expect(find.text('Lead Qualquer'), findsNothing);

      await tester.tap(find.text('Proprietários'));
      await tester.pumpAndSettle();
      expect(find.text('Ana Inquilina'), findsNothing);
      await tester.tap(find.text('Marcar todos da lista (2)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Compartilhar com 2'));
      await tester.pumpAndSettle();

      expect(find.text('Vazia • compartilhada com 2'), findsOneWidget);
      expect(
        find.text('"Boletos" compartilhada com 2 pessoas.'),
        findsOneWidget,
      );
      expect(find.byTooltip('Compartilhada com 2 — alterar'), findsOneWidget);
      expect(
        (await sl<DocumentoRepository>().pastas()).single.compartilhadaCom
            .toSet(),
        {'beto', 'caio'},
      );
      expect(tester.takeException(), isNull);
    });
  }

  test('pastas: cria, abre, renomeia sem repetir nome e exclui', () async {
    final vm = await _vm();
    expect(await vm.salvarPasta('  Boletos '), isTrue);
    expect(vm.pasta?.nome, 'Boletos', reason: 'a pasta nova já abre');
    expect(await vm.salvarPasta('Relatórios'), isTrue);
    expect(vm.pastas.map((p) => p.nome), ['Boletos', 'Relatórios']);

    expect(await vm.salvarPasta('boletos'), isFalse);
    expect(vm.erro, 'Já existe uma pasta chamada "boletos".');
    expect(await vm.salvarPasta('   '), isFalse);

    final relatorios = vm.pasta!;
    expect(await vm.salvarPasta('Relatórios 2026', id: relatorios.id), isTrue);
    expect(vm.pastas.map((p) => p.nome), ['Boletos', 'Relatórios 2026']);

    expect(await vm.removerPasta(relatorios.id), isTrue);
    expect(vm.pastas.map((p) => p.nome), ['Boletos']);
    expect(vm.pasta, isNull);
    vm.dispose();
  });

  test('documentos: aceita só PDF, Word e Excel e permite editar', () async {
    final vm = await _vm();
    await vm.salvarPasta('Relatórios');
    final relatorios = vm.pastaId!;
    await vm.salvarPasta('Boletos');

    final enviados = await vm.enviar([
      _arquivo('Boleto Outubro.pdf'),
      _arquivo('Contrato.docx'),
      _arquivo('Planilha.xlsx'),
      _arquivo('foto.png'),
      _arquivo('enorme.pdf', 31 * 1024 * 1024),
    ]);
    expect(enviados, 3);
    expect(vm.erro, contains('"foto.png" não é aceito'));
    expect(vm.erro, contains('"enorme.pdf" é grande demais'));
    expect(vm.documentos.map((d) => d.nome), [
      'Boleto Outubro',
      'Contrato',
      'Planilha',
    ]);
    expect(vm.pasta!.documentos, 3);

    vm.buscar('planil');
    expect(vm.documentos.single.arquivoNome, 'Planilha.xlsx');
    vm.buscar('');

    final boleto = vm.documentos.first;
    expect(await vm.renomear(boleto, 'Boleto aluguel'), isTrue);
    expect(vm.documentos.first.nome, 'Boleto aluguel');
    expect(await vm.renomear(vm.documentos.first, ' '), isFalse);

    expect(
      await vm.substituir(vm.documentos.first, _arquivo('Novo.xls', 99)),
      isTrue,
    );
    final trocado = vm.documentos.first;
    expect(
      (trocado.nome, trocado.arquivoNome, trocado.tamanho),
      ('Boleto aluguel', 'Novo.xls', 99),
    );
    expect(await vm.substituir(trocado, _arquivo('nota.txt')), isFalse);
    expect(await sl<DocumentoRepository>().endereco(trocado), isNotNull);

    expect(await vm.mover(trocado, relatorios), isTrue);
    expect(vm.documentos.length, 2);
    expect(await vm.remover(vm.documentos.first), isTrue);
    expect(vm.documentos.single.nome, 'Planilha');

    await vm.abrirPasta(relatorios);
    expect(vm.documentos.single.nome, 'Boleto aluguel');
    vm.dispose();
  });

  test('duplicar cria a cópia na mesma pasta com o sufixo', () async {
    final vm = await _vm();
    await vm.salvarPasta('Boletos');
    await vm.enviar([_arquivo('Liquidação 20102026.pdf', 25)]);
    final original = vm.documentos.single;

    expect(await vm.duplicar(original), isTrue);
    expect(vm.ultimaCopia, 'Liquidação 20102026 (cópia)');
    expect(await vm.duplicar(original), isTrue);
    expect(vm.ultimaCopia, 'Liquidação 20102026 (cópia 2)');

    final copia = vm.documentos.firstWhere(
      (d) => d.nome == 'Liquidação 20102026 (cópia)',
    );
    expect(
      (copia.arquivoNome, copia.tamanho, copia.pastaId),
      ('Liquidação 20102026 (cópia).pdf', 25, original.pastaId),
    );
    expect(copia.arquivoId, isNot(original.arquivoId));
    expect(vm.pasta!.documentos, 3);

    await vm.remover(original);
    expect(await sl<DocumentoRepository>().endereco(copia), isNotNull);
    vm.dispose();
  });

  testWidgets('menu do documento tem Duplicar', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = sl<DocumentoRepository>();
    await repo.salvarPasta('p1', 'Boletos');
    await repo.enviar('p1', Uint8List(10), 'Relatório.xlsx');

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const Scaffold(body: DocumentosTab()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Boletos'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Opções do documento'));
    await tester.pumpAndSettle();
    expect(find.text('Duplicar'), findsOneWidget);
    await tester.tap(find.text('Duplicar'));
    await tester.pumpAndSettle();

    expect(find.text('Relatório (cópia)'), findsOneWidget);
    expect(find.text('Cópia criada: "Relatório (cópia)".'), findsOneWidget);
    expect((await repo.documentos('p1')).length, 2);
  });

  for (final (nome, tamanho) in [
    ('celular', const Size(360, 740)),
    ('computador', const Size(1400, 900)),
  ]) {
    testWidgets('tela cria pasta e mostra os documentos ($nome)', (
      tester,
    ) async {
      tester.view.physicalSize = tamanho;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repo = sl<DocumentoRepository>();
      final p = await repo.salvarPasta('p1', 'Boletos');
      await repo.enviar(p.id, Uint8List(2048), 'Boleto Outubro.pdf');

      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(body: DocumentosTab()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Boletos'), findsOneWidget);
      expect(find.text('1 documento'), findsOneWidget);

      await tester.tap(find.text('Nova pasta'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Relatórios');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();
      expect(find.text('Relatórios'), findsWidgets);
      expect(
        find.textContaining('Nenhum documento nesta pasta'),
        findsOneWidget,
      );

      if (tamanho.width < 900) {
        await tester.tap(find.byTooltip('Voltar às pastas'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Boletos'));
      await tester.pumpAndSettle();
      expect(find.text('Boleto Outubro'), findsOneWidget);
      expect(find.textContaining('Boleto Outubro.pdf • 2 KB'), findsOneWidget);
      expect(find.text('Enviar documentos'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
