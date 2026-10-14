import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marceloimob_gestao/core/di/injector.dart';
import 'package:marceloimob_gestao/core/errors/domain_exception.dart';
import 'package:marceloimob_gestao/core/theme/app_theme.dart';
import 'package:marceloimob_gestao/features/crm/domain/entities/enums.dart';
import 'package:marceloimob_gestao/features/crm/domain/entities/imovel.dart';
import 'package:marceloimob_gestao/features/crm/domain/repositories/imovel_repository.dart';
import 'package:marceloimob_gestao/features/manutencao/data/documentos/pdf_documentos_manutencao_gateway.dart';
import 'package:marceloimob_gestao/features/manutencao/domain/entities/manutencao.dart';
import 'package:marceloimob_gestao/features/manutencao/domain/repositories/manutencao_repository.dart';
import 'package:marceloimob_gestao/features/manutencao/domain/usecases/manutencao_usecases.dart';
import 'package:marceloimob_gestao/features/manutencao/presentation/widgets/manutencao_tab.dart';

Manutencao _manutencao({
  String id = 'm1',
  ContextoManutencao contexto = ContextoManutencao.locacao,
  TipoManutencao tipo = TipoManutencao.pintura,
  String tipoOutro = '',
  String imovelId = 'i1',
}) => Manutencao(
  id: id,
  contexto: contexto,
  imovelId: imovelId,
  tipo: tipo,
  tipoOutro: tipoOutro,
  descricao: 'Pintar a sala',
  criadaEm: DateTime(2026, 10, 1),
);

RegistroDiario _registro({String id = 'r1', double taxa = 100}) =>
    RegistroDiario(
      id: id,
      data: DateTime(2026, 10, 5),
      profissional: 'João Pintor',
      servico: 'Pintura da sala',
      material: 'Tinta',
      valorMaterial: 300,
      valorMaoDeObra: 700,
      valorTaxa: taxa,
    );

void main() {
  setUp(configurarDependencias);

  test('registro calcula serviços, taxa e total', () {
    final r = _registro();
    expect(r.valorServicos, 1000);
    expect(r.valorTaxa, 100);
    expect(r.valorTotal, 1100);
  });

  test('valida a pauta', () {
    final salvar = SalvarManutencao(sl());
    expect(
      () => salvar(_manutencao(imovelId: '')),
      throwsA(isA<DomainException>()),
    );
    expect(
      () => salvar(_manutencao(tipo: TipoManutencao.outros)),
      throwsA(isA<DomainException>()),
    );
  });

  test('diário muda status e é preservado ao editar a pauta', () async {
    final repo = sl<ManutencaoRepository>();
    await SalvarManutencao(sl())(_manutencao());
    await RegistrarDiario(sl())('m1', _registro());
    await RegistrarDiario(sl())('m1', _registro(id: 'r2', taxa: 0));

    var m = repo.porId('m1')!;
    expect(m.status, StatusManutencao.emAndamento);
    expect(m.diario, hasLength(2));
    expect(m.total, 2100);

    await SalvarManutencao(sl())(_manutencao());
    m = repo.porId('m1')!;
    expect(m.diario, hasLength(2));

    await RemoverRegistroDiario(sl())('m1', 'r2');
    expect(repo.porId('m1')!.diario, hasLength(1));

    expect(
      () => RegistrarDiario(sl())(
        'm1',
        RegistroDiario(
          id: 'x',
          data: DateTime(2026),
          profissional: '',
          servico: 'a',
        ),
      ),
      throwsA(isA<DomainException>()),
    );
  });

  test('pauta separada por módulo', () async {
    await SalvarManutencao(sl())(_manutencao());
    await SalvarManutencao(sl())(
      _manutencao(id: 'm2', contexto: ContextoManutencao.venda),
    );
    final locacao = await ObservarManutencoes(sl())(
      ContextoManutencao.locacao,
    ).first;
    expect(locacao.map((m) => m.id), ['m1']);
  });

  test('gera o PDF do diário e exige registros', () async {
    await sl<ImovelRepository>().salvar(
      Imovel(id: 'i1', codigo: 'AP01', titulo: 'Apto Barra'),
    );
    await SalvarManutencao(sl())(_manutencao());
    final imprimir = ImprimirDiarioManutencao(sl(), sl(), sl(), sl());
    await expectLater(imprimir.montar('m1'), throwsA(isA<DomainException>()));

    await RegistrarDiario(sl())('m1', _registro());
    await RegistrarDiario(sl())('m1', _registro(id: 'r2', taxa: 50));
    final doc = await imprimir.montar('m1');
    expect(doc.imovel?.codigo, 'AP01');
    final bytes = await PdfDocumentosManutencaoGateway().gerarDiario(doc);
    expect(latin1.decode(bytes.sublist(0, 4)), '%PDF');
    final destino = Platform.environment['DIARIO_PDF'];
    if (destino != null) File(destino).writeAsBytesSync(bytes);
  });

  testWidgets('aba lista a pauta e abre o diário', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await sl<ImovelRepository>().salvar(
      Imovel(
        id: 'i1',
        codigo: 'AP01',
        titulo: 'Apto Barra',
        finalidades: const {Finalidade.locacao},
      ),
    );
    await SalvarManutencao(sl())(_manutencao());
    await RegistrarDiario(sl())('m1', _registro());

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const Scaffold(
          body: ManutencaoTab(contexto: ContextoManutencao.locacao),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Pintar a sala'), findsOneWidget);
    expect(find.text('AP01 • Apto Barra'), findsWidgets);

    await tester.tap(find.text('Pintar a sala'));
    await tester.pumpAndSettle();
    expect(find.text('Diário'), findsOneWidget);
    expect(find.text('Pintura da sala'), findsOneWidget);
    expect(find.text('João Pintor'), findsOneWidget);

    await tester.tap(find.text('Registrar no diário'));
    await tester.pumpAndSettle();
    expect(find.text('Valor total dos serviços'), findsWidgets);
  });
}
