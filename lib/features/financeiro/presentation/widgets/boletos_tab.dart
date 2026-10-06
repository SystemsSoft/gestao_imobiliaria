import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/boleto_bancario.dart';
import '../../domain/entities/financeiro_enums.dart';
import '../../domain/entities/lancamento.dart';
import '../viewmodels/boletos_viewmodel.dart';

/// Emissão de boletos e baixa automática pelo retorno bancário.
class BoletosTab extends StatefulWidget {
  const BoletosTab({super.key});

  @override
  State<BoletosTab> createState() => _BoletosTabState();
}

class _BoletosTabState extends State<BoletosTab> {
  final _vm = sl<BoletosViewModel>();

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

  Future<void> _emitir(Lancamento l) async {
    if (_vm.contas.isEmpty) {
      mostrarMensagem(
        context,
        'Cadastre uma conta bancária em "Conciliação bancária" primeiro.',
      );
      return;
    }
    var contaId = _vm.contas.first.id;
    final escolhida = _vm.contas.length == 1
        ? contaId
        : await showDialog<String>(
            context: context,
            builder: (ctx) => SimpleDialog(
              backgroundColor: AppColors.navy,
              title: const Text('Emitir pela conta'),
              children: [
                for (final c in _vm.contas)
                  SimpleDialogOption(
                    onPressed: () => Navigator.pop(ctx, c.id),
                    child: Text(c.descricao),
                  ),
              ],
            ),
          );
    if (escolhida == null) return;
    contaId = escolhida;
    await _acao(() => _vm.emitir(l, contaId), 'Boleto emitido.');
  }

  Future<void> _retorno() async {
    final texto = await showDialog<String>(
      context: context,
      builder: (_) => const _RetornoDialog(),
    );
    if (texto == null || texto.trim().isEmpty) return;
    await _acao(() => _vm.processarRetorno(texto));
    if (!mounted || _vm.ultimoRetorno == null) return;
    final r = _vm.ultimoRetorno!;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.navy,
        title: const Text('Resultado do retorno'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${r.baixados} pagamento(s) baixado(s) automaticamente.',
              style: const TextStyle(
                color: Colors.greenAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (r.naoEncontrados.isNotEmpty)
              Text(
                'Nosso número não encontrado: ${r.naoEncontrados.join(', ')}',
                style: const TextStyle(color: Colors.orangeAccent),
              ),
            if (r.ignorados.isNotEmpty)
              Text(
                'Ignorados (já pagos ou cancelados): ${r.ignorados.join(', ')}',
                style: const TextStyle(color: Colors.orangeAccent),
              ),
            if (r.linhasInvalidas.isNotEmpty)
              Text(
                'Linhas inválidas: ${r.linhasInvalidas.join(' | ')}',
                style: const TextStyle(color: Colors.redAccent),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final lista = _vm.filtrados;
        final semBoleto = _vm.semBoleto;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            ResumoValores(
              itens: [
                (
                  rotulo: 'Boletos emitidos',
                  valor: formatMoney(_vm.totalEmitido),
                  cor: AppColors.gold,
                ),
                (
                  rotulo: 'Pagos (baixados)',
                  valor: formatMoney(_vm.totalPago),
                  cor: Colors.greenAccent,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _retorno,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.navyDark,
                  ),
                  icon: const Icon(Icons.download_done),
                  label: const Text('Processar retorno bancário'),
                ),
                const Tooltip(
                  message:
                      'O envio da remessa e o registro online serão ligados na integração com o banco.',
                  child: OutlinedButton(
                    onPressed: null,
                    child: Text('Enviar remessa (em breve)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'No retorno, cada pagamento marca o boleto como pago e dá baixa na conta a receber, '
              'já na conta bancária do boleto.',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Text(
              'Contas a receber sem boleto (${semBoleto.length})',
              style: const TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            if (semBoleto.isEmpty)
              const Text(
                'Todas as contas a receber em aberto já têm boleto.',
                style: TextStyle(color: Colors.white60),
              ),
            for (final l in semBoleto)
              CardPadrao(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.descricao,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${_vm.nomeContato(l.contatoId) ?? 'Sem cliente'} • vence em ${formatDate(l.vencimento)}'
                            ' • ${formatMoney(l.valor)}',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _vm.ocupado ? null : () => _emitir(l),
                      icon: const Icon(Icons.qr_code_2),
                      label: const Text('Emitir boleto'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            const Text(
              'Boletos',
              style: TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            FiltroChips<StatusBoleto>(
              opcoes: StatusBoleto.values,
              selecionado: _vm.status,
              labelOf: (s) => s.label,
              onChanged: _vm.filtrar,
              padding: EdgeInsets.zero,
            ),
            if (_vm.carregado && lista.isEmpty)
              const EmptyState(
                icon: Icons.qr_code_2,
                message: 'Nenhum boleto emitido.',
              ),
            for (final b in lista) _card(b),
          ],
        );
      },
    );
  }

  Widget _card(BoletoBancario b) {
    final (rotulo, cor) = switch (b.status) {
      StatusBoleto.pago => ('Pago', Colors.greenAccent),
      StatusBoleto.cancelado => ('Cancelado', Colors.grey),
      StatusBoleto.emitido when b.vencido(_vm.hoje) => (
        'Vencido',
        Colors.redAccent,
      ),
      StatusBoleto.emitido => ('Emitido', Colors.orangeAccent),
    };
    return CardPadrao(
      borda: cor,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Nosso nº ${b.nossoNumero}',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GoldChip(rotulo, color: cor),
                  ],
                ),
                Text(
                  _vm.pagador(b),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(
                  '${_vm.nomeConta(b.contaId)} • ${_vm.lancamento(b.lancamentoId)?.descricao ?? ''}',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  b.status == StatusBoleto.pago
                      ? 'Pago ${formatMoney(b.valorPago)} em ${formatDate(b.dataPagamento)}'
                      : 'Vence em ${formatDate(b.vencimento)} • ${formatMoney(b.valor)}',
                  style: const TextStyle(
                    color: AppColors.goldLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (b.status == StatusBoleto.emitido)
            IconButton(
              tooltip: 'Imprimir boleto (PDF)',
              icon: const Icon(
                Icons.picture_as_pdf_outlined,
                color: AppColors.goldLight,
              ),
              onPressed: () => _acao(() => _vm.imprimir(b)),
            ),
          if (b.status == StatusBoleto.emitido)
            IconButton(
              tooltip: 'Cancelar boleto',
              icon: const Icon(Icons.cancel_outlined),
              onPressed: () =>
                  _acao(() => _vm.cancelar(b), 'Boleto cancelado.'),
            ),
        ],
      ),
    );
  }
}

class _RetornoDialog extends StatefulWidget {
  const _RetornoDialog();

  @override
  State<_RetornoDialog> createState() => _RetornoDialogState();
}

class _RetornoDialogState extends State<_RetornoDialog> {
  final _texto = TextEditingController();

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.navy,
      title: const Text('Processar retorno bancário'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Cole uma linha por pagamento, no formato:\nnosso número;valor;dd/mm/aaaa\n'
              'Ex.: 0000000001;3.250,00;12/03/2027\n'
              '(A leitura direta do arquivo CNAB virá com a integração bancária.)',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _texto,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Pagamentos do retorno',
                alignLabelWithHint: true,
              ),
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
          onPressed: () => Navigator.pop(context, _texto.text),
          child: const Text('Baixar pagamentos'),
        ),
      ],
    );
  }
}
