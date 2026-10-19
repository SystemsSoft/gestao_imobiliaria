import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marceloimob_gestao/core/di/injector.dart';
import 'package:marceloimob_gestao/core/theme/app_theme.dart';
import 'package:marceloimob_gestao/features/crm/presentation/pages/contato_form_page.dart';
import 'package:marceloimob_gestao/features/crm/presentation/pages/imovel_form_page.dart';
import 'package:marceloimob_gestao/features/financeiro/presentation/pages/lancamento_form_page.dart';
import 'package:marceloimob_gestao/features/home/presentation/pages/home_page.dart';
import 'package:marceloimob_gestao/features/home/presentation/viewmodels/home_viewmodel.dart';
import 'package:marceloimob_gestao/features/locacao/presentation/pages/contrato_form_page.dart';
import 'package:marceloimob_gestao/features/temporada/presentation/pages/reserva_form_page.dart';
import 'package:marceloimob_gestao/features/vendas/presentation/pages/venda_form_page.dart';

/// Celulares comuns (largura × altura lógicas).
const _telas = [Size(360, 740), Size(412, 915)];

/// Registra os erros de layout (overflow) em vez de falhar no primeiro.
List<String> _capturarErros() {
  final erros = <String>[];
  final anterior = FlutterError.onError;
  FlutterError.onError = (d) => erros.add(d.exceptionAsString().split('\n').first);
  addTearDown(() => FlutterError.onError = anterior);
  return erros;
}

void _celular(WidgetTester tester, Size tela) {
  tester.view.physicalSize = tela;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(configurarDependencias);

  for (final tela in _telas) {
    final nome = '${tela.width.toInt()}x${tela.height.toInt()}';

    testWidgets('módulos e abas cabem no celular ($nome)', (tester) async {
      _celular(tester, tela);
      final erros = _capturarErros();
      await tester.pumpWidget(
        MaterialApp(theme: buildAppTheme(), home: const HomePage()),
      );
      await tester.pumpAndSettle();
      final vm = sl<HomeViewModel>();
      final problemas = <String>[];
      for (final m in ModuloMenu.values) {
        vm.selecionar(m);
        await tester.pumpAndSettle();
        final abas = find.byType(Tab);
        final total = abas.evaluate().length;
        for (var i = 0; i < (total == 0 ? 1 : total); i++) {
          if (total > 0) {
            await tester.tap(abas.at(i), warnIfMissed: false);
            await tester.pumpAndSettle();
          }
          if (erros.isNotEmpty) {
            problemas.add('${m.label} / aba $i: ${erros.toSet().join(' | ')}');
            erros.clear();
          }
        }
      }
      expect(problemas, isEmpty, reason: problemas.join('\n'));
    });

    final formularios = <String, Widget>{
      'contato': const ContatoFormPage(),
      'imóvel': const ImovelFormPage(),
      'contrato de locação': const ContratoFormPage(),
      'venda': const VendaFormPage(),
      'reserva': const ReservaFormPage(),
      'lançamento': const LancamentoFormPage(),
    };
    for (final MapEntry(key: titulo, value: pagina) in formularios.entries) {
      testWidgets('formulário de $titulo cabe no celular ($nome)', (
        tester,
      ) async {
        _celular(tester, tela);
        final erros = _capturarErros();
        await tester.pumpWidget(
          MaterialApp(theme: buildAppTheme(), home: pagina),
        );
        await tester.pumpAndSettle();
        expect(erros.toSet(), isEmpty);
      });
    }
  }
}
