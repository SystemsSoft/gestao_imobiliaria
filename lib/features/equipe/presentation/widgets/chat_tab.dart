import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/chat.dart';
import '../viewmodels/chat_viewmodel.dart';
import 'avatar_usuario.dart';

/// Chat interno entre os usuários.
class ChatTab extends StatefulWidget {
  const ChatTab({super.key});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final _vm = sl<ChatViewModel>();
  final _texto = TextEditingController();
  final _rolagem = ScrollController();
  int _qtdMensagens = 0;

  /// Em telas estreitas, mostra a conversa no lugar da lista.
  bool _conversaAberta = false;

  @override
  void dispose() {
    _texto.dispose();
    _rolagem.dispose();
    _vm.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final t = _texto.text;
    if (t.trim().isEmpty) return;
    _texto.clear();
    final ok = await _vm.enviar(t);
    if (!mounted) return;
    if (!ok) {
      _texto.text = t;
      mostrarMensagem(context, _vm.erro ?? 'Não foi possível enviar.');
    }
  }

  Future<void> _entrarComo(String id) async {
    final ok = await _vm.entrarComo(id);
    if (!mounted) return;
    if (!ok) mostrarMensagem(context, _vm.erro ?? 'Não foi possível entrar.');
  }

  void _rolarParaOFim() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_rolagem.hasClients) {
        _rolagem.jumpTo(_rolagem.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        if (!_vm.carregado) return const SizedBox.shrink();
        final n = _vm.mensagens.length;
        if (n != _qtdMensagens) {
          _qtdMensagens = n;
          _rolarParaOFim();
        }
        return Column(
          children: [
            _simulacao(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  if (c.maxWidth >= 760) {
                    return Row(
                      children: [
                        SizedBox(width: 300, child: _lista(aoAbrir: null)),
                        const VerticalDivider(width: 1),
                        Expanded(child: _conversa(voltar: null)),
                      ],
                    );
                  }
                  return _conversaAberta
                      ? _conversa(
                          voltar: () => setState(() => _conversaAberta = false),
                        )
                      : _lista(
                          aoAbrir: () => setState(() => _conversaAberta = true),
                        );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// Escolhe com qual usuário conversar, simulando outro login (sem servidor).
  Widget _simulacao() {
    final ativos = _vm.usuarios.where((u) => u.ativo).toList();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: Colors.black.withValues(alpha: 0.12),
      child: Row(
        children: [
          const Icon(
            Icons.manage_accounts_outlined,
            color: AppColors.gold,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Text(
            'Conversando como:',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<String>(
              value: ativos.any((u) => u.id == _vm.usuarioAtualId)
                  ? _vm.usuarioAtualId
                  : null,
              isExpanded: true,
              dropdownColor: AppColors.navy,
              underline: const SizedBox.shrink(),
              items: [
                for (final u in ativos)
                  DropdownMenuItem(
                    value: u.id,
                    child: Text(
                      '${u.nome} (${u.perfil.label})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (v) {
                if (v != null) _entrarComo(v);
              },
            ),
          ),
          const Tooltip(
            message:
                'Simula entrar como outro usuário para testar o chat. '
                'Com o servidor, cada pessoa usa o próprio login.',
            child: Icon(Icons.info_outline, size: 18, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _lista({required VoidCallback? aoAbrir}) {
    final conversas = _vm.conversas;
    return ListView(
      children: [
        for (final c in conversas)
          ListTile(
            selected: c.id == _vm.conversaId,
            selectedTileColor: AppColors.gold.withValues(alpha: 0.1),
            leading: c.usuario == null
                ? const CircleAvatar(
                    backgroundColor: Color(0x33F5C432),
                    foregroundColor: AppColors.gold,
                    child: Icon(Icons.groups_outlined),
                  )
                : AvatarUsuario(
                    nome: c.titulo,
                    online: _vm.online(c.usuario!.id),
                  ),
            title: Text(
              c.titulo,
              style: TextStyle(
                fontWeight: c.naoLidas > 0 ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
            subtitle: Text(
              c.ultima == null
                  ? (c.usuario == null
                        ? 'Canal de toda a equipe'
                        : 'Nenhuma mensagem')
                  : '${c.ultima!.remetenteId == _vm.usuarioAtualId ? 'Você: ' : ''}${c.ultima!.texto}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
            trailing: c.naoLidas == 0
                ? null
                : CircleAvatar(
                    radius: 11,
                    backgroundColor: AppColors.gold,
                    child: Text(
                      '${c.naoLidas}',
                      style: const TextStyle(
                        color: AppColors.navyDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
            onTap: () {
              _vm.selecionar(c.id);
              aoAbrir?.call();
            },
          ),
        if (conversas.length == 1)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Cadastre mais usuários na aba "Usuários e sessões" para conversar em particular.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _conversa({required VoidCallback? voltar}) {
    final c = _vm.conversaAtual;
    final msgs = _vm.mensagens;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          color: AppColors.navy,
          child: Row(
            children: [
              if (voltar != null)
                IconButton(
                  onPressed: voltar,
                  icon: const Icon(Icons.arrow_back),
                ),
              if (c.usuario == null)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.groups_outlined, color: AppColors.gold),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: AvatarUsuario(
                    nome: c.titulo,
                    online: _vm.online(c.usuario!.id),
                    raio: 16,
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.titulo,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      c.usuario == null
                          ? '${_vm.usuarios.where((u) => u.ativo).length} participante(s)'
                          : (_vm.online(c.usuario!.id) ? 'Online' : 'Offline'),
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: msgs.isEmpty
              ? const EmptyState(
                  icon: Icons.chat_bubble_outline,
                  message: 'Nenhuma mensagem ainda.\nEscreva a primeira.',
                )
              : ListView(
                  controller: _rolagem,
                  padding: const EdgeInsets.all(16),
                  children: _bolhas(msgs, c.usuario == null),
                ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          color: AppColors.navy,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _texto,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _enviar(),
                  decoration: const InputDecoration(
                    hintText: 'Escreva uma mensagem...',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _vm.ocupado ? null : _enviar,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.navyDark,
                ),
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _bolhas(List<Mensagem> msgs, bool geral) {
    final widgets = <Widget>[];
    DateTime? dia;
    for (final m in msgs) {
      final d = DateTime(m.enviadaEm.year, m.enviadaEm.month, m.enviadaEm.day);
      if (dia != d) {
        dia = d;
        widgets.add(
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                formatDate(d),
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ),
          ),
        );
      }
      widgets.add(_bolha(m, geral));
    }
    return widgets;
  }

  Widget _bolha(Mensagem m, bool geral) {
    final minha = m.remetenteId == _vm.usuarioAtualId;
    final hora =
        '${m.enviadaEm.hour.toString().padLeft(2, '0')}:${m.enviadaEm.minute.toString().padLeft(2, '0')}';
    return Align(
      alignment: minha ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 6),
          decoration: BoxDecoration(
            color: minha
                ? AppColors.gold.withValues(alpha: 0.88)
                : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: Radius.circular(minha ? 14 : 3),
              bottomRight: Radius.circular(minha ? 3 : 14),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (geral && !minha)
                Text(
                  _vm.nome(m.remetenteId),
                  style: const TextStyle(
                    color: AppColors.goldLight,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              Text(
                m.texto,
                style: TextStyle(
                  color: minha ? AppColors.navyDark : Colors.white,
                  height: 1.35,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    hora,
                    style: TextStyle(
                      color: minha
                          ? AppColors.navyDark.withValues(alpha: 0.7)
                          : Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                  if (minha)
                    InkWell(
                      onTap: () async {
                        if (!await _vm.apagar(m) && mounted) {
                          mostrarMensagem(
                            context,
                            _vm.erro ?? 'Não foi possível apagar.',
                          );
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Icon(
                          Icons.delete_outline,
                          size: 14,
                          color: AppColors.navyDark,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
