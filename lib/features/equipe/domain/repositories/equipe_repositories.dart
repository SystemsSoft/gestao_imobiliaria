import '../entities/atividade.dart';
import '../entities/chat.dart';
import '../entities/comissao_equipe.dart';
import '../entities/fila.dart';
import '../entities/sessao.dart';
import '../entities/usuario_sistema.dart';

abstract interface class UsuarioRepository {
  Stream<List<UsuarioSistema>> observar();
  Future<List<UsuarioSistema>> listar();
  Future<UsuarioSistema?> obter(String id);

  /// [senha]: obrigatória ao criar no servidor; ao editar, só para trocar.
  Future<void> salvar(UsuarioSistema usuario, {String? senha});
  Future<void> remover(String id);
}

abstract interface class SessaoRepository {
  Stream<List<SessaoUsuario>> observar();
  Future<List<SessaoUsuario>> listar();
  Future<void> salvar(SessaoUsuario sessao);
  Future<void> remover(String id);
  Future<void> removerDoUsuario(String usuarioId);
}

abstract interface class ConfiguracaoSegurancaRepository {
  Stream<ConfiguracaoSeguranca> observar();
  Future<ConfiguracaoSeguranca> obter();
  Future<void> salvar(ConfiguracaoSeguranca configuracao);
}

/// Usuário que está usando o sistema neste computador.
abstract interface class UsuarioAtualRepository {
  Stream<String?> observar();
  Future<String?> obter();
  Future<void> definir(String usuarioId);

  /// Sem servidor dá para simular outro usuário; com login, não.
  bool get permiteTrocar;
}

abstract interface class AtividadeRepository {
  Stream<List<Atividade>> observar();
  Future<void> salvar(Atividade atividade);
}

abstract interface class FilaRepository {
  Stream<List<ItemFila>> observar();
  Future<List<ItemFila>> listar();

  /// Substitui a fila inteira, na ordem recebida.
  Future<void> salvar(List<ItemFila> fila);
}

abstract interface class AtendimentoRepository {
  Stream<List<Atendimento>> observar();
  Future<Atendimento?> obter(String id);
  Future<void> salvar(Atendimento atendimento);
}

abstract interface class ComissaoEquipeRepository {
  Stream<List<RegraComissao>> observarRegras();
  Future<RegraComissao?> obterRegra(String usuarioId);
  Future<void> salvarRegra(RegraComissao regra);

  Stream<List<LancamentoComissao>> observarLancamentos();
  Future<LancamentoComissao?> obterLancamento(String id);
  Future<void> salvarLancamento(LancamentoComissao lancamento);
  Future<void> removerLancamento(String id);
}

abstract interface class MensagemRepository {
  Stream<List<Mensagem>> observar();
  Future<List<Mensagem>> listar();
  Future<void> salvar(Mensagem mensagem);
  Future<void> salvarTodas(List<Mensagem> mensagens);
  Future<void> remover(String id);
}
