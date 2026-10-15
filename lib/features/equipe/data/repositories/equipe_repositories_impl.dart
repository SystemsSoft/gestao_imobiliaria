import 'dart:async';

import '../../domain/entities/atividade.dart';
import '../../domain/entities/chat.dart';
import '../../domain/entities/comissao_equipe.dart';
import '../../domain/entities/fila.dart';
import '../../domain/entities/sessao.dart';
import '../../domain/entities/usuario_sistema.dart';
import '../../domain/repositories/equipe_repositories.dart';
import '../datasources/equipe_memory_datasource.dart';

/// Emite o valor atual ao assinar e depois a cada alteração.
Stream<T> _comInicial<T>(T Function() atual, Stream<T> mudancas) {
  late final StreamController<T> c;
  StreamSubscription<T>? sub;
  c = StreamController<T>(
    onListen: () {
      c.add(atual());
      sub = mudancas.listen(c.add);
    },
    onCancel: () => sub?.cancel(),
  );
  return c.stream;
}

class UsuarioRepositoryImpl implements UsuarioRepository {
  const UsuarioRepositoryImpl(this._ds);
  final EquipeMemoryDataSource _ds;

  @override
  Stream<List<UsuarioSistema>> observar() => _ds.usuarios.watch();

  @override
  Future<List<UsuarioSistema>> listar() async => _ds.usuarios.all;

  @override
  Future<UsuarioSistema?> obter(String id) async => _ds.usuarios.byId(id);

  @override
  Future<void> salvar(UsuarioSistema usuario, {String? senha}) async =>
      _ds.usuarios.upsert(usuario);

  @override
  Future<void> remover(String id) async =>
      _ds.usuarios.removeWhere((e) => e.id == id);
}

class SessaoRepositoryImpl implements SessaoRepository {
  const SessaoRepositoryImpl(this._ds);
  final EquipeMemoryDataSource _ds;

  @override
  Stream<List<SessaoUsuario>> observar() => _ds.sessoes.watch();

  @override
  Future<List<SessaoUsuario>> listar() async => _ds.sessoes.all;

  @override
  Future<void> salvar(SessaoUsuario sessao) async => _ds.sessoes.upsert(sessao);

  @override
  Future<void> remover(String id) async =>
      _ds.sessoes.removeWhere((e) => e.id == id);

  @override
  Future<void> removerDoUsuario(String usuarioId) async =>
      _ds.sessoes.removeWhere((e) => e.usuarioId == usuarioId);
}

class ConfiguracaoSegurancaRepositoryImpl
    implements ConfiguracaoSegurancaRepository {
  const ConfiguracaoSegurancaRepositoryImpl(this._ds);
  final EquipeMemoryDataSource _ds;

  @override
  Stream<ConfiguracaoSeguranca> observar() => _ds.configuracao.watch().map(
    (l) => l.firstOrNull ?? const ConfiguracaoSeguranca(),
  );

  @override
  Future<ConfiguracaoSeguranca> obter() async =>
      _ds.configuracao.all.firstOrNull ?? const ConfiguracaoSeguranca();

  @override
  Future<void> salvar(ConfiguracaoSeguranca configuracao) async =>
      _ds.configuracao.upsert(configuracao);
}

class UsuarioAtualRepositoryImpl implements UsuarioAtualRepository {
  const UsuarioAtualRepositoryImpl(this._ds);
  final EquipeMemoryDataSource _ds;

  @override
  Stream<String?> observar() =>
      _comInicial(() => _ds.usuarioAtualId, _ds.usuarioAtualChanges.stream);

  @override
  Future<String?> obter() async => _ds.usuarioAtualId;

  @override
  Future<void> definir(String usuarioId) async {
    _ds.usuarioAtualId = usuarioId;
    _ds.usuarioAtualChanges.add(usuarioId);
  }

  @override
  bool get permiteTrocar => true;
}

class AtividadeRepositoryImpl implements AtividadeRepository {
  const AtividadeRepositoryImpl(this._ds);
  final EquipeMemoryDataSource _ds;

  @override
  Stream<List<Atividade>> observar() => _ds.atividades.watch();

  @override
  Future<void> salvar(Atividade atividade) async =>
      _ds.atividades.upsert(atividade);
}

class FilaRepositoryImpl implements FilaRepository {
  const FilaRepositoryImpl(this._ds);
  final EquipeMemoryDataSource _ds;

  @override
  Stream<List<ItemFila>> observar() =>
      _comInicial(() => List.unmodifiable(_ds.fila), _ds.filaChanges.stream);

  @override
  Future<List<ItemFila>> listar() async => List.unmodifiable(_ds.fila);

  @override
  Future<void> salvar(List<ItemFila> fila) async {
    _ds.fila = [...fila];
    _ds.filaChanges.add(List.unmodifiable(_ds.fila));
  }
}

class AtendimentoRepositoryImpl implements AtendimentoRepository {
  const AtendimentoRepositoryImpl(this._ds);
  final EquipeMemoryDataSource _ds;

  @override
  Stream<List<Atendimento>> observar() => _ds.atendimentos.watch();

  @override
  Future<Atendimento?> obter(String id) async => _ds.atendimentos.byId(id);

  @override
  Future<void> salvar(Atendimento atendimento) async =>
      _ds.atendimentos.upsert(atendimento);
}

class ComissaoEquipeRepositoryImpl implements ComissaoEquipeRepository {
  const ComissaoEquipeRepositoryImpl(this._ds);
  final EquipeMemoryDataSource _ds;

  @override
  Stream<List<RegraComissao>> observarRegras() => _ds.regras.watch();

  @override
  Future<RegraComissao?> obterRegra(String usuarioId) async =>
      _ds.regras.byId(usuarioId);

  @override
  Future<void> salvarRegra(RegraComissao regra) async =>
      _ds.regras.upsert(regra);

  @override
  Stream<List<LancamentoComissao>> observarLancamentos() =>
      _ds.lancamentos.watch();

  @override
  Future<LancamentoComissao?> obterLancamento(String id) async =>
      _ds.lancamentos.byId(id);

  @override
  Future<void> salvarLancamento(LancamentoComissao l) async =>
      _ds.lancamentos.upsert(l);

  @override
  Future<void> removerLancamento(String id) async =>
      _ds.lancamentos.removeWhere((e) => e.id == id);
}

class MensagemRepositoryImpl implements MensagemRepository {
  const MensagemRepositoryImpl(this._ds);
  final EquipeMemoryDataSource _ds;

  @override
  Stream<List<Mensagem>> observar() => _ds.mensagens.watch();

  @override
  Future<List<Mensagem>> listar() async => _ds.mensagens.all;

  @override
  Future<void> salvar(Mensagem mensagem) async =>
      _ds.mensagens.upsert(mensagem);

  @override
  Future<void> salvarTodas(List<Mensagem> mensagens) async {
    for (final m in mensagens) {
      _ds.mensagens.upsert(m);
    }
  }

  @override
  Future<void> remover(String id) async =>
      _ds.mensagens.removeWhere((e) => e.id == id);
}
