import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marceloimob_gestao/core/arquivos/arquivo_repository.dart';
import 'package:marceloimob_gestao/core/di/injector.dart';
import 'package:marceloimob_gestao/core/theme/app_theme.dart';
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

void main() {
  setUp(configurarDependencias);

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
