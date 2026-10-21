import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../auditoria/domain/usecases/auditoria_usecases.dart';
import '../../../portal_inquilino/domain/usecases/portal_usecases.dart';
import '../../../portal_inquilino/presentation/widgets/portal_dialogs.dart';
import '../../../site/domain/repositories/site_repository.dart';
import '../../domain/entities/contato.dart';
import '../../domain/entities/enums.dart';
import '../viewmodels/acesso_portal_viewmodel.dart';

/// Seção "Acesso ao portal" do cadastro do contato: conforme o perfil
/// (locatário e/ou proprietário), libera, renova a senha ou revoga o acesso
/// à área dele no site — o mesmo fluxo da Locação e das Auditorias.
class AcessoPortalSecao extends StatefulWidget {
  const AcessoPortalSecao({
    super.key,
    required this.contato,
    required this.papeis,
    required this.documentoAlterado,
    required this.telefone,
  });

  /// Contato como está salvo (o servidor usa o CPF/CNPJ salvo como login).
  final Contato contato;

  /// Perfis marcados agora no formulário.
  final Set<PapelContato> papeis;

  /// O CPF/CNPJ foi mudado no formulário e ainda não foi salvo.
  final bool documentoAlterado;

  /// Celular (ou telefone) para enviar a senha pelo WhatsApp.
  final String telefone;

  @override
  State<AcessoPortalSecao> createState() => _AcessoPortalSecaoState();
}

class _AcessoPortalSecaoState extends State<AcessoPortalSecao> {
  final _vm = sl<AcessoPortalViewModel>();

  @override
  void initState() {
    super.initState();
    _vm.carregar(widget.contato.id);
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<bool> _confirmar(String texto) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.navy,
          content: Text(texto),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.navyDark,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _liberar({required bool inquilino}) async {
    final s = inquilino ? _vm.inquilino : _vm.proprietario;
    final quem = inquilino ? 'o inquilino' : 'o proprietário';
    if (s.ativo &&
        !await _confirmar(
          'Gerar nova senha provisória para ${widget.contato.nome}? A senha '
          'atual deixa de funcionar e $quem é desconectado.',
        )) {
      return;
    }
    final ok = inquilino
        ? await _vm.liberarInquilino()
        : await _vm.liberarProprietario();
    if (!mounted) return;
    if (!ok) {
      mostrarMensagem(context, _vm.erro ?? 'Não foi possível liberar.');
      return;
    }
    final senha = _vm.senhaGerada!;
    final site = sl<SiteRepository>().endereco;
    await mostrarSenhaProvisoria(
      context,
      senha: senha,
      telefone: widget.telefone,
      mensagem: inquilino
          ? mensagemDeAcesso(
              nome: widget.contato.nome,
              enderecoSite: site,
              senha: senha,
            )
          : mensagemDeAcessoProprietario(
              nome: widget.contato.nome,
              enderecoSite: site,
              senha: senha,
            ),
    );
  }

  Future<void> _revogar({required bool inquilino}) async {
    final area = inquilino ? 'Área do inquilino' : 'Área do proprietário';
    if (!await _confirmar(
      'Revogar o acesso de ${widget.contato.nome} à $area?',
    )) {
      return;
    }
    final ok = inquilino
        ? await _vm.revogarInquilino()
        : await _vm.revogarProprietario();
    if (mounted) {
      mostrarMensagem(context, ok ? 'Acesso revogado.' : (_vm.erro ?? 'Erro.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final locatario =
            widget.papeis.contains(PapelContato.locatario) ||
            _vm.inquilino.temContrato == true ||
            _vm.inquilino.ativo;
        final proprietario =
            widget.papeis.contains(PapelContato.proprietario) ||
            _vm.proprietario.temContrato == true ||
            _vm.proprietario.ativo;
        return FormSection(
          title: 'Acesso ao portal (site)',
          icon: Icons.vpn_key_outlined,
          children: [
            if (!_vm.carregado)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (!locatario && !proprietario)
              const Text(
                'Marque o perfil "Locatário" e/ou "Proprietário" acima para '
                'liberar o acesso dele à área do site.',
                style: TextStyle(color: Colors.white70),
              )
            else ...[
              if (widget.documentoAlterado)
                const _Aviso(
                  'O CPF/CNPJ foi alterado: salve o contato antes de liberar, '
                  'porque ele é o login no portal.',
                ),
              if (locatario)
                _area(
                  titulo: 'Área do inquilino',
                  caminho: '/inquilino',
                  papelMarcado: widget.papeis.contains(PapelContato.locatario),
                  papel: 'Locatário',
                  s: _vm.inquilino,
                  semContrato:
                      'Sem contrato de locação: no portal ele vê os '
                      'documentos compartilhados e os avisos. Pagamentos e '
                      'chamados aparecem quando houver contrato.',
                  inquilino: true,
                ),
              if (proprietario)
                _area(
                  titulo: 'Área do proprietário',
                  caminho: '/proprietario',
                  papelMarcado: widget.papeis.contains(
                    PapelContato.proprietario,
                  ),
                  papel: 'Proprietário',
                  s: _vm.proprietario,
                  semContrato:
                      'Sem contrato de locação: no portal ele vê os '
                      'documentos compartilhados e os imóveis em nome dele. '
                      'Repasses aparecem quando houver contrato.',
                  inquilino: false,
                ),
            ],
          ],
        );
      },
    );
  }

  Widget _area({
    required String titulo,
    required String caminho,
    required bool papelMarcado,
    required String papel,
    required SituacaoPortal s,
    required String semContrato,
    required bool inquilino,
  }) {
    final semDocumento = widget.contato.documento.trim().isEmpty;
    final podeLiberar =
        s.erro == null && !semDocumento && !widget.documentoAlterado;
    final (situacao, cor) = switch (s) {
      SituacaoPortal(ativo: true, bloqueado: true) => (
        'Bloqueado por tentativas de senha',
        Colors.redAccent,
      ),
      SituacaoPortal(ativo: true, trocarSenha: true) => (
        'Liberado • ainda com a senha provisória',
        Colors.orangeAccent,
      ),
      SituacaoPortal(ativo: true) => ('Liberado', Colors.greenAccent),
      _ => ('Sem acesso', Colors.white54),
    };
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GoldChip(situacao, color: cor),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            s.ativo
                ? 'Login: ${s.login.isEmpty ? 'CPF/CNPJ do cadastro' : s.login}'
                      '${s.ultimoAcesso != null ? ' • último acesso ${formatDateTime(s.ultimoAcesso)}' : ' • ainda não entrou'}'
                : semDocumento
                ? 'Cadastre e salve o CPF/CNPJ: ele é o login.'
                : 'O login será o CPF/CNPJ: ${widget.contato.documento}. '
                      'Endereço: site$caminho',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          if (!papelMarcado)
            _Aviso(
              'O perfil "$papel" não está marcado neste contato. '
              'Marque-o acima para manter o cadastro correto.',
            ),
          if (s.erro != null)
            _Aviso(s.erro!)
          else if (s.temContrato == false)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                semContrato,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _vm.ocupado || !podeLiberar
                    ? null
                    : () => _liberar(inquilino: inquilino),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.navyDark,
                ),
                icon: const Icon(Icons.lock_open, size: 18),
                label: Text(s.ativo ? 'Gerar nova senha' : 'Liberar acesso'),
              ),
              if (s.ativo)
                OutlinedButton.icon(
                  onPressed: _vm.ocupado
                      ? null
                      : () => _revogar(inquilino: inquilino),
                  icon: const Icon(Icons.block, size: 18),
                  label: const Text('Revogar'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, size: 16, color: Colors.orangeAccent),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(color: Colors.orangeAccent, fontSize: 12),
          ),
        ),
      ],
    ),
  );
}
