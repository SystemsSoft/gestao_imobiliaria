import '../../../../core/api/api_client.dart';
import '../../../../core/api/sessao_api.dart';
import '../../../../core/api/status_conexao.dart';
import '../../domain/entities/usuario.dart';
import '../../domain/repositories/auth_repository.dart';

/// Login no servidor (`/api/v1/auth`). O token fica só na memória: ao
/// recarregar a página é preciso entrar de novo.
class AuthRepositoryApi implements AuthRepository {
  const AuthRepositoryApi(this._api, this._sessao, this._status);
  final ApiClient _api;
  final SessaoApi _sessao;
  final StatusConexao _status;

  @override
  Future<Usuario> entrar({required String email, required String senha}) async {
    final r =
        await _api.post('auth/entrar', {'email': email, 'senha': senha})
            as Map<String, dynamic>;
    final usuario = r['usuario'] as Map<String, dynamic>;
    // Dados de um login anterior (outro usuário) não podem aparecer.
    _status.invalidarTudo();
    _sessao.iniciar(
      token: r['token'] as String,
      usuarioId: usuario['id'] as String,
      sessaoId: r['sessaoId'] as String,
    );
    return Usuario(email: usuario['email'] as String);
  }

  @override
  Future<void> sair() async {
    try {
      if (_sessao.logado) await _api.post('auth/sair', null);
    } on ApiException {
      // Mesmo sem resposta do servidor, a sessão local é encerrada.
    } finally {
      _sessao.encerrar();
      _status.invalidarTudo();
    }
  }

  @override
  Future<void> alterarSenha({
    required String atual,
    required String nova,
  }) async =>
      _api.post('auth/alterar-senha', {'senhaAtual': atual, 'novaSenha': nova});
}
