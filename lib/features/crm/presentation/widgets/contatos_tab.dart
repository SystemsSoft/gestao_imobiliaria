import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/contato.dart';
import '../../domain/entities/enums.dart';
import '../pages/contato_form_page.dart';
import '../viewmodels/contatos_viewmodel.dart';

class ContatosTab extends StatefulWidget {
  const ContatosTab({super.key});

  @override
  State<ContatosTab> createState() => _ContatosTabState();
}

class _ContatosTabState extends State<ContatosTab> {
  final _vm = sl<ContatosViewModel>();

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  void _abrir([Contato? contato]) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ContatoFormPage(contato: contato),
      ),
    );
  }

  Future<void> _excluir(Contato c) async {
    if (await confirmDelete(context, 'Excluir o contato "${c.nome}"?')) {
      await _vm.remover(c.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: goldFab(
        icon: Icons.person_add_alt,
        label: 'Novo contato',
        onPressed: _abrir,
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          final lista = _vm.filtrados;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  onChanged: _vm.buscar,
                  decoration: const InputDecoration(
                    hintText:
                        'Buscar por nome, telefone, e-mail ou CPF/CNPJ...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              FiltroChips<PapelContato>(
                opcoes: PapelContato.values,
                selecionado: _vm.papel,
                labelOf: (p) => p.label,
                onChanged: _vm.filtrarPapel,
              ),
              Expanded(
                child: !_vm.carregado
                    ? const SizedBox.shrink()
                    : lista.isEmpty
                    ? EmptyState(
                        icon: Icons.contacts_outlined,
                        message: _vm.semCadastro
                            ? 'Nenhum contato cadastrado.\nToque em "Novo contato" para começar.'
                            : 'Nenhum contato encontrado com esse filtro.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                        itemCount: lista.length,
                        itemBuilder: (_, i) => _ContatoCard(
                          contato: lista[i],
                          onTap: () => _abrir(lista[i]),
                          onDelete: () => _excluir(lista[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ContatoCard extends StatelessWidget {
  const _ContatoCard({
    required this.contato,
    required this.onTap,
    required this.onDelete,
  });

  final Contato contato;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final fone = contato.celular.isNotEmpty
        ? contato.celular
        : contato.telefone;
    return Card(
      color: Colors.white.withValues(alpha: 0.06),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.gold.withValues(alpha: 0.25)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.navyDark,
                child: Text(
                  contato.nome.isEmpty ? '?' : contato.nome[0].toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contato.nome,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        fone,
                        contato.email,
                      ].where((e) => e.isNotEmpty).join('  •  '),
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final p in contato.papeis) GoldChip(p.label),
                        GoldChip(
                          contato.etapa.label,
                          color: AppColors.blueGlow,
                        ),
                        if (contato.perfil != null)
                          const GoldChip(
                            'Perfil de interesse',
                            color: Colors.greenAccent,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                color: AppColors.navy,
                onSelected: (v) => v == 'edit' ? onTap() : onDelete(),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Editar')),
                  PopupMenuItem(value: 'del', child: Text('Excluir')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
