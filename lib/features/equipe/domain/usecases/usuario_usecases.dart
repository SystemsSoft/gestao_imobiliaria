import '../../../../core/errors/domain_exception.dart';
import '../../../../core/utils/id.dart';
import '../entities/atividade.dart';
import '../entities/equipe_enums.dart';
import '../entities/sessao.dart';
import '../entities/usuario_sistema.dart';
import '../repositories/equipe_repositories.dart';

class ObservarUsuarios {
  const ObservarUsuarios(this._repo);
  final UsuarioRepository _repo;

  Stream<List<UsuarioSistema>> call() => _repo.observar();
}

class ObservarSessoes {
  const ObservarSessoes(this._repo);
  final SessaoRepository _repo;

  Stream<List<SessaoUsuario>> call() => _repo.observar();
}

class ObservarUsuarioAtual {
  const ObservarUsuarioAtual(this._repo);
  final UsuarioAtualRepository _repo;

  Stream<String?> call() => _repo.observar();
}

class ObservarConfiguracaoSeguranca {
  const ObservarConfiguracaoSeguranca(this._repo);
  final ConfiguracaoSegurancaRepository _repo;

  Stream<ConfiguracaoSeguranca> call() => _repo.observar();
}

class ObservarAtividades {
  const ObservarAtividades(this._repo);
  final AtividadeRepository _repo;

  Stream<List<Atividade>> call() => _repo.observar();
}

/// Registra uma ação no histórico, em nome do usuário atual (ou de [usuarioId]).
class RegistrarAtividade {
  const RegistrarAtividade(this._atividades, this._atual);
  final AtividadeRepository _atividades;
  final UsuarioAtualRepository _atual;

  Future<void> call(
    TipoAtividade tipo,
    String descricao, {
    ModuloSistema? modulo,
    String? usuarioId,
  }) async {
    final id = usuarioId ?? await _atual.obter();
    if (id == null) return;
    await _atividades.salvar(
      Atividade(
        id: gerarId(),
        usuarioId: id,
        tipo: tipo,
        descricao: descricao,
        quando: DateTime.now(),
        modulo: modulo,
      ),
    );
  }
}

final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class SalvarUsuario {
  const SalvarUsuario(this._repo, this._registrar);
  final UsuarioRepository _repo;
  final RegistrarAtividade _registrar;

  Future<void> call(UsuarioSistema u, {String? senha}) async {
    if (u.nome.trim().isEmpty) throw const DomainException('Informe o nome.');
    if (senha != null && senha.isNotEmpty && senha.length < 8) {
      throw const DomainException('A senha precisa de ao menos 8 caracteres.');
    }
    if (!_email.hasMatch(u.email.trim())) {
      throw const DomainException('E-mail inválido.');
    }
    final todos = await _repo.listar();
    final duplicado = todos.any(
      (x) =>
          x.id != u.id && x.email.toLowerCase() == u.email.trim().toLowerCase(),
    );
    if (duplicado) {
      throw const DomainException('Já existe um usuário com este e-mail.');
    }
    final novo = !todos.any((x) => x.id == u.id);
    await _repo.salvar(u, senha: senha?.isEmpty ?? true ? null : senha);
    await _registrar(
      novo ? TipoAtividade.criacao : TipoAtividade.edicao,
      '${novo ? 'Criou' : 'Editou'} o usuário ${u.nome}',
      modulo: ModuloSistema.equipeSeguranca,
    );
  }
}

/// Ativa ou desativa o acesso. Desativar encerra as sessões do usuário.
class AlternarAtivoUsuario {
  const AlternarAtivoUsuario(this._usuarios, this._sessoes, this._registrar);
  final UsuarioRepository _usuarios;
  final SessaoRepository _sessoes;
  final RegistrarAtividade _registrar;

  Future<void> call(UsuarioSistema u) async {
    if (u.ativo) {
      final outrosAdmins = (await _usuarios.listar()).where(
        (x) => x.id != u.id && x.ativo && x.administrador,
      );
      if (u.administrador && outrosAdmins.isEmpty) {
        throw const DomainException(
          'Mantenha ao menos um administrador ativo.',
        );
      }
      await _sessoes.removerDoUsuario(u.id);
    }
    await _usuarios.salvar(u.copyWith(ativo: !u.ativo));
    await _registrar(
      TipoAtividade.edicao,
      '${u.ativo ? 'Desativou' : 'Reativou'} o usuário ${u.nome}',
      modulo: ModuloSistema.equipeSeguranca,
    );
  }
}

class RemoverUsuario {
  const RemoverUsuario(
    this._usuarios,
    this._sessoes,
    this._atual,
    this._registrar,
  );
  final UsuarioRepository _usuarios;
  final SessaoRepository _sessoes;
  final UsuarioAtualRepository _atual;
  final RegistrarAtividade _registrar;

  Future<void> call(UsuarioSistema u) async {
    if (await _atual.obter() == u.id) {
      throw const DomainException(
        'Você não pode excluir o usuário que está em uso.',
      );
    }
    final outrosAdmins = (await _usuarios.listar()).where(
      (x) => x.id != u.id && x.ativo && x.administrador,
    );
    if (u.administrador && outrosAdmins.isEmpty) {
      throw const DomainException('Mantenha ao menos um administrador ativo.');
    }
    await _sessoes.removerDoUsuario(u.id);
    await _usuarios.remover(u.id);
    await _registrar(
      TipoAtividade.exclusao,
      'Excluiu o usuário ${u.nome}',
      modulo: ModuloSistema.equipeSeguranca,
    );
  }
}

/// Sessões que ainda contam como conectadas (com atividade recente).
List<SessaoUsuario> sessoesAtivas(
  List<SessaoUsuario> sessoes,
  ConfiguracaoSeguranca config,
  DateTime agora,
) => sessoes
    .where(
      (s) =>
          agora.difference(s.ultimaAtividade).inMinutes <
          config.inatividadeMinutos,
    )
    .toList();

/// Passa a usar o sistema como [usuarioId], abrindo uma sessão. Respeita o
/// limite de usuários simultâneos.
class DefinirUsuarioAtual {
  const DefinirUsuarioAtual(
    this._usuarios,
    this._sessoes,
    this._config,
    this._atual,
    this._registrar,
  );
  final UsuarioRepository _usuarios;
  final SessaoRepository _sessoes;
  final ConfiguracaoSegurancaRepository _config;
  final UsuarioAtualRepository _atual;
  final RegistrarAtividade _registrar;

  Future<void> call(String usuarioId) async {
    final u = await _usuarios.obter(usuarioId);
    if (u == null) throw const DomainException('Usuário não encontrado.');
    if (!u.ativo) throw const DomainException('Este usuário está desativado.');
    final agora = DateTime.now();
    final config = await _config.obter();
    final ativas = sessoesAtivas(await _sessoes.listar(), config, agora);
    final propria = ativas.where((s) => s.usuarioId == usuarioId).firstOrNull;

    if (propria != null) {
      await _sessoes.salvar(propria.copyWith(ultimaAtividade: agora));
    } else {
      if (ativas.length >= config.limiteSessoes) {
        throw DomainException(
          'Limite de ${config.limiteSessoes} usuário(s) simultâneo(s) atingido. '
          'Encerre uma sessão ou aumente o limite.',
        );
      }
      await _sessoes.salvar(
        SessaoUsuario(
          id: gerarId(),
          usuarioId: usuarioId,
          inicio: agora,
          ultimaAtividade: agora,
          dispositivo: 'Navegador deste computador',
        ),
      );
      await _registrar(
        TipoAtividade.login,
        'Entrou no sistema',
        usuarioId: usuarioId,
      );
    }
    await _atual.definir(usuarioId);
  }
}

class EncerrarSessao {
  const EncerrarSessao(this._sessoes, this._usuarios, this._registrar);
  final SessaoRepository _sessoes;
  final UsuarioRepository _usuarios;
  final RegistrarAtividade _registrar;

  Future<void> call(SessaoUsuario s) async {
    await _sessoes.remover(s.id);
    final u = await _usuarios.obter(s.usuarioId);
    await _registrar(
      TipoAtividade.logout,
      'Sessão de ${u?.nome ?? 'usuário'} encerrada',
      modulo: ModuloSistema.equipeSeguranca,
    );
  }
}

class SalvarConfiguracaoSeguranca {
  const SalvarConfiguracaoSeguranca(this._repo, this._registrar);
  final ConfiguracaoSegurancaRepository _repo;
  final RegistrarAtividade _registrar;

  Future<void> call(ConfiguracaoSeguranca c) async {
    if (c.limiteSessoes < 1 || c.limiteSessoes > 100) {
      throw const DomainException('O limite deve ser de 1 a 100 usuários.');
    }
    if (c.inatividadeMinutos < 5 || c.inatividadeMinutos > 480) {
      throw const DomainException('A inatividade deve ser de 5 a 480 minutos.');
    }
    await _repo.salvar(c);
    await _registrar(
      TipoAtividade.permissao,
      'Alterou a segurança: ${c.limiteSessoes} simultâneos, ${c.inatividadeMinutos} min de inatividade',
      modulo: ModuloSistema.equipeSeguranca,
    );
  }
}
