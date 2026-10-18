import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marceloimob_gestao/core/di/injector.dart';
import 'package:marceloimob_gestao/core/errors/domain_exception.dart';
import 'package:marceloimob_gestao/core/theme/app_theme.dart';
import 'package:marceloimob_gestao/features/crm/domain/entities/contato.dart';
import 'package:marceloimob_gestao/features/locacao/domain/entities/contrato_locacao.dart';
import 'package:marceloimob_gestao/features/manutencao/data/models/manutencao_json.dart';
import 'package:marceloimob_gestao/features/manutencao/domain/entities/manutencao.dart';
import 'package:marceloimob_gestao/features/manutencao/domain/repositories/manutencao_repository.dart';
import 'package:marceloimob_gestao/features/manutencao/domain/usecases/manutencao_usecases.dart';
import 'package:marceloimob_gestao/features/portal_inquilino/data/repositories/portal_repositories.dart';
import 'package:marceloimob_gestao/features/portal_inquilino/domain/entities/portal.dart';
import 'package:marceloimob_gestao/features/portal_inquilino/domain/repositories/portal_repository.dart';
import 'package:marceloimob_gestao/features/portal_inquilino/domain/usecases/portal_usecases.dart';
import 'package:marceloimob_gestao/features/portal_inquilino/presentation/pages/portal_contrato_page.dart';

final _contrato = ContratoLocacao(
  id: 'c1',
  numero: 'LOC-0001',
  imovelId: 'i1',
  locatarioId: 'ana',
  beneficiarios: const [Beneficiario(contatoId: 'dono', percentual: 100)],
  dataInicio: DateTime(2026),
  valorAluguel: 3000,
);

Manutencao _chamado() => Manutencao(
  id: 'm1',
  contexto: ContextoManutencao.locacao,
  imovelId: 'i1',
  tipo: TipoManutencao.eletrica,
  descricao: 'Tomada soltando faísca',
  criadaEm: DateTime(2026, 10, 17),
  contratoId: 'c1',
  origem: OrigemManutencao.inquilino,
);

void main() {
  setUp(configurarDependencias);

  test('chamado do inquilino: contrato e origem vão e voltam no JSON', () {
    final j = manutencaoParaJson(_chamado());
    expect((j['contratoId'], j['origem']), ('c1', 'inquilino'));
    final lido = manutencaoDeJson({...j, 'id': 'm1'});
    expect((lido.contratoId, lido.doInquilino), ('c1', true));
  });

  test(
    'editar a pauta pelo formulário não desliga o chamado do contrato',
    () async {
      final repo = sl<ManutencaoRepository>();
      await repo.salvar(_chamado());
      // O formulário monta a manutenção sem contrato/origem.
      final editada = Manutencao(
        id: 'm1',
        contexto: ContextoManutencao.locacao,
        imovelId: 'i1',
        tipo: TipoManutencao.eletrica,
        descricao: 'Tomada da sala soltando faísca',
        criadaEm: DateTime(2026, 10, 17),
        status: StatusManutencao.emAndamento,
      );
      await sl<SalvarManutencao>()(editada);
      final salva = repo.porId('m1')!;
      expect(
        (salva.contratoId, salva.origem, salva.status),
        ('c1', OrigemManutencao.inquilino, StatusManutencao.emAndamento),
      );
    },
  );

  test(
    'aviso exige título e mensagem; texto de acesso para o inquilino',
    () async {
      await expectLater(
        sl<EnviarComunicado>()(titulo: ' ', mensagem: 'x'),
        throwsA(isA<DomainException>()),
      );
      final texto = mensagemDeAcesso(
        nome: 'Ana Souza',
        enderecoSite: 'http://18.191.168.173',
        senha: const SenhaProvisoria(login: '52998224725', senha: 'Abc23xyz9Q'),
      );
      expect(texto, contains('Olá, Ana!'));
      expect(texto, contains('http://18.191.168.173/inquilino'));
      expect(texto, contains('Abc23xyz9Q'));
    },
  );

  testWidgets(
    'página do contrato: libera acesso, mostra a senha e publica aviso',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await sl<ManutencaoRepository>().salvar(_chamado());
      final portal =
          sl<PortalInquilinoRepository>() as PortalInquilinoMemoryRepository;

      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: PortalContratoPage(
            contrato: _contrato,
            locatario: Contato(
              id: 'ana',
              nome: 'Ana Souza',
              documento: '529.982.247-25',
              celular: '(21) 98888-7777',
              criadoEm: DateTime(2026),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sem acesso'), findsOneWidget);
      expect(find.text('Tomada soltando faísca'), findsOneWidget); // chamado

      await tester.tap(find.text('Liberar acesso'));
      await tester.pumpAndSettle();
      expect(find.text('Acesso liberado'), findsOneWidget);
      expect(find.textContaining('Provisoria23'), findsOneWidget);
      expect(find.text('Enviar por WhatsApp'), findsOneWidget);
      await tester.tap(find.text('Concluir'));
      await tester.pumpAndSettle();
      expect(find.text('Senha provisória'), findsOneWidget);
      expect(portal.acessosPorContato.keys, ['ana']);

      await tester.tap(find.text('Novo aviso'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Título'),
        'Vistoria',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mensagem'),
        'Vistoria anual dia 20.',
      );
      await tester.tap(find.text('Publicar aviso'));
      await tester.pumpAndSettle();
      expect(portal.comunicadosPorId.values.single.contratoId, 'c1');
      expect(find.text('Vistoria anual dia 20.'), findsOneWidget);
    },
  );
}
