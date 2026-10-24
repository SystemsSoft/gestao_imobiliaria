import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/campos_modelo.dart';
import '../../domain/entities/clausula_modelo.dart';
import '../../domain/entities/parametro_modelo.dart';

/// Escolhe o que inserir no texto: campo do sistema, parâmetro próprio ou
/// cláusula da biblioteca. Retorna um [String] (marcador) ou uma
/// [ClausulaModelo].
Future<Object?> mostrarInserirDialog(
  BuildContext context, {
  required List<CampoModelo> campos,
  required List<ParametroModelo> parametros,
  required List<ClausulaModelo> clausulas,
  int abaInicial = 0,
}) => showDialog<Object>(
  context: context,
  builder: (_) => _InserirDialog(
    campos: campos,
    parametros: parametros,
    clausulas: clausulas,
    abaInicial: abaInicial,
  ),
);

class _InserirDialog extends StatefulWidget {
  const _InserirDialog({
    required this.campos,
    required this.parametros,
    required this.clausulas,
    required this.abaInicial,
  });

  final List<CampoModelo> campos;
  final List<ParametroModelo> parametros;
  final List<ClausulaModelo> clausulas;
  final int abaInicial;

  @override
  State<_InserirDialog> createState() => _InserirDialogState();
}

class _InserirDialogState extends State<_InserirDialog> {
  String _q = '';

  bool _casa(String t) =>
      _q.isEmpty || t.toLowerCase().contains(_q.toLowerCase());

  @override
  Widget build(BuildContext context) {
    final grupos = <String, List<CampoModelo>>{};
    for (final c in widget.campos.where(
      (c) => _casa('${c.chave} ${c.descricao}'),
    )) {
      grupos.putIfAbsent(c.grupo, () => []).add(c);
    }
    final params = widget.parametros
        .where((p) => _casa('${p.chave} ${p.rotulo}'))
        .toList();
    final clausulas = widget.clausulas
        .where((c) => _casa('${c.titulo} ${c.texto}'))
        .toList();
    return DefaultTabController(
      length: 3,
      initialIndex: widget.abaInicial,
      child: Dialog(
        backgroundColor: AppColors.navy,
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640, maxHeight: 640),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Inserir no texto',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  onChanged: (v) => setState(() => _q = v),
                  decoration: const InputDecoration(
                    hintText: 'Buscar...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              TabBar(
                indicatorColor: AppColors.gold,
                labelColor: AppColors.gold,
                unselectedLabelColor: Colors.white70,
                tabs: [
                  Tab(text: 'Campos do sistema'),
                  Tab(text: 'Meus parâmetros'),
                  Tab(text: 'Cláusulas'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    ListView(
                      padding: const EdgeInsets.all(8),
                      children: [
                        for (final e in grupos.entries) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
                            child: Text(
                              e.key,
                              style: TextStyle(
                                color: AppColors.gold,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          for (final c in e.value)
                            ListTile(
                              dense: true,
                              title: Text(
                                c.marcador,
                                style: const TextStyle(fontFamily: 'monospace'),
                              ),
                              subtitle: Text(
                                '${c.descricao}${c.exemplo.isEmpty ? '' : ' • ex.: ${c.exemplo}'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => Navigator.pop(context, c.marcador),
                            ),
                        ],
                      ],
                    ),
                    params.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'Nenhum parâmetro próprio ainda.\nCrie na aba "Parâmetros" do editor.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white60),
                              ),
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.all(8),
                            children: [
                              for (final p in params)
                                ListTile(
                                  dense: true,
                                  title: Text(
                                    p.marcador,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${p.rotulo} • padrão: ${p.valorPadrao.isEmpty ? '—' : p.valorPadrao}',
                                  ),
                                  onTap: () =>
                                      Navigator.pop(context, p.marcador),
                                ),
                            ],
                          ),
                    ListView(
                      padding: const EdgeInsets.all(8),
                      children: [
                        for (final c in clausulas)
                          Card(
                            color: Colors.white.withValues(alpha: 0.06),
                            child: ListTile(
                              title: Text(
                                c.titulo,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                c.texto,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Icon(
                                Icons.add_circle_outline,
                                color: AppColors.gold,
                              ),
                              onTap: () => Navigator.pop(context, c),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
