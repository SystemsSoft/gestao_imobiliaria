import 'dart:async';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/sessao_api.dart';
import '../../../../core/api/status_conexao.dart';
import '../../../../core/data/remote_collection.dart';
import '../../../../core/errors/domain_exception.dart';
import '../../domain/entities/atividade.dart';
import '../../domain/entities/chat.dart';
import '../../domain/entities/comissao_equipe.dart';
import '../../domain/entities/fila.dart';
import '../../domain/entities/sessao.dart';
import '../../domain/entities/usuario_sistema.dart';
import '../../domain/repositories/equipe_repositories.dart';
import '../models/equipe_json.dart';

Future<List<Map<String, dynamic>>> _lista(
  ApiClient api,
  String caminho,
) async => (await api.get(caminho) as List).cast<Map<String, dynamic>>();

/// Equipe no servidor (`/api/v1/equipe`), com cache local. Chat, fila e
/// sessões se atualizam sozinhos enquanto estão na tela.
class EquipeApiDataSource {
  EquipeApiDataSource(this.api, this.sessao, StatusConexao status)
    : usuarios = RemoteCollection(
        idOf: (e) => e.id,
        status: status,
        carregar: () async => [
          for (final j in await _lista(api, 'equipe/usuarios'))
            usuarioDeJson(j),
        ],
      ),
      sessoes = RemoteCollection(
        idOf: (e) => e.id,
        status: status,
        intervalo: const Duration(seconds: 30),
        carregar: () async => [
          for (final j in await _lista(api, 'equipe/sessoes')) sessaoDeJson(j),
        ],
      ),
      configuracao = RemoteCollection(
        idOf: (_) => 'config',
        status: status,
        carregar: () async => [
          configuracaoDeJson(
            await api.get('equipe/configuracao') as Map<String, dynamic>,
          ),
        ],
      ),
      atividades = RemoteCollection(
        idOf: (e) => e.id,
        status: status,
        carregar: () async => [
          for (final j in await _lista(api, 'equipe/atividades'))
            atividadeDeJson(j),
        ],
      ),
      fila = RemoteCollection(
        // A ordem da fila é a da lista; a chave guarda a posição.
        idOf: (e) => e.usuarioId,
        status: status,
        intervalo: const Duration(seconds: 15),
        carregar: () async => [
          for (final j in await _lista(api, 'equipe/fila')) itemFilaDeJson(j),
        ],
      ),
      atendimentos = RemoteCollection(
        idOf: (e) => e.id,
        status: status,
        intervalo: const Duration(seconds: 15),
        carregar: () async => [
          for (final j in await _lista(api, 'equipe/atendimentos'))
            atendimentoDeJson(j),
        ],
      ),
      regras = RemoteCollection(
        idOf: (e) => e.usuarioId,
        status: status,
        carregar: () async => [
          for (final j in await _lista(api, 'equipe/comissoes/regras'))
            regraDeJson(j),
        ],
      ),
      comissoes = RemoteCollection(
        idOf: (e) => e.id,
        status: status,
        carregar: () async => [
          for (final j in await _lista(api, 'equipe/comissoes'))
            comissaoDeJson(j),
        ],
      ),
      mensagens = RemoteCollection(
        idOf: (e) => e.id,
        status: status,
        intervalo: const Duration(seconds: 10),
        carregar: () async => [
          for (final j in await _lista(api, 'equipe/mensagens'))
            mensagemDeJson(j),
        ],
      );

  final ApiClient api;
  final SessaoApi sessao;
  final RemoteCollection<UsuarioSistema> usuarios;
  final RemoteCollection<SessaoUsuario> sessoes;
  final RemoteCollection<ConfiguracaoSeguranca> configuracao;
  final RemoteCollection<Atividade> atividades;
  final RemoteCollection<ItemFila> fila;
  final RemoteCollection<Atendimento> atendimentos;
  final RemoteCollection<RegraComissao> regras;
  final RemoteCollection<LancamentoComissao> comissoes;
  final RemoteCollection<Mensagem> mensagens;
}

class UsuarioApiRepository implements UsuarioRepository {
  const UsuarioApiRepository(this._ds);
  final EquipeApiDataSource _ds;

  @override
  Stream<List<UsuarioSistema>> observar() => _ds.usuarios.watch();

  @override
  Future<List<UsuarioSistema>> listar() => _ds.usuarios.all();

  @override
  Future<UsuarioSistema?> obter(String id) => _ds.usuarios.byId(id);

  @override
  Future<void> salvar(UsuarioSistema u, {String? senha}) async {
    final json = await _ds.api.put(
      'equipe/usuarios/${u.id}',
      usuarioParaJson(u, senha: senha),
    );
    _ds.usuarios.cache.upsert(usuarioDeJson(json as Map<String, dynamic>));
    // Desativar derruba as sessões do usuário no servidor.
    if (!u.ativo) {
      _ds.sessoes.cache.removeWhere((s) => s.usuarioId == u.id);
    }
  }

  @override
  Future<void> remover(String id) async {
    await _ds.api.delete('equipe/usuarios/$id');
    _ds.usuarios.cache.removeWhere((e) => e.id == id);
  }
}

class SessaoApiRepository implements SessaoRepository {
  const SessaoApiRepository(this._ds);
  final EquipeApiDataSource _ds;

  @override
  Stream<List<SessaoUsuario>> observar() => _ds.sessoes.watch();

  @override
  Future<List<SessaoUsuario>> listar() => _ds.sessoes.all();

  /// As sessões nascem no login, no servidor.
  @override
  Future<void> salvar(SessaoUsuario sessao) async {}

  @override
  Future<void> remover(String id) async {
    await _ds.api.delete('equipe/sessoes/$id');
    _ds.sessoes.cache.removeWhere((e) => e.id == id);
  }

  /// O servidor já encerra as sessões ao desativar ou excluir o usuário.
  @override
  Future<void> removerDoUsuario(String usuarioId) async =>
      _ds.sessoes.cache.removeWhere((e) => e.usuarioId == usuarioId);
}

class ConfiguracaoSegurancaApiRepository
    implements ConfiguracaoSegurancaRepository {
  const ConfiguracaoSegurancaApiRepository(this._ds);
  final EquipeApiDataSource _ds;

  @override
  Stream<ConfiguracaoSeguranca> observar() => _ds.configuracao.watch().map(
    (l) => l.firstOrNull ?? const ConfiguracaoSeguranca(),
  );

  @override
  Future<ConfiguracaoSeguranca> obter() async =>
      (await _ds.configuracao.all()).firstOrNull ??
      const ConfiguracaoSeguranca();

  @override
  Future<void> salvar(ConfiguracaoSeguranca c) async {
    final json = await _ds.api.put(
      'equipe/configuracao',
      configuracaoParaJson(c),
    );
    _ds.configuracao.cache.upsert(
      configuracaoDeJson(json as Map<String, dynamic>),
    );
  }
}

/// Usuário atual = quem entrou com e-mail e senha.
class UsuarioAtualApiRepository implements UsuarioAtualRepository {
  const UsuarioAtualApiRepository(this._sessao);
  final SessaoApi _sessao;

  @override
  Stream<String?> observar() {
    late final StreamController<String?> c;
    void avisar() => c.add(_sessao.usuarioId);
    c = StreamController<String?>(
      onListen: () {
        avisar();
        _sessao.addListener(avisar);
      },
      onCancel: () => _sessao.removeListener(avisar),
    );
    return c.stream;
  }

  @override
  Future<String?> obter() async => _sessao.usuarioId;

  @override
  Future<void> definir(String usuarioId) async {
    if (usuarioId == _sessao.usuarioId) return;
    throw const DomainException(
      'Para usar outro usuário, saia e entre com o login dele.',
    );
  }

  @override
  bool get permiteTrocar => false;

  @override
  String? get sessaoAtualId => _sessao.sessaoId;
}

class AtividadeApiRepository implements AtividadeRepository {
  const AtividadeApiRepository(this._ds);
  final EquipeApiDataSource _ds;

  @override
  Stream<List<Atividade>> observar() => _ds.atividades.watch();

  /// O servidor grava o autor a partir do login.
  @override
  Future<void> salvar(Atividade a) async {
    final json = await _ds.api.put(
      'equipe/atividades/${a.id}',
      atividadeParaJson(a),
    );
    _ds.atividades.cache.upsert(atividadeDeJson(json as Map<String, dynamic>));
  }
}

class FilaApiRepository implements FilaRepository {
  const FilaApiRepository(this._ds);
  final EquipeApiDataSource _ds;

  @override
  Stream<List<ItemFila>> observar() => _ds.fila.watch();

  @override
  Future<List<ItemFila>> listar() => _ds.fila.all();

  @override
  Future<void> salvar(List<ItemFila> fila) async {
    final json = await _ds.api.put('equipe/fila', [
      for (final i in fila) itemFilaParaJson(i),
    ]);
    _ds.fila.cache.substituir([
      for (final j in json as List) itemFilaDeJson(j as Map<String, dynamic>),
    ]);
  }
}

class AtendimentoApiRepository implements AtendimentoRepository {
  const AtendimentoApiRepository(this._ds);
  final EquipeApiDataSource _ds;

  @override
  Stream<List<Atendimento>> observar() => _ds.atendimentos.watch();

  @override
  Future<Atendimento?> obter(String id) => _ds.atendimentos.byId(id);

  @override
  Future<void> salvar(Atendimento a) async {
    final json = await _ds.api.put(
      'equipe/atendimentos/${a.id}',
      atendimentoParaJson(a),
    );
    _ds.atendimentos.cache.upsert(
      atendimentoDeJson(json as Map<String, dynamic>),
    );
  }
}

class ComissaoEquipeApiRepository implements ComissaoEquipeRepository {
  const ComissaoEquipeApiRepository(this._ds);
  final EquipeApiDataSource _ds;

  @override
  Stream<List<RegraComissao>> observarRegras() => _ds.regras.watch();

  @override
  Future<RegraComissao?> obterRegra(String usuarioId) =>
      _ds.regras.byId(usuarioId);

  @override
  Future<void> salvarRegra(RegraComissao r) async {
    final json = await _ds.api.put(
      'equipe/comissoes/regras/${r.usuarioId}',
      regraParaJson(r),
    );
    _ds.regras.cache.upsert(regraDeJson(json as Map<String, dynamic>));
  }

  @override
  Stream<List<LancamentoComissao>> observarLancamentos() =>
      _ds.comissoes.watch();

  @override
  Future<LancamentoComissao?> obterLancamento(String id) =>
      _ds.comissoes.byId(id);

  @override
  Future<void> salvarLancamento(LancamentoComissao l) async {
    final json = await _ds.api.put(
      'equipe/comissoes/${l.id}',
      comissaoParaJson(l),
    );
    _ds.comissoes.cache.upsert(comissaoDeJson(json as Map<String, dynamic>));
  }

  @override
  Future<void> removerLancamento(String id) async {
    await _ds.api.delete('equipe/comissoes/$id');
    _ds.comissoes.cache.removeWhere((e) => e.id == id);
  }
}

class MensagemApiRepository implements MensagemRepository {
  const MensagemApiRepository(this._ds);
  final EquipeApiDataSource _ds;

  @override
  Stream<List<Mensagem>> observar() => _ds.mensagens.watch();

  @override
  Future<List<Mensagem>> listar() => _ds.mensagens.all();

  @override
  Future<void> salvar(Mensagem m) async {
    final json = await _ds.api.put(
      'equipe/mensagens/${m.id}',
      mensagemParaJson(m),
    );
    _ds.mensagens.cache.upsert(mensagemDeJson(json as Map<String, dynamic>));
  }

  /// Uma requisição para marcar a conversa inteira como lida.
  @override
  Future<void> salvarTodas(List<Mensagem> mensagens) async {
    if (mensagens.isEmpty) return;
    final json = await _ds.api.put('equipe/mensagens', [
      for (final m in mensagens) {'id': m.id, ...mensagemParaJson(m)},
    ]);
    for (final j in json as List) {
      _ds.mensagens.cache.upsert(mensagemDeJson(j as Map<String, dynamic>));
    }
  }

  @override
  Future<void> remover(String id) async {
    await _ds.api.delete('equipe/mensagens/$id');
    _ds.mensagens.cache.removeWhere((e) => e.id == id);
  }
}
