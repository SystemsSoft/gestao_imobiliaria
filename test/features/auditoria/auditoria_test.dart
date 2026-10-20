import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:marceloimob_gestao/core/api/api_client.dart';
import 'package:marceloimob_gestao/core/arquivos/arquivo_repository.dart';
import 'package:marceloimob_gestao/core/di/injector.dart';
import 'package:marceloimob_gestao/core/errors/domain_exception.dart';
import 'package:marceloimob_gestao/core/theme/app_theme.dart';
import 'package:marceloimob_gestao/features/auditoria/data/repositories/auditoria_repositories.dart';
import 'package:marceloimob_gestao/features/auditoria/domain/entities/auditoria.dart';
import 'package:marceloimob_gestao/features/auditoria/domain/repositories/auditoria_repository.dart';
import 'package:marceloimob_gestao/features/auditoria/domain/usecases/auditoria_usecases.dart';
import 'package:marceloimob_gestao/features/auditoria/presentation/pages/auditoria_page.dart';
import 'package:marceloimob_gestao/features/auditoria/presentation/viewmodels/auditoria_viewmodels.dart';
import 'package:marceloimob_gestao/features/auditoria/presentation/widgets/proprietarios_auditoria_tab.dart';
import 'package:marceloimob_gestao/features/crm/domain/entities/imovel.dart';
import 'package:marceloimob_gestao/features/crm/domain/repositories/imovel_repository.dart';
import 'package:marceloimob_gestao/features/portal_inquilino/domain/entities/portal.dart';

const _id = '11111111-1111-4111-8111-111111111111';

final _jsonServidor = {
  'id': _id,
  'numero': 'AUD-0007',
  'imovelId': 'i1',
  'contratoId': 'c1',
  'proprietarioId': 'dono',
  'corretorId': null,
  'tipo': 'periodica',
  'status': 'concluida',
  'dataAgendada': '2026-10-10',
  'dataRealizada': '2026-10-12',
  'nota': 4,
  'resumo': 'Imóvel bem conservado.',
  'recomendacoes': '',
  'publicada': true,
  'concluidaEm': '2026-10-12T15:00:00',
  'concluidaPorId': 'u1',
  'itens': [
    {
      'id': 'it1',
      'area': 'Cozinha',
      'item': 'Torneiras e sifão',
      'estado': 'problema',
      'observacao': 'Torneira pingando',
      'manutencaoId': null,
    },
  ],
  'midias': [
    {
      'id': 'm1',
      'itemId': 'it1',
      'referencia': 'arquivo:abc',
      'tipo': 'video',
      'titulo': '',
      'transcricaoStatus': 'concluida',
      'transcricaoTexto': 'Na cozinha a torneira está pingando.',
      'transcricaoErro': '',
      'transcricaoEm': '2026-10-12T15:10:00',
      'criadoEm': '2026-10-12T14:00:00',
    },
  ],
  'criadoEm': '2026-10-10T09:00:00',
  'atualizadoEm': '2026-10-12T15:10:00',
};

ArquivoEscolhido _arquivo(String nome) => ArquivoEscolhido(
  nome: nome,
  tamanho: 3,
  ler: () async => Uint8List.fromList([1, 2, 3]),
);

void main() {
  setUp(configurarDependencias);

  group('API', () {
    late List<http.Request> pedidos;
    late AuditoriaApiRepository repo;

    setUp(() {
      pedidos = [];
      repo = AuditoriaApiRepository(
        ApiClient(
          'https://api.inovacloud.app',
          cliente: MockClient((r) async {
            pedidos.add(r);
            final corpo = r.url.path.endsWith('/relatorio')
                ? {'link': '/relatorio-auditoria/$_id?expira=1&assinatura=x'}
                : _jsonServidor;
            return http.Response(
              jsonEncode(corpo),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }),
        ),
      );
    });

    test('lê a auditoria do servidor com itens, vídeo e transcrição', () {
      final a = auditoriaDeJson(_jsonServidor);
      expect(
        (a.numero, a.concluida, a.publicada, a.nota),
        ('AUD-0007', true, true, 4),
      );
      expect(a.itens.single.estado, EstadoItem.problema);
      expect(a.problemasSemManutencao, 1);
      final v = a.midias.single;
      expect((v.video, v.itemId), (true, 'it1'));
      expect(v.transcricaoStatus, StatusTranscricao.concluida);
      expect(v.transcricaoTexto, contains('torneira está pingando'));
    });

    test('salva com PUT (sem status concluída) e pede transcrição', () async {
      final a = auditoriaDeJson(
        _jsonServidor,
      ).copyWith(status: StatusAuditoria.emAndamento);
      await repo.salvar(a);
      final put = pedidos.single;
      expect((put.method, put.url.path), ('PUT', '/api/v1/auditorias/$_id'));
      final corpo = jsonDecode(put.body) as Map<String, dynamic>;
      expect(corpo['status'], 'emAndamento');
      expect(corpo['dataAgendada'], '2026-10-10');
      expect((corpo['itens'] as List).single, {
        'id': 'it1',
        'area': 'Cozinha',
        'item': 'Torneiras e sifão',
        'estado': 'problema',
        'observacao': 'Torneira pingando',
      });

      await repo.transcrever(_id, 'm1');
      expect(
        (pedidos.last.method, pedidos.last.url.path),
        ('POST', '/api/v1/auditorias/$_id/midias/m1/transcrever'),
      );
    });

    test('link do relatório vira endereço completo do servidor', () async {
      final uri = await repo.linkRelatorio(_id);
      expect(
        uri.toString(),
        'https://api.inovacloud.app/relatorio-auditoria/$_id?expira=1&assinatura=x',
      );
    });
  });

  group('regras', () {
    test('nova auditoria usa o checklist do modelo', () {
      final a = novaAuditoria(
        imovelId: 'i1',
        modelo: const ModeloChecklist(
          id: 'm',
          nome: 'M',
          itens: [(area: 'Sala', item: 'Piso'), (area: 'Sala', item: 'Teto')],
        ),
      );
      expect(a.nova, true);
      expect(a.itens.map((i) => i.item), ['Piso', 'Teto']);
      expect(a.itens.every((i) => i.estado == EstadoItem.pendente), true);
    });

    test('concluir exige itens avaliados e nota', () {
      final a = novaAuditoria(
        imovelId: 'i1',
        modelo: const ModeloChecklist(
          id: 'm',
          nome: 'M',
          itens: [(area: 'Sala', item: 'Piso')],
        ),
      );
      expect(
        () => validarConclusao(a),
        throwsA(
          isA<DomainException>().having(
            (e) => e.mensagem,
            'mensagem',
            contains('1 sem avaliação'),
          ),
        ),
      );
      final avaliada = a.copyWith(
        itens: [a.itens.single.copyWith(estado: EstadoItem.ok)],
      );
      expect(() => validarConclusao(avaliada), throwsA(isA<DomainException>()));
      validarConclusao(avaliada.copyWith(nota: () => 5));
    });

    test(
      'mídia: só formatos aceitos; vídeo exige a categoria de vídeo',
      () async {
        final a = await sl<AuditoriaRepository>().salvar(
          novaAuditoria(imovelId: 'i1'),
        );
        await expectLater(
          sl<AnexarMidiaAuditoria>()(
            a,
            arquivo: _arquivo('planta.pdf'),
            tipo: TipoMidia.foto,
          ),
          throwsA(isA<DomainException>()),
        );
        final comVideo = await sl<AnexarMidiaAuditoria>()(
          a,
          arquivo: _arquivo('visita.mp4'),
          tipo: TipoMidia.video,
        );
        expect(comVideo.midias.single.video, true);
        expect(comVideo.midias.single.referencia, startsWith('arquivo:'));
      },
    );

    test('mensagem de acesso do proprietário', () {
      final t = mensagemDeAcessoProprietario(
        nome: 'Carlos Dono',
        enderecoSite: 'https://api.inovacloud.app',
        senha: const SenhaProvisoria(login: '52998224725', senha: 'X9y8Z7w6'),
      );
      expect(t, contains('Olá, Carlos!'));
      expect(t, contains('https://api.inovacloud.app/proprietario'));
      expect(t, contains('X9y8Z7w6'));
      expect(t, contains('transcrição'));
    });
  });

  group('formulário', () {
    test(
      'anexar vídeo salva a auditoria nova; transcrição é acompanhada',
      () async {
        final repo = sl<AuditoriaRepository>() as AuditoriaMemoryRepository;
        final vm = AuditoriaFormViewModel(
          novaAuditoria(imovelId: 'i1', modelo: (await repo.modelos()).first),
          sl(),
          sl(),
          sl(),
          sl(),
          repo,
          sl(),
          intervaloTranscricao: const Duration(milliseconds: 10),
        );
        addTearDown(vm.dispose);

        expect(
          await vm.anexar([(_arquivo('sala.mp4'), TipoMidia.video)]),
          true,
        );
        expect(vm.auditoria.nova, false); // salvou antes de anexar
        await vm.aguardarEnvios();
        expect(vm.auditoria.numero, 'AUD-0001');
        final video = vm.auditoria.midias.single;

        expect(await vm.transcrever(video), true);
        expect(
          vm.auditoria.midias.single.transcricaoStatus,
          StatusTranscricao.pendente,
        );

        // Enquanto a fila trabalha, o corretor continua avaliando.
        vm.avaliar(vm.auditoria.itens.first, EstadoItem.atencao);
        final a = repo.auditorias[vm.auditoria.id]!;
        repo.auditorias[a.id] = Auditoria(
          id: a.id,
          numero: a.numero,
          imovelId: a.imovelId,
          itens: a.itens,
          midias: [
            AuditoriaMemoryRepository.concluirTranscricao(
              a.midias.single,
              'A sala está em bom estado.',
            ),
          ],
        );
        await Future<void>.delayed(const Duration(milliseconds: 40));
        final m = vm.auditoria.midias.single;
        expect(m.transcricaoTexto, 'A sala está em bom estado.');
        expect(vm.auditoria.itens.first.estado, EstadoItem.atencao);
        expect(vm.alterada, true); // a edição não foi perdida
      },
    );

    test(
      'envio em segundo plano: a tela segue livre e nada se perde',
      () async {
        final repo = sl<AuditoriaRepository>() as AuditoriaMemoryRepository;
        final vm = AuditoriaFormViewModel(
          novaAuditoria(imovelId: 'i1', modelo: (await repo.modelos()).first),
          sl(),
          sl(),
          sl(),
          sl(),
          repo,
          sl(),
        );
        addTearDown(vm.dispose);
        final liberar = Completer<void>();
        final lento = ArquivoEscolhido(
          nome: 'cozinha.mp4',
          tamanho: 3,
          ler: () async {
            await liberar.future; // upload demorado
            return Uint8List.fromList([1, 2, 3]);
          },
        );

        expect(
          await vm.anexar([
            (lento, TipoMidia.video),
            (_arquivo('sala.jpg'), TipoMidia.foto),
          ]),
          true,
        );
        expect(vm.ocupado, false); // não trava a tela
        expect((vm.enviando, vm.envios.length), (true, 2));

        // Enquanto sobe, o corretor avalia e escreve; concluir espera.
        vm.avaliar(vm.auditoria.itens.first, EstadoItem.problema);
        vm.observarItem(vm.auditoria.itens.first, 'Sifão vazando');
        expect(await vm.concluir(publicar: false), false);
        expect(vm.erro, contains('Aguarde o envio'));

        liberar.complete();
        await vm.aguardarEnvios();
        expect(vm.envios, isEmpty);
        expect(vm.auditoria.midias.map((m) => m.tipo), [
          TipoMidia.video,
          TipoMidia.foto,
        ]);
        // As respostas do servidor trocaram só as mídias.
        expect(vm.auditoria.itens.first.estado, EstadoItem.problema);
        expect(vm.auditoria.itens.first.observacao, 'Sifão vazando');

        // Formato inválido é recusado na hora, sem entrar na fila.
        expect(
          await vm.anexar([(_arquivo('planta.pdf'), TipoMidia.foto)]),
          false,
        );
        expect(vm.envios, isEmpty);
      },
    );

    testWidgets('avalia, conclui e publica para o proprietário', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await sl<ImovelRepository>().salvar(
        Imovel(id: 'i1', codigo: 'AP-01', titulo: 'Apto Centro'),
      );
      final repo = sl<AuditoriaRepository>() as AuditoriaMemoryRepository;
      final modelo = (await repo.modelos()).first;
      final a = await repo.salvar(
        novaAuditoria(imovelId: 'i1', modelo: modelo),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: AuditoriaPage(auditoria: a, modelos: [modelo]),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Checklist (0 de 3 avaliados)'), findsOneWidget);

      // "Restantes OK" em cada área.
      while (find.text('Restantes OK').evaluate().isNotEmpty) {
        await tester.tap(find.text('Restantes OK').first);
        await tester.pump();
      }
      expect(find.text('Checklist (3 de 3 avaliados)'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.star_border).at(3)); // nota 4
      await tester.pump();

      await tester.tap(find.text('Concluir auditoria'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Concluir e publicar'));
      await tester.pumpAndSettle();

      final salva = repo.auditorias[a.id]!;
      expect((salva.concluida, salva.publicada, salva.nota), (true, true, 4));
      expect(find.textContaining('Concluída em'), findsOneWidget);
      expect(find.text('Reabrir'), findsOneWidget);
      expect(find.text('Salvar'), findsNothing); // travada
    });
  });

  testWidgets('proprietários: libera o acesso e mostra a senha uma vez', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = sl<AuditoriaRepository>() as AuditoriaMemoryRepository;
    repo.proprietariosLista = [
      const ResumoProprietario(
        contatoId: 'dono',
        nome: 'Carlos Dono',
        imoveis: 2,
        contratosAtivos: 1,
        saude: Saude.vermelho,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const Scaffold(body: ProprietariosAuditoriaTab()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Carlos Dono'), findsOneWidget);
    expect(find.text('Sem acesso'), findsOneWidget);

    await tester.tap(find.text('Liberar acesso'));
    await tester.pumpAndSettle();
    expect(find.text('Acesso liberado'), findsOneWidget);
    expect(find.textContaining('Provisoria23'), findsOneWidget);
    await tester.tap(find.text('Concluir'));
    await tester.pumpAndSettle();
    expect(find.text('Acesso ativo'), findsNothing); // ainda provisória
    expect(find.text('Senha provisória'), findsOneWidget);
    expect(repo.acessos, {'dono'});
  });
}
