import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marceloimob_gestao/core/api/status_conexao.dart';
import 'package:marceloimob_gestao/core/di/injector.dart';
import 'package:marceloimob_gestao/core/errors/domain_exception.dart';
import 'package:marceloimob_gestao/core/theme/app_theme.dart';
import 'package:marceloimob_gestao/features/crm/domain/entities/enums.dart';
import 'package:marceloimob_gestao/features/crm/domain/entities/imovel.dart';
import 'package:marceloimob_gestao/features/crm/domain/repositories/imovel_repository.dart';
import 'package:marceloimob_gestao/features/site/data/repositories/site_repositories.dart';
import 'package:marceloimob_gestao/features/site/domain/entities/configuracao_site.dart';
import 'package:marceloimob_gestao/features/site/domain/entities/lead_site.dart';
import 'package:marceloimob_gestao/features/site/domain/repositories/site_repository.dart';
import 'package:marceloimob_gestao/features/site/domain/usecases/site_usecases.dart';
import 'package:marceloimob_gestao/features/site/presentation/pages/site_page.dart';

import '../../apoio/servidor_falso.dart';

Map<String, dynamic> _leadJson(String id, {String nome = 'Ana Souza'}) => {
  'id': id,
  'tipo': 'visita',
  'status': 'novo',
  'nome': nome,
  'email': 'ana@x.com',
  'telefone': '(21) 98888-7777',
  'mensagem': 'Quero visitar no sábado',
  'dataVisita': '2026-10-18T10:00:00',
  'imovelId': 'i1',
  'contatoId': 'c1',
  'corretorId': null,
  'observacao': '',
  'criadoEm': '2026-10-16T09:00:00',
};

void main() {
  group('API', () {
    late ServidorFalso servidor;
    late StatusConexao status;
    late SiteApiRepository repo;
    var chegaram = 0;

    setUp(() {
      servidor = ServidorFalso();
      status = StatusConexao();
      chegaram = 0;
      repo = SiteApiRepository(
        servidor.cliente(),
        status,
        endereco: 'http://servidor',
        aoChegarLead: () => chegaram++,
      );
    });

    test('configuração ida e volta, com validações', () async {
      final salvar = SalvarConfiguracaoSite(repo);
      final c = await salvar(
        const ConfiguracaoSite().copyWith(
          titulo: 'Seu novo lar',
          whatsapp: '(21) 99999-0000',
          mostrarValores: false,
          distribuirNaFila: false,
        ),
      );
      expect(c.whatsapp, '21999990000');
      final lida = await repo.obterConfiguracao();
      expect(
        (lida.titulo, lida.mostrarValores, lida.distribuirNaFila),
        ('Seu novo lar', false, false),
      );
      await expectLater(
        salvar(const ConfiguracaoSite(instagram: 'instagram.com/x')),
        throwsA(isA<DomainException>()),
      );
      await expectLater(
        salvar(const ConfiguracaoSite(whatsapp: '123')),
        throwsA(isA<DomainException>()),
      );
    });

    test('leads: status muda sem perder os dados do site', () async {
      servidor.colecao('site/leads')['l1'] = _leadJson('l1');
      final lead = (await repo.observarLeads().first).single;
      expect(
        (lead.tipo, lead.dataVisita),
        (TipoLead.visita, DateTime(2026, 10, 18, 10)),
      );
      await AtualizarLead(repo)(
        lead.copyWith(status: StatusLead.convertido, corretorId: 'u1'),
      );
      final salvo = servidor.colecao('site/leads')['l1']!;
      expect(
        (salvo['status'], salvo['corretorId'], salvo['nome']),
        ('convertido', 'u1', 'Ana Souza'),
      );
      expect(chegaram, 0); // primeira carga não conta como novidade
    });

    test('lead novo no servidor avisa para recarregar o CRM', () async {
      servidor.colecao('site/leads')['l1'] = _leadJson('l1');
      await repo.observarLeads().first;
      servidor.colecao('site/leads')['l2'] = _leadJson('l2', nome: 'Bruno');
      await status.tentarNovamente();
      expect(chegaram, 1);
      final nomes = (await repo.observarLeads().first).map((l) => l.nome);
      expect(nomes, contains('Bruno'));
    });
  });

  test('publicar e destacar imóvel', () async {
    await configurarDependencias();
    final imoveis = sl<ImovelRepository>();
    final i = Imovel(id: 'i1', codigo: 'IM-0001', titulo: 'Casa');
    await imoveis.salvar(i);
    final publicar = sl<PublicarImovelNoSite>();
    await expectLater(
      publicar(i, destaque: true),
      throwsA(isA<DomainException>()),
    );
    await publicar(i, publicar: true);
    await publicar((await imoveis.obter('i1'))!, destaque: true);
    var lido = (await imoveis.obter('i1'))!;
    expect((lido.publicarSite, lido.destaqueSite), (true, true));
    expect(pendenciasNoSite(lido), containsAll(['Sem fotos', 'Sem valor']));
    await publicar(lido, publicar: false); // tirar do site tira o destaque
    lido = (await imoveis.obter('i1'))!;
    expect((lido.publicarSite, lido.destaqueSite), (false, false));
  });

  testWidgets('menu do site: leads, imóveis e configurações', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await configurarDependencias();
    final repo = sl<SiteRepository>() as SiteMemoryRepository;
    repo.leads.upsert(
      LeadSite(
        id: 'l1',
        tipo: TipoLead.interesse,
        nome: 'Carla Cliente',
        telefone: '(21) 97777-6666',
        mensagem: 'Tem garagem?',
        criadoEm: DateTime(2026, 10, 16, 9),
      ),
    );
    await sl<ImovelRepository>().salvar(
      Imovel(
        id: 'i1',
        codigo: 'IM-0001',
        titulo: 'Apartamento Icaraí',
        valorVenda: 500000,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const Scaffold(body: SitePage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Carla Cliente'), findsOneWidget);
    expect(find.text('Novo (1)'), findsOneWidget);
    expect(find.text('WhatsApp'), findsOneWidget);

    await tester.tap(find.text('Imóveis no site'));
    await tester.pumpAndSettle();
    expect(find.text('Apartamento Icaraí'), findsOneWidget);
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect((await sl<ImovelRepository>().obter('i1'))!.publicarSite, isTrue);
    expect(find.text('No ar'), findsOneWidget);
    expect(find.textContaining('Sem fotos'), findsOneWidget);

    await tester.tap(find.text('Configurações do site'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Título da página inicial'),
      'Imóveis em Niterói',
    );
    await tester.tap(find.text('Salvar site'));
    await tester.pumpAndSettle();
    expect((await repo.obterConfiguracao()).titulo, 'Imóveis em Niterói');
    expect(find.text('Site atualizado.'), findsOneWidget);
    expect(StatusImovel.disponivel.label, isNotEmpty);
  });
}
