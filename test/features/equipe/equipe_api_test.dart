import 'package:flutter_test/flutter_test.dart';
import 'package:marceloimob_gestao/core/api/api_client.dart';
import 'package:marceloimob_gestao/core/api/sessao_api.dart';
import 'package:marceloimob_gestao/core/api/status_conexao.dart';
import 'package:marceloimob_gestao/core/utils/id.dart';
import 'package:marceloimob_gestao/features/auth/data/repositories/auth_repository_api.dart';
import 'package:marceloimob_gestao/features/crm/data/datasources/crm_api_datasource.dart';
import 'package:marceloimob_gestao/features/crm/data/repositories/crm_api_repositories.dart';
import 'package:marceloimob_gestao/features/equipe/data/repositories/equipe_api_repositories.dart';
import 'package:marceloimob_gestao/features/equipe/domain/entities/chat.dart';
import 'package:marceloimob_gestao/features/equipe/domain/entities/equipe_enums.dart';
import 'package:marceloimob_gestao/features/equipe/domain/entities/fila.dart';
import 'package:marceloimob_gestao/features/equipe/domain/entities/permissoes.dart';
import 'package:marceloimob_gestao/features/equipe/domain/entities/usuario_sistema.dart';
import 'package:marceloimob_gestao/core/errors/domain_exception.dart';

import '../../apoio/servidor_falso.dart';

void main() {
  late ServidorFalso servidor;
  late SessaoApi sessao;
  late StatusConexao status;
  late ApiClient api;

  setUp(() {
    servidor = ServidorFalso();
    sessao = SessaoApi();
    status = StatusConexao();
    api = servidor.cliente(sessao: sessao);
  });

  test('login guarda o token e ele vai nas requisições; sair limpa', () async {
    final auth = AuthRepositoryApi(api, sessao, status);
    await expectLater(
      auth.entrar(email: 'admin@x.com', senha: 'errada'),
      throwsA(isA<ApiException>()),
    );
    expect(sessao.logado, isFalse);

    await auth.entrar(email: 'admin@x.com', senha: 'senha-certa');
    expect((sessao.usuarioId, sessao.logado), ('u-admin', true));
    await api.get('equipe/usuarios');
    expect(servidor.ultimoToken, 'Bearer token-de-teste');

    await auth.sair();
    expect(servidor.requisicoes.last, 'POST /api/v1/auth/sair');
    expect(sessao.logado, isFalse);
  });

  test('401 encerra a sessão e avisa para voltar ao login', () async {
    String? aviso;
    sessao.aoExpirar = (m) => aviso = m;
    sessao.iniciar(token: 't', usuarioId: 'u', sessaoId: 's');
    servidor.erros['crm'] = (401, 'Sua sessão expirou por inatividade.');
    await expectLater(api.get('crm/imoveis'), throwsA(isA<ApiException>()));
    expect(aviso, 'Sua sessão expirou por inatividade.');
    expect(sessao.logado, isFalse);
  });

  test('403 deixa o módulo vazio, sem faixa de erro', () async {
    servidor.erros['crm/imoveis'] = (403, 'Sem permissão.');
    final ds = CrmApiDataSource(api, status);
    expect(await ImovelApiRepository(ds).listar(), isEmpty);
    expect(status.erro, isNull);
  });

  group('equipe', () {
    late EquipeApiDataSource ds;
    setUp(() => ds = EquipeApiDataSource(api, sessao, status));

    test('usuário com senha; a senha não volta', () async {
      final repo = UsuarioApiRepository(ds);
      final u = UsuarioSistema(
        id: gerarId(),
        nome: 'Carla Corretora',
        email: 'carla@x.com',
        perfil: PerfilAcesso.corretor,
        permissoes: Permissoes.perfil(PerfilAcesso.corretor),
        criadoEm: DateTime(2026),
        atendeNaFila: true,
      );
      await repo.salvar(u, senha: 'senha-da-carla');
      final lido = (await repo.listar()).single;
      expect(lido.perfil, PerfilAcesso.corretor);
      expect(
        lido.permissoes.pode(ModuloSistema.vendas, AcaoPermissao.criar),
        isTrue,
      );
      expect(
        lido.permissoes.pode(
          ModuloSistema.financeiro,
          AcaoPermissao.visualizar,
        ),
        isFalse,
      );
      expect(servidor.colecao('equipe/usuarios')[u.id]!['senha'], isNull);
    });

    test('fila mantém a ordem e o chat marca lidas em lote', () async {
      final fila = FilaApiRepository(ds);
      await fila.salvar([
        ItemFila(
          usuarioId: 'b',
          status: StatusFila.disponivel,
          desde: DateTime(2026, 10, 16, 9),
        ),
        ItemFila(
          usuarioId: 'a',
          status: StatusFila.ausente,
          desde: DateTime(2026, 10, 16, 8),
        ),
      ]);
      expect((await fila.listar()).map((i) => i.usuarioId), ['b', 'a']);

      final chat = MensagemApiRepository(ds);
      final m = Mensagem(
        id: gerarId(),
        conversaId: conversaGeral,
        remetenteId: 'a',
        texto: 'Bom dia!',
        enviadaEm: DateTime(2026, 10, 16, 9),
      );
      await chat.salvar(m);
      await chat.salvarTodas([m.comLeitor('b')]);
      expect(servidor.requisicoes.last, 'PUT /api/v1/equipe/mensagens');
      expect((await chat.listar()).single.lidaPor, {'b'});
    });

    test('usuário atual vem do login e não pode ser trocado', () async {
      final atual = UsuarioAtualApiRepository(sessao);
      final ids = <String?>[];
      final sub = atual.observar().listen(ids.add);
      sessao.iniciar(token: 't', usuarioId: 'u1', sessaoId: 's');
      await Future<void>.delayed(Duration.zero);
      expect(ids, [null, 'u1']);
      expect(atual.permiteTrocar, isFalse);
      await expectLater(atual.definir('u2'), throwsA(isA<DomainException>()));
      await sub.cancel();
    });
  });
}
