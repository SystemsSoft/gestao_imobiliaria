import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../../core/widgets/visual_marca.dart';
import '../../../portal_inquilino/presentation/widgets/portal_dialogs.dart';
import '../../../site/domain/repositories/site_repository.dart';
import '../../domain/entities/auditoria.dart';
import '../../domain/usecases/auditoria_usecases.dart';
import '../viewmodels/auditoria_viewmodels.dart';
import 'auditoria_visual.dart';

/// Saúde da carteira de cada proprietário e acesso à Área do proprietário.
class ProprietariosAuditoriaTab extends StatefulWidget {
  const ProprietariosAuditoriaTab({super.key});

  @override
  State<ProprietariosAuditoriaTab> createState() =>
      _ProprietariosAuditoriaTabState();
}

class _ProprietariosAuditoriaTabState extends State<ProprietariosAuditoriaTab> {
  final _vm = sl<ProprietariosAuditoriaViewModel>();

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
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _liberar(ResumoProprietario p) async {
    if (p.acesso != null &&
        !await _confirmar(
          'Gerar nova senha provisória para ${p.nome}? A senha atual deixa '
          'de funcionar e o proprietário é desconectado.',
        )) {
      return;
    }
    if (!await _vm.liberarAcesso(p)) {
      if (mounted) mostrarMensagem(context, _vm.erro ?? 'Erro.');
      return;
    }
    final senha = _vm.senhaGerada!;
    final contato = _vm.contatos[p.contatoId];
    if (!mounted) return;
    await mostrarSenhaProvisoria(
      context,
      senha: senha,
      telefone: contato?.celular.isNotEmpty ?? false
          ? contato!.celular
          : contato?.telefone ?? '',
      mensagem: mensagemDeAcessoProprietario(
        nome: p.nome,
        enderecoSite: sl<SiteRepository>().endereco,
        senha: senha,
      ),
    );
  }

  Future<void> _revogar(ResumoProprietario p) async {
    if (!await _confirmar('Revogar o acesso de ${p.nome} ao portal?')) return;
    final ok = await _vm.revogarAcesso(p);
    if (mounted) {
      mostrarMensagem(context, ok ? 'Acesso revogado.' : (_vm.erro ?? 'Erro.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final lista = _vm.lista;
        return Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                _margem(context),
                20,
                _margem(context),
                0,
              ),
              child: CampoBusca(
                hint: 'Buscar proprietário por nome ou CPF/CNPJ...',
                onChanged: _vm.buscar,
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                _margem(context),
                10,
                _margem(context),
                4,
              ),
              child: Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  for (final s in Saude.values)
                    Text(
                      '● ${s.label}: ${_vm.contar(s)}',
                      style: TextStyle(color: s.cor, fontSize: 13),
                    ),
                  Text(
                    '${_vm.comAcesso} com acesso à Área do proprietário',
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ],
              ),
            ),
            Expanded(
              child: !_vm.carregado
                  ? const Center(child: CircularProgressIndicator())
                  : lista.isEmpty
                  ? const EmptyState(
                      icon: Icons.supervisor_account_outlined,
                      message:
                          'Nenhum proprietário com contrato de locação '
                          '(beneficiário).',
                    )
                  : ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                        _margem(context),
                        4,
                        _margem(context),
                        48,
                      ),
                      itemCount: lista.length,
                      itemBuilder: (_, i) => _card(lista[i]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _card(ResumoProprietario p) {
    final (rotulo, cor) = situacaoAcessoProprietario(p.acesso);
    return CardPadrao(
      borda: p.saude.cor,
      child: Wrap(
        spacing: 16,
        runSpacing: 10,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                backgroundColor: p.saude.cor.withValues(alpha: 0.15),
                child: Icon(Icons.person_outline, color: p.saude.cor),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.nome,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${p.imoveis} imóvel(is) • ${p.contratosAtivos} contrato(s) '
                    'ativo(s) • ${formatMoney(p.aluguelMensal)}/mês',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  Text(
                    [
                      if (p.emAtraso > 0)
                        'Em atraso: ${formatMoney(p.emAtraso)}',
                      if (p.criticas > 0) '${p.criticas} crítica(s)',
                      if (p.atencoes > 0) '${p.atencoes} atenção',
                      p.ultimaAuditoria == null
                          ? 'Nunca auditado'
                          : 'Última auditoria ${formatDate(p.ultimaAuditoria)}',
                    ].join(' • '),
                    style: TextStyle(
                      color: p.saude == Saude.verde
                          ? Colors.white38
                          : p.saude.cor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GoldChip(rotulo, color: cor),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _vm.ocupado ? null : () => _liberar(p),
                icon: const Icon(Icons.lock_open, size: 18),
                label: Text(p.acesso == null ? 'Liberar acesso' : 'Nova senha'),
              ),
              if (p.acesso != null)
                IconButton(
                  tooltip: 'Revogar acesso',
                  icon: const Icon(Icons.block, size: 20),
                  onPressed: _vm.ocupado ? null : () => _revogar(p),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Margem lateral: menor no celular.
double _margem(BuildContext context) =>
    MediaQuery.sizeOf(context).width < 600 ? 16 : 24;
