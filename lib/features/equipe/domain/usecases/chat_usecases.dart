import '../../../../core/errors/domain_exception.dart';
import '../../../../core/utils/id.dart';
import '../entities/chat.dart';
import '../repositories/equipe_repositories.dart';

class ObservarMensagens {
  const ObservarMensagens(this._repo);
  final MensagemRepository _repo;

  Stream<List<Mensagem>> call() => _repo.observar();
}

class EnviarMensagem {
  const EnviarMensagem(this._mensagens, this._usuarios);
  final MensagemRepository _mensagens;
  final UsuarioRepository _usuarios;

  Future<void> call({
    required String conversaId,
    required String remetenteId,
    required String texto,
  }) async {
    final t = texto.trim();
    if (t.isEmpty) return;
    if (t.length > 2000) {
      throw const DomainException('A mensagem passa de 2.000 caracteres.');
    }
    final u = await _usuarios.obter(remetenteId);
    if (u == null || !u.ativo) throw const DomainException('Usuário inativo.');
    await _mensagens.salvar(
      Mensagem(
        id: gerarId(),
        conversaId: conversaId,
        remetenteId: remetenteId,
        texto: t,
        enviadaEm: DateTime.now(),
      ),
    );
  }
}

/// Marca como lidas as mensagens da conversa para o usuário.
class MarcarConversaLida {
  const MarcarConversaLida(this._repo);
  final MensagemRepository _repo;

  Future<void> call(String conversaId, String usuarioId) async {
    final pendentes = (await _repo.listar())
        .where(
          (m) => m.conversaId == conversaId && !m.lidaPorUsuario(usuarioId),
        )
        .map((m) => m.comLeitor(usuarioId))
        .toList();
    if (pendentes.isNotEmpty) await _repo.salvarTodas(pendentes);
  }
}

/// Apaga uma mensagem; só o autor pode.
class ApagarMensagem {
  const ApagarMensagem(this._repo);
  final MensagemRepository _repo;

  Future<void> call(Mensagem m, String usuarioId) {
    if (m.remetenteId != usuarioId) {
      throw const DomainException('Você só pode apagar as suas mensagens.');
    }
    return _repo.remover(m.id);
  }
}
