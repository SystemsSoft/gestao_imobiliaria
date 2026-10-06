import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marceloimob_gestao/core/di/injector.dart';
import 'package:marceloimob_gestao/core/errors/domain_exception.dart';
import 'package:marceloimob_gestao/core/theme/app_theme.dart';
import 'package:marceloimob_gestao/features/crm/domain/entities/contato.dart';
import 'package:marceloimob_gestao/features/crm/domain/entities/enums.dart';
import 'package:marceloimob_gestao/features/crm/domain/entities/imovel.dart';
import 'package:marceloimob_gestao/features/crm/domain/repositories/contato_repository.dart';
import 'package:marceloimob_gestao/features/crm/domain/repositories/imovel_repository.dart';
import 'package:marceloimob_gestao/features/temporada/domain/entities/dia_calendario.dart';
import 'package:marceloimob_gestao/features/temporada/domain/entities/reserva.dart';
import 'package:marceloimob_gestao/features/temporada/domain/entities/reserva_enums.dart';
import 'package:marceloimob_gestao/features/temporada/domain/repositories/reserva_repository.dart';
import 'package:marceloimob_gestao/features/temporada/domain/services/calendario_temporada.dart';
import 'package:marceloimob_gestao/features/temporada/domain/usecases/reserva_usecases.dart';
import 'package:marceloimob_gestao/features/temporada/presentation/pages/temporada_page.dart';
import 'package:marceloimob_gestao/features/temporada/presentation/viewmodels/calendario_viewmodel.dart';

Reserva _r(
  String id,
  int diaIn,
  int diaOut, {
  String imovel = 'i1',
  SituacaoReserva situacao = SituacaoReserva.confirmada,
  double diaria = 500,
  bool bloqueio = false,
}) => Reserva(
  id: id,
  imovelId: imovel,
  hospedeId: bloqueio ? null : 'h1',
  bloqueio: bloqueio,
  checkIn: DateTime(2027, 1, diaIn),
  checkOut: DateTime(2027, 1, diaOut),
  valorDiaria: diaria,
  situacao: situacao,
);

void main() {
  const cal = CalendarioTemporada();

  group('Reserva', () {
    test('noites, total e saldo', () {
      final r = Reserva(
        id: 'a',
        imovelId: 'i1',
        checkIn: DateTime(2027, 1, 10, 15),
        checkOut: DateTime(2027, 1, 14, 11),
        valorDiaria: 400,
        taxaLimpeza: 150,
        desconto: 50,
        valorPago: 500,
      );
      expect(r.noites, 4);
      expect(r.total, 1700);
      expect(r.saldo, 1200);
    });

    test('estado é calculado automaticamente pelas datas', () {
      final r = _r('a', 10, 14);
      expect(r.estadoEm(DateTime(2027, 1, 9)), EstadoReserva.confirmada);
      expect(r.estadoEm(DateTime(2027, 1, 10)), EstadoReserva.hospedada);
      expect(r.estadoEm(DateTime(2027, 1, 13)), EstadoReserva.hospedada);
      expect(r.estadoEm(DateTime(2027, 1, 14)), EstadoReserva.concluida);
      expect(
        _r(
          'b',
          10,
          14,
          situacao: SituacaoReserva.preReserva,
        ).estadoEm(DateTime(2027, 1, 12)),
        EstadoReserva.preReserva,
      );
      expect(
        _r(
          'c',
          10,
          14,
          situacao: SituacaoReserva.cancelada,
        ).estadoEm(DateTime(2027, 1, 12)),
        EstadoReserva.cancelada,
      );
    });
  });

  group('CalendarioTemporada', () {
    test('o dia do check-out fica livre para outro check-in', () {
      final reservas = [_r('a', 10, 14)];
      expect(
        cal.conflitos(
          reservas,
          imovelId: 'i1',
          checkIn: DateTime(2027, 1, 14),
          checkOut: DateTime(2027, 1, 16),
        ),
        isEmpty,
      );
      expect(
        cal.conflitos(
          reservas,
          imovelId: 'i1',
          checkIn: DateTime(2027, 1, 13),
          checkOut: DateTime(2027, 1, 16),
        ),
        hasLength(1),
      );
      expect(
        cal.conflitos(
          reservas,
          imovelId: 'i1',
          checkIn: DateTime(2027, 1, 8),
          checkOut: DateTime(2027, 1, 10),
        ),
        isEmpty,
      );
    });

    test('ignora canceladas, outros imóveis e a própria reserva', () {
      final reservas = [
        _r('a', 10, 14, situacao: SituacaoReserva.cancelada),
        _r('b', 10, 14, imovel: 'i2'),
        _r('c', 10, 14),
      ];
      final args = (
        imovelId: 'i1',
        checkIn: DateTime(2027, 1, 11),
        checkOut: DateTime(2027, 1, 12),
      );
      expect(
        cal.conflitos(
          reservas,
          imovelId: args.imovelId,
          checkIn: args.checkIn,
          checkOut: args.checkOut,
        ),
        hasLength(1),
      );
      expect(
        cal.conflitos(
          reservas,
          imovelId: args.imovelId,
          checkIn: args.checkIn,
          checkOut: args.checkOut,
          ignorarId: 'c',
        ),
        isEmpty,
      );
    });

    test('dias do mês marcam check-in, check-out e virada de hóspede', () {
      final reservas = [_r('a', 10, 14), _r('b', 14, 16)];
      final dias = cal.diasDoMes(reservas, 'i1', 2027, 1);
      DiaCalendario dia(int d) => dias[d - 1];
      expect(dia(9).livre, isTrue);
      expect(dia(10).checkIn, isTrue);
      expect(dia(12).noite?.id, 'a');
      expect(dia(14).viradaDeHospede, isTrue);
      expect(dia(14).checkOut, isTrue);
      expect(dia(14).checkIn, isTrue);
      expect(dia(16).checkOut, isTrue);
      expect(dia(16).noite, isNull);
      expect(dia(17).livre, isTrue);
    });

    test('ocupação e receita proporcionais ao mês', () {
      // 28/12 → 04/01 = 7 noites; 3 delas (29, 30, 31/12) ... em janeiro: 1, 2, 3.
      final atravessa = Reserva(
        id: 'x',
        imovelId: 'i1',
        checkIn: DateTime(2026, 12, 28),
        checkOut: DateTime(2027, 1, 4),
        valorDiaria: 100,
      );
      final o = cal.ocupacao([atravessa, _r('a', 10, 14)], 'i1', 2027, 1);
      expect(o.noitesOcupadas, 3 + 4);
      expect(o.receita, 300 + 2000);
      expect(o.taxa, closeTo(7 / 31, 0.0001));
    });
  });

  group('SalvarReserva', () {
    setUp(() async {
      await configurarDependencias();
      await sl<ContatoRepository>().salvar(
        Contato(id: 'h1', nome: 'Ana Hóspede', criadoEm: DateTime(2026)),
      );
      await sl<ImovelRepository>().salvar(
        Imovel(
          id: 'i1',
          codigo: 'IM-0001',
          titulo: 'Casa de praia',
          finalidades: {Finalidade.temporada},
          valorTemporada: 500,
        ),
      );
    });

    test('numera, impede conflito e aceita virada no mesmo dia', () async {
      final salvar = sl<SalvarReserva>();
      expect((await salvar(_r('a', 10, 14))).numero, 'RES-0001');
      await expectLater(
        salvar(_r('b', 12, 15)),
        throwsA(isA<DomainException>()),
      );
      expect((await salvar(_r('c', 14, 17))).numero, 'RES-0002');
      expect(await sl<ReservaRepository>().listar(), hasLength(2));
    });

    test('bloqueio impede reservas; cancelar libera as datas', () async {
      final salvar = sl<SalvarReserva>();
      await salvar(_r('blk', 20, 25, bloqueio: true));
      await expectLater(
        salvar(_r('a', 22, 24)),
        throwsA(isA<DomainException>()),
      );

      final r = await salvar(_r('b', 1, 3));
      await sl<AlterarSituacaoReserva>()(r, SituacaoReserva.cancelada);
      expect((await salvar(_r('c', 1, 3))).numero, isNotEmpty);
      // Reativar a cancelada agora conflita.
      await expectLater(
        sl<AlterarSituacaoReserva>()(
          r.copyWith(situacao: SituacaoReserva.cancelada),
          SituacaoReserva.confirmada,
        ),
        throwsA(isA<DomainException>()),
      );
    });

    test('validações', () {
      final salvar = sl<SalvarReserva>();
      expect(() => salvar(_r('a', 14, 10)), throwsA(isA<DomainException>()));
      expect(
        () => salvar(
          Reserva(
            id: 'x',
            imovelId: 'i1',
            checkIn: DateTime(2027, 1, 1),
            checkOut: DateTime(2027, 1, 3),
            valorDiaria: 100,
          ),
        ),
        throwsA(isA<DomainException>()), // sem hóspede
      );
      expect(
        () => salvar(
          Reserva(
            id: 'y',
            imovelId: 'i1',
            hospedeId: 'h1',
            checkIn: DateTime(2027, 1, 1),
            checkOut: DateTime(2027, 1, 3),
            valorDiaria: 100,
            valorPago: 999,
          ),
        ),
        throwsA(isA<DomainException>()), // pago > total
      );
    });

    test('quitar registra o saldo', () async {
      final r = await sl<SalvarReserva>()(_r('a', 10, 12));
      await sl<QuitarReserva>()(r);
      final salva = (await sl<ReservaRepository>().obter('a'))!;
      expect(salva.saldo, 0);
      expect(() => sl<QuitarReserva>()(salva), throwsA(isA<DomainException>()));
    });

    test('painel do dia: chegadas, saídas e hospedados', () async {
      final salvar = sl<SalvarReserva>();
      await salvar(_r('a', 10, 14)); // hospedado em 12
      await salvar(_r('b', 14, 17)); // chega no dia 14
      final vm = CalendarioViewModel(
        sl(),
        sl(),
        sl(),
        sl(),
        agora: () => DateTime(2027, 1, 14, 9),
      );
      await Future<void>.delayed(Duration.zero);
      expect(vm.chegadasHoje.map((r) => r.id), ['b']);
      expect(vm.saidasHoje.map((r) => r.id), ['a']);
      expect(vm.hospedadosAgora.map((r) => r.id), ['b']);
      expect(vm.imoveis.single.codigo, 'IM-0001');
      vm.dispose();
    });
  });

  testWidgets('tela de temporada mostra o calendário e as reservas', (
    tester,
  ) async {
    await configurarDependencias();
    await sl<ContatoRepository>().salvar(
      Contato(id: 'h1', nome: 'Ana Hóspede', criadoEm: DateTime(2026)),
    );
    await sl<ImovelRepository>().salvar(
      Imovel(
        id: 'i1',
        codigo: 'IM-0001',
        titulo: 'Casa de praia',
        finalidades: {Finalidade.temporada},
        valorTemporada: 500,
      ),
    );
    final hoje = DateTime.now();
    await sl<SalvarReserva>()(
      Reserva(
        id: 'r1',
        imovelId: 'i1',
        hospedeId: 'h1',
        checkIn: DateTime(hoje.year, hoje.month, 1),
        checkOut: DateTime(hoje.year, hoje.month, 3),
        valorDiaria: 500,
      ),
    );

    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const Scaffold(body: TemporadaPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chegadas hoje'), findsOneWidget);
    expect(find.text('IM-0001'), findsWidgets);
    expect(find.text('Ana Hóspede'), findsWidgets);

    await tester.tap(find.text('Reservas'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Todas'));
    await tester.pumpAndSettle();
    expect(find.textContaining('RES-0001'), findsWidgets);
  });
}
