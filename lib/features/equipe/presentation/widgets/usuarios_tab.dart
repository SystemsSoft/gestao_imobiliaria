import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/equipe_enums.dart';
import '../../domain/entities/sessao.dart';
import '../../domain/entities/usuario_sistema.dart';
import '../viewmodels/usuarios_viewmodel.dart';
import 'avatar_usuario.dart';
import 'usuario_dialog.dart';

/// Usuários do sistema e conexões simultâneas.
class UsuariosTab extends StatefulWidget {
  const UsuariosTab({super.key});

  @override
  State<UsuariosTab> createState() => _UsuariosTabState();
}

class _UsuariosTabState extends State<UsuariosTab> {
  final _vm = sl<UsuariosViewModel>();

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _acao(Future<bool> Function() f, [String? sucesso]) async {
    final ok = await f();
    if (!mounted) return;
    if (!ok) {
      mostrarMensagem(context, _vm.erro ?? 'Não foi possível concluir.');
    } else if (sucesso != null) {
      mostrarMensagem(context, sucesso);
    }
  }

  Future<void> _editar([UsuarioSistema? u]) async {
    final novo = await mostrarUsuarioDialog(context, usuario: u);
    if (novo != null) await _acao(() => _vm.salvar(novo), 'Usuário salvo.');
  }

  Future<void> _configurar() async {
    final r = await showDialog<ConfiguracaoSeguranca>(
      context: context,
      builder: (_) => _SegurancaDialog(config: _vm.config),
    );
    if (r != null) {
      await _acao(() => _vm.salvarConfig(r), 'Configuração salva.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: goldFab(
        icon: Icons.person_add_alt_1,
        label: 'Novo usuário',
        onPressed: _editar,
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          final lista = _vm.filtrados;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            children: [
              _painelConexoes(),
              const SizedBox(height: 12),
              TextField(
                onChanged: _vm.buscar,
                decoration: const InputDecoration(
                  hintText: 'Buscar usuário por nome ou e-mail...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              FiltroChips<PerfilAcesso>(
                opcoes: PerfilAcesso.values,
                selecionado: _vm.perfil,
                labelOf: (p) => p.label,
                onChanged: _vm.filtrarPerfil,
                padding: EdgeInsets.zero,
              ),
              for (final u in lista) _card(u),
            ],
          );
        },
      ),
    );
  }

  Widget _painelConexoes() {
    final sessoes = _vm.sessoesAtivas;
    final cor = _vm.limiteAtingido ? Colors.orangeAccent : Colors.greenAccent;
    return FormSection(
      title: 'Conexões simultâneas',
      icon: Icons.lan_outlined,
      children: [
        Row(
          children: [
            Text(
              '${_vm.conectados} de ${_vm.limite}',
              style: TextStyle(
                color: cor,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'usuários conectados agora (limite de licenças)',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _configurar,
              icon: const Icon(Icons.tune, size: 18),
              label: const Text('Configurar'),
            ),
          ],
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (_vm.conectados / _vm.limite).clamp(0, 1),
            minHeight: 8,
            color: cor,
            backgroundColor: Colors.white12,
          ),
        ),
        Text(
          'Sessões sem atividade por ${_vm.config.inatividadeMinutos} minutos deixam de contar como conectadas. '
          'Em rede, as conexões serão registradas pelo servidor; aqui aparecem as deste computador.',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        for (final s in sessoes) _sessao(s),
      ],
    );
  }

  Widget _sessao(SessaoUsuario s) {
    final u = _vm.usuario(s.usuarioId);
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: AvatarUsuario(nome: u?.nome ?? '?', online: true, raio: 18),
      title: Text(u?.nome ?? 'Usuário removido'),
      subtitle: Text(
        '${s.dispositivo} • desde ${formatDateTime(s.inicio)}'
        '${s.usuarioId == _vm.usuarioAtualId ? ' • esta sessão' : ''}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: TextButton.icon(
        onPressed: () =>
            _acao(() => _vm.encerrarSessao(s), 'Sessão encerrada.'),
        icon: const Icon(Icons.logout, size: 18),
        label: const Text('Encerrar'),
        style: TextButton.styleFrom(foregroundColor: Colors.orangeAccent),
      ),
    );
  }

  Widget _card(UsuarioSistema u) {
    final online = _vm.online(u);
    return CardPadrao(
      onTap: () => _editar(u),
      child: Row(
        children: [
          AvatarUsuario(nome: u.nome, online: online),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        u.nome,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: u.ativo ? null : Colors.white54,
                        ),
                      ),
                    ),
                    if (u.id == _vm.usuarioAtualId) ...const [
                      SizedBox(width: 6),
                      GoldChip('Você', color: Colors.greenAccent),
                    ],
                  ],
                ),
                Text(
                  u.email,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    GoldChip(u.perfil.label),
                    if (!u.ativo)
                      const GoldChip('Desativado', color: Colors.redAccent),
                    if (online)
                      const GoldChip('Online', color: Colors.greenAccent),
                    if (u.atendeNaFila)
                      const GoldChip('Na fila', color: AppColors.blueGlow),
                    if (u.creci.isNotEmpty)
                      GoldChip('CRECI ${u.creci}', color: Colors.white54),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            color: AppColors.navy,
            onSelected: (v) => switch (v) {
              'editar' => _editar(u),
              'ativo' => _acao(
                () => _vm.alternarAtivo(u),
                u.ativo ? 'Usuário desativado.' : 'Usuário reativado.',
              ),
              _ => () async {
                if (await confirmDelete(
                  context,
                  'Excluir o usuário "${u.nome}"?',
                )) {
                  await _acao(() => _vm.remover(u), 'Usuário excluído.');
                }
              }(),
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'editar', child: Text('Editar')),
              PopupMenuItem(
                value: 'ativo',
                child: Text(u.ativo ? 'Desativar acesso' : 'Reativar acesso'),
              ),
              const PopupMenuItem(value: 'del', child: Text('Excluir')),
            ],
          ),
        ],
      ),
    );
  }
}

class _SegurancaDialog extends StatefulWidget {
  const _SegurancaDialog({required this.config});

  final ConfiguracaoSeguranca config;

  @override
  State<_SegurancaDialog> createState() => _SegurancaDialogState();
}

class _SegurancaDialogState extends State<_SegurancaDialog> {
  late final _limite = TextEditingController(
    text: '${widget.config.limiteSessoes}',
  );
  late final _inatividade = TextEditingController(
    text: '${widget.config.inatividadeMinutos}',
  );

  @override
  void dispose() {
    _limite.dispose();
    _inatividade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.navy,
      title: const Text('Segurança das conexões'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            AppTextField.integer(
              label: 'Usuários simultâneos (licenças)',
              controller: _limite,
            ),
            const SizedBox(height: 12),
            AppTextField.integer(
              label: 'Encerrar por inatividade (minutos)',
              controller: _inatividade,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: AppColors.navyDark,
          ),
          onPressed: () => Navigator.pop(
            context,
            ConfiguracaoSeguranca(
              limiteSessoes: parseInt(_limite.text) ?? 0,
              inatividadeMinutos: parseInt(_inatividade.text) ?? 0,
            ),
          ),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
