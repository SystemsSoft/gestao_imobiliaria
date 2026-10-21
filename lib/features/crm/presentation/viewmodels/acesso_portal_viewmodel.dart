import '../../../../core/errors/domain_exception.dart';
import '../../../../core/presentation/view_model.dart';
import '../../../auditoria/domain/entities/auditoria.dart';
import '../../../auditoria/domain/repositories/auditoria_repository.dart';
import '../../../locacao/domain/repositories/contrato_locacao_repository.dart';
import '../../../portal_inquilino/domain/entities/portal.dart';
import '../../../portal_inquilino/domain/repositories/portal_repository.dart';

/// Situação do contato em uma das áreas do portal (inquilino/proprietário).
class SituacaoPortal {
  const SituacaoPortal({
    this.temContrato,
    this.ativo = false,
    this.login = '',
    this.trocarSenha = false,
    this.bloqueado = false,
    this.ultimoAcesso,
    this.erro,
  });

  /// Locatário ou beneficiário de algum contrato de locação (só informa o
  /// que ele verá no portal; null = não foi possível consultar).
  final bool? temContrato;

  /// Já tem acesso liberado.
  final bool ativo;
  final String login;
  final bool trocarSenha;
  final bool bloqueado;
  final DateTime? ultimoAcesso;

  /// Não foi possível consultar (ex.: sem permissão no módulo).
  final String? erro;
}

/// Acesso do contato às áreas do inquilino e do proprietário no site, com o
/// mesmo fluxo da Locação (Portal do inquilino) e das Auditorias
/// (Proprietários): liberar, gerar nova senha e revogar.
class AcessoPortalViewModel extends ViewModel {
  AcessoPortalViewModel(this._portal, this._auditorias, this._contratos);

  final PortalInquilinoRepository _portal;
  final AuditoriaRepository _auditorias;
  final ContratoLocacaoRepository _contratos;

  late String contatoId;
  bool carregado = false;
  SituacaoPortal inquilino = const SituacaoPortal();
  SituacaoPortal proprietario = const SituacaoPortal();

  /// Senha da última liberação (mostrada uma única vez).
  SenhaProvisoria? senhaGerada;

  Future<void> carregar(String id) async {
    contatoId = id;
    bool? locatario, beneficiario;
    try {
      final contratos = await _contratos.listar();
      locatario = contratos.any((c) => c.locatarioId == id);
      beneficiario = contratos.any(
        (c) => c.beneficiarios.any((b) => b.contatoId == id),
      );
    } on DomainException {
      // Sem permissão em Locação: o contrato não é exigido, só não se sabe.
    }
    inquilino = await _situacao(locatario, () async {
      final a = (await _portal.acessos())
          .where((a) => a.contatoId == id)
          .firstOrNull;
      return a == null
          ? null
          : (a.ativo, a.login, a.trocarSenha, a.bloqueado, a.ultimoAcesso);
    });
    proprietario = await _situacao(beneficiario, () async {
      final p = (await _auditorias.proprietarios())
          .where((p) => p.contatoId == id)
          .firstOrNull;
      final AcessoProprietario? a = p?.acesso;
      return a == null
          ? null
          : (a.ativo, p!.documento, a.trocarSenha, a.bloqueado, a.ultimoAcesso);
    });
    carregado = true;
    notificar();
  }

  Future<SituacaoPortal> _situacao(
    bool? temContrato,
    Future<(bool, String, bool, bool, DateTime?)?> Function() acesso,
  ) async {
    try {
      final a = await acesso();
      return a == null
          ? SituacaoPortal(temContrato: temContrato)
          : SituacaoPortal(
              temContrato: temContrato,
              ativo: a.$1,
              login: a.$2,
              trocarSenha: a.$3,
              bloqueado: a.$4,
              ultimoAcesso: a.$5,
            );
    } on DomainException catch (e) {
      return SituacaoPortal(temContrato: temContrato, erro: e.mensagem);
    }
  }

  Future<bool> liberarInquilino() => executar(() async {
    senhaGerada = await _portal.liberarAcesso(contatoId);
    await carregar(contatoId);
  });

  Future<bool> revogarInquilino() => executar(() async {
    await _portal.revogarAcesso(contatoId);
    await carregar(contatoId);
  });

  Future<bool> liberarProprietario() => executar(() async {
    senhaGerada = await _auditorias.liberarAcesso(contatoId);
    await carregar(contatoId);
  });

  Future<bool> revogarProprietario() => executar(() async {
    await _auditorias.revogarAcesso(contatoId);
    await carregar(contatoId);
  });
}
