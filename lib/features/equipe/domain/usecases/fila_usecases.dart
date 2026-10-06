import '../../../../core/errors/domain_exception.dart';
import '../../../../core/utils/id.dart';
import '../entities/equipe_enums.dart';
import '../entities/fila.dart';
import '../repositories/equipe_repositories.dart';
import '../services/fila_service.dart';
import 'usuario_usecases.dart';

class ObservarFila {
  const ObservarFila(this._repo);
  final FilaRepository _repo;

  Stream<List<ItemFila>> call() => _repo.observar();
}

class ObservarAtendimentos {
  const ObservarAtendimentos(this._repo);
  final AtendimentoRepository _repo;

  Stream<List<Atendimento>> call() => _repo.observar();
}

/// Operações de entrada, saída, ausência e ordem da fila.
class GerenciarFila {
  const GerenciarFila(
    this._fila,
    this._usuarios,
    this._registrar, [
    this._service = const FilaService(),
  ]);
  final FilaRepository _fila;
  final UsuarioRepository _usuarios;
  final RegistrarAtividade _registrar;
  final FilaService _service;

  Future<void> entrar(String usuarioId) async {
    final u = await _usuarios.obter(usuarioId);
    if (u == null || !u.ativo) throw const DomainException('Usuário inativo.');
    await _fila.salvar(
      _service.entrar(await _fila.listar(), usuarioId, DateTime.now()),
    );
    await _registrar(
      TipoAtividade.atendimento,
      '${u.nome} entrou na fila de atendimento',
    );
  }

  Future<void> sair(String usuarioId) async {
    final u = await _usuarios.obter(usuarioId);
    await _fila.salvar(_service.sair(await _fila.listar(), usuarioId));
    await _registrar(
      TipoAtividade.atendimento,
      '${u?.nome ?? 'Corretor'} saiu da fila de atendimento',
    );
  }

  Future<void> mudarStatus(String usuarioId, StatusFila status) async {
    await _fila.salvar(
      _service.mudarStatus(
        await _fila.listar(),
        usuarioId,
        status,
        DateTime.now(),
      ),
    );
  }

  Future<void> pular(String usuarioId) async {
    final u = await _usuarios.obter(usuarioId);
    await _fila.salvar(
      _service.pular(await _fila.listar(), usuarioId, DateTime.now()),
    );
    await _registrar(
      TipoAtividade.atendimento,
      '${u?.nome ?? 'Corretor'} passou a vez na fila',
    );
  }

  Future<void> mover(String usuarioId, int delta) async =>
      _fila.salvar(_service.mover(await _fila.listar(), usuarioId, delta));
}

/// Entrega o cliente ao próximo corretor disponível e abre o atendimento.
class ChamarProximo {
  const ChamarProximo(
    this._fila,
    this._atendimentos,
    this._usuarios,
    this._registrar, [
    this._service = const FilaService(),
  ]);
  final FilaRepository _fila;
  final AtendimentoRepository _atendimentos;
  final UsuarioRepository _usuarios;
  final RegistrarAtividade _registrar;
  final FilaService _service;

  Future<Atendimento> call({
    required String clienteNome,
    required OrigemAtendimento origem,
    String? contatoId,
    String observacao = '',
  }) async {
    if (clienteNome.trim().isEmpty) {
      throw const DomainException('Informe o nome do cliente.');
    }
    final agora = DateTime.now();
    final r = _service.chamarProximo(await _fila.listar(), agora);
    final chamado = r.chamado;
    if (chamado == null) {
      throw const DomainException('Nenhum corretor disponível na fila.');
    }
    await _fila.salvar(r.fila);
    final a = Atendimento(
      id: gerarId(),
      corretorId: chamado.usuarioId,
      clienteNome: clienteNome.trim(),
      origem: origem,
      iniciadoEm: agora,
      contatoId: contatoId,
      observacao: observacao.trim(),
    );
    await _atendimentos.salvar(a);
    final u = await _usuarios.obter(chamado.usuarioId);
    await _registrar(
      TipoAtividade.atendimento,
      'Atendimento de ${a.clienteNome} encaminhado a ${u?.nome ?? 'corretor'} (${origem.label})',
      usuarioId: chamado.usuarioId,
    );
    return a;
  }
}

class FinalizarAtendimento {
  const FinalizarAtendimento(
    this._fila,
    this._atendimentos,
    this._registrar, [
    this._service = const FilaService(),
  ]);
  final FilaRepository _fila;
  final AtendimentoRepository _atendimentos;
  final RegistrarAtividade _registrar;
  final FilaService _service;

  Future<void> call(Atendimento a, String observacao) async {
    if (!a.emAndamento) return;
    final agora = DateTime.now();
    await _atendimentos.salvar(a.finalizar(agora, observacao.trim()));
    final fila = await _fila.listar();
    final item = fila.where((i) => i.usuarioId == a.corretorId).firstOrNull;
    if (item != null && item.status == StatusFila.emAtendimento) {
      await _fila.salvar(
        _service.mudarStatus(fila, a.corretorId, StatusFila.disponivel, agora),
      );
    }
    await _registrar(
      TipoAtividade.atendimento,
      'Finalizou o atendimento de ${a.clienteNome}',
      usuarioId: a.corretorId,
    );
  }
}
