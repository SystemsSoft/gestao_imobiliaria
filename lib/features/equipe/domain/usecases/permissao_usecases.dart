import '../../../../core/errors/domain_exception.dart';
import '../entities/equipe_enums.dart';
import '../entities/permissoes.dart';
import '../entities/usuario_sistema.dart';
import '../repositories/equipe_repositories.dart';
import 'usuario_usecases.dart';

/// Salva as permissões do usuário, sem deixar o sistema sem administrador.
class SalvarPermissoes {
  const SalvarPermissoes(this._repo, this._registrar);
  final UsuarioRepository _repo;
  final RegistrarAtividade _registrar;

  Future<void> call(
    UsuarioSistema u,
    Permissoes p, {
    PerfilAcesso? perfil,
  }) async {
    final outros = (await _repo.listar()).where(
      (x) => x.id != u.id && x.ativo && x.administrador,
    );
    final seraAdmin = p.temEspecial(PermissaoEspecial.gerenciarUsuarios);
    if (u.administrador && !seraAdmin && outros.isEmpty) {
      throw const DomainException(
        'Este é o único administrador: mantenha a permissão "Gerenciar usuários".',
      );
    }
    await _repo.salvar(u.copyWith(permissoes: p, perfil: perfil));
    await _registrar(
      TipoAtividade.permissao,
      'Alterou as permissões de ${u.nome}'
      '${perfil == null ? '' : ' (perfil ${perfil.label})'}',
      modulo: ModuloSistema.equipeSeguranca,
    );
  }
}
