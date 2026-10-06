import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/equipe_enums.dart';
import '../../domain/entities/fila.dart';
import '../viewmodels/fila_viewmodel.dart';
import 'avatar_usuario.dart';

/// Fila de corretores: quem atende o próximo cliente.
class FilaTab extends StatefulWidget {
  const FilaTab({super.key});

  @override
  State<FilaTab> createState() => _FilaTabState();
}

class _FilaTabState extends State<FilaTab> {
  final _vm = sl<FilaViewModel>();

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

  Future<void> _chamar() async {
    final proximo = _vm.proximo;
    final r =
        await showDialog<
          ({
            String cliente,
            OrigemAtendimento origem,
            String? contatoId,
            String obs,
          })
        >(
          context: context,
          builder: (_) => _ChamarDialog(vm: _vm),
        );
    if (r == null) return;
    await _acao(
      () => _vm.chamar(
        cliente: r.cliente,
        origem: r.origem,
        contatoId: r.contatoId,
        observacao: r.obs,
      ),
      proximo == null
          ? null
          : 'Cliente encaminhado a ${_vm.nome(proximo.usuarioId)}.',
    );
  }

  Future<void> _finalizar(Atendimento a) async {
    final c = TextEditingController();
    final obs = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.navy,
        title: const Text('Finalizar atendimento'),
        content: SizedBox(
          width: 420,
          child: AppTextField(
            label: 'Resultado / observações',
            controller: c,
            maxLines: 3,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.navyDark,
            ),
            onPressed: () => Navigator.pop(ctx, c.text),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
    c.dispose();
    if (obs != null) {
      await _acao(() => _vm.finalizar(a, obs), 'Atendimento finalizado.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final proximo = _vm.proximo;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            _proximo(proximo),
            const SizedBox(height: 16),
            _entrar(),
            const SizedBox(height: 8),
            Text(
              'Fila (${_vm.fila.length}) • ${_vm.atendimentosHojeTotal} atendimento(s) hoje',
              style: const TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            if (_vm.carregado && _vm.fila.isEmpty)
              const EmptyState(
                icon: Icons.groups_outlined,
                message:
                    'A fila está vazia.\nAdicione corretores acima para distribuir os atendimentos.',
              ),
            for (var i = 0; i < _vm.fila.length; i++) _item(i, _vm.fila[i]),
            if (_vm.emAndamento.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Em atendimento',
                style: TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              for (final a in _vm.emAndamento) _atendimento(a),
            ],
            if (_vm.historico.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Últimos atendimentos',
                style: TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              for (final a in _vm.historico.take(15)) _atendimento(a),
            ],
          ],
        );
      },
    );
  }

  Widget _proximo(ItemFila? proximo) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [AppColors.blue.withValues(alpha: 0.55), AppColors.navy],
        ),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          if (proximo != null)
            AvatarUsuario(nome: _vm.nome(proximo.usuarioId), raio: 28),
          if (proximo == null)
            const Icon(
              Icons.person_off_outlined,
              size: 40,
              color: Colors.white54,
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PRÓXIMO DA VEZ',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 12,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  proximo == null
                      ? 'Nenhum corretor disponível'
                      : _vm.nome(proximo.usuarioId),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: proximo == null || _vm.ocupado ? null : _chamar,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.navyDark,
            ),
            icon: const Icon(Icons.support_agent),
            label: const Text('Novo atendimento'),
          ),
        ],
      ),
    );
  }

  Widget _entrar() {
    final elegiveis = _vm.elegiveis;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text('Entrar na fila:', style: TextStyle(color: Colors.white70)),
        if (elegiveis.isEmpty)
          const Text(
            'todos os corretores já estão na fila (ou marque "Atende na fila" no cadastro do usuário).',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        for (final u in elegiveis)
          ActionChip(
            avatar: AvatarUsuario(nome: u.nome, raio: 11),
            label: Text(u.nome),
            onPressed: () => _acao(() => _vm.entrar(u.id)),
          ),
      ],
    );
  }

  Widget _item(int i, ItemFila item) {
    final (cor, icone) = switch (item.status) {
      StatusFila.disponivel => (Colors.greenAccent, Icons.check_circle_outline),
      StatusFila.emAtendimento => (AppColors.gold, Icons.headset_mic_outlined),
      StatusFila.ausente => (Colors.grey, Icons.pause_circle_outline),
    };
    final proximo = item.usuarioId == _vm.proximo?.usuarioId;
    return CardPadrao(
      borda: proximo ? AppColors.gold : cor,
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '${i + 1}º',
              style: const TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          AvatarUsuario(nome: _vm.nome(item.usuarioId)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _vm.nome(item.usuarioId),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (proximo) ...const [
                      SizedBox(width: 6),
                      GoldChip('Da vez'),
                    ],
                  ],
                ),
                Row(
                  children: [
                    Icon(icone, size: 14, color: cor),
                    const SizedBox(width: 4),
                    Text(
                      '${item.status.label} desde ${_hora(item.desde)} • '
                      '${_vm.atendimentosHoje(item.usuarioId)} atendimento(s) hoje',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Subir na fila',
            icon: const Icon(Icons.keyboard_arrow_up),
            onPressed: i == 0
                ? null
                : () => _acao(() => _vm.mover(item.usuarioId, -1)),
          ),
          IconButton(
            tooltip: 'Descer na fila',
            icon: const Icon(Icons.keyboard_arrow_down),
            onPressed: i == _vm.fila.length - 1
                ? null
                : () => _acao(() => _vm.mover(item.usuarioId, 1)),
          ),
          PopupMenuButton<String>(
            color: AppColors.navy,
            onSelected: (v) => switch (v) {
              'pular' => _acao(
                () => _vm.pular(item.usuarioId),
                'Vez passada para o fim da fila.',
              ),
              'ausente' => _acao(
                () => _vm.mudarStatus(item.usuarioId, StatusFila.ausente),
              ),
              'voltar' => _acao(
                () => _vm.mudarStatus(item.usuarioId, StatusFila.disponivel),
              ),
              _ => _acao(() => _vm.sair(item.usuarioId)),
            },
            itemBuilder: (_) => [
              if (item.status == StatusFila.disponivel)
                const PopupMenuItem(
                  value: 'pular',
                  child: Text('Passar a vez'),
                ),
              if (item.status == StatusFila.disponivel)
                const PopupMenuItem(
                  value: 'ausente',
                  child: Text('Marcar como ausente'),
                ),
              if (item.status == StatusFila.ausente)
                const PopupMenuItem(
                  value: 'voltar',
                  child: Text('Voltar à fila'),
                ),
              const PopupMenuItem(
                value: 'sair',
                child: Text('Remover da fila'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _hora(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  Widget _atendimento(Atendimento a) {
    final dur = a.duracao;
    return CardPadrao(
      borda: a.emAndamento ? AppColors.gold : Colors.white54,
      child: Row(
        children: [
          AvatarUsuario(nome: _vm.nome(a.corretorId), raio: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.clienteNome,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${_vm.nome(a.corretorId)} • ${a.origem.label} • ${formatDateTime(a.iniciadoEm)}'
                  '${dur == null ? '' : ' • ${dur.inMinutes} min'}',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
                if (a.observacao.isNotEmpty)
                  Text(
                    a.observacao,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
              ],
            ),
          ),
          if (a.emAndamento)
            FilledButton(
              onPressed: _vm.ocupado ? null : () => _finalizar(a),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.navyDark,
              ),
              child: const Text('Finalizar'),
            ),
        ],
      ),
    );
  }
}

class _ChamarDialog extends StatefulWidget {
  const _ChamarDialog({required this.vm});

  final FilaViewModel vm;

  @override
  State<_ChamarDialog> createState() => _ChamarDialogState();
}

class _ChamarDialogState extends State<_ChamarDialog> {
  final _cliente = TextEditingController();
  final _obs = TextEditingController();
  OrigemAtendimento _origem = OrigemAtendimento.plantao;
  String? _contatoId;

  @override
  void dispose() {
    _cliente.dispose();
    _obs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contatos = widget.vm.contatos;
    final proximo = widget.vm.proximo;
    return AlertDialog(
      backgroundColor: AppColors.navy,
      title: const Text('Novo atendimento'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (proximo != null)
                Text(
                  'Será encaminhado a ${widget.vm.nome(proximo.usuarioId)}.',
                  style: const TextStyle(
                    color: AppColors.goldLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              const SizedBox(height: 12),
              AppDropdown<String?>(
                label: 'Cliente já cadastrado (opcional)',
                value: contatos.any((c) => c.id == _contatoId)
                    ? _contatoId
                    : null,
                items: [null, ...contatos.map((c) => c.id)],
                labelOf: (id) => id == null
                    ? 'Novo cliente'
                    : widget.vm.nomeContato(id) ?? '',
                onChanged: (v) => setState(() {
                  _contatoId = v;
                  if (v != null) _cliente.text = widget.vm.nomeContato(v) ?? '';
                }),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Nome do cliente *',
                controller: _cliente,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              AppDropdown<OrigemAtendimento>(
                label: 'Origem',
                value: _origem,
                items: OrigemAtendimento.values,
                labelOf: (o) => o.label,
                onChanged: (v) => setState(() => _origem = v ?? _origem),
              ),
              const SizedBox(height: 12),
              AppTextField(label: 'Observações', controller: _obs, maxLines: 2),
            ],
          ),
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
          onPressed: () => Navigator.pop(context, (
            cliente: _cliente.text,
            origem: _origem,
            contatoId: _contatoId,
            obs: _obs.text,
          )),
          child: const Text('Encaminhar'),
        ),
      ],
    );
  }
}
