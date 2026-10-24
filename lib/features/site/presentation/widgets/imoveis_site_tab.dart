import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../../core/widgets/midia_anexo.dart';
import '../../../../core/widgets/visual_marca.dart';
import '../../../crm/domain/entities/enums.dart';
import '../../../crm/domain/entities/imovel.dart';
import '../../domain/repositories/site_repository.dart';
import '../../domain/usecases/site_usecases.dart';
import '../viewmodels/site_viewmodels.dart';

/// Escolhe quais imóveis aparecem no site e quais ficam em destaque.
class ImoveisSiteTab extends StatefulWidget {
  const ImoveisSiteTab({super.key});

  @override
  State<ImoveisSiteTab> createState() => _ImoveisSiteTabState();
}

class _ImoveisSiteTabState extends State<ImoveisSiteTab> {
  final _vm = sl<ImoveisNoSiteViewModel>();
  final _site = sl<SiteRepository>().endereco;

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _resultado(Future<bool> acao, String sucesso) async {
    final ok = await acao;
    if (mounted) mostrarMensagem(context, ok ? sucesso : (_vm.erro ?? 'Erro.'));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final lista = _vm.filtrados;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: CampoBusca(
                hint: 'Buscar por código, título ou bairro...',
                onChanged: _vm.buscar,
              ),
            ),
            FiltroChips<FiltroPublicacao>(
              opcoes: FiltroPublicacao.values,
              selecionado: _vm.filtro,
              labelOf: (f) => switch (f) {
                FiltroPublicacao.publicados => '${f.label} (${_vm.publicados})',
                FiltroPublicacao.destaques => '${f.label} (${_vm.destaques})',
                _ => f.label,
              },
              onChanged: _vm.filtrar,
              padding: const EdgeInsets.symmetric(horizontal: 24),
            ),
            Expanded(
              child: !_vm.carregado
                  ? const SizedBox.shrink()
                  : lista.isEmpty
                  ? EmptyState(
                      icon: Icons.apartment,
                      message: _vm.semImoveis
                          ? 'Nenhum imóvel cadastrado.\nCadastre em "Cadastros e CRM".'
                          : 'Nenhum imóvel com esse filtro.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      itemCount: lista.length,
                      itemBuilder: (_, i) => _card(lista[i]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _card(Imovel i) {
    final foto = i.primeiraFoto;
    final pendencias = i.publicarSite ? pendenciasNoSite(i) : const <String>[];
    final noAr = i.publicarSite && i.status == StatusImovel.disponivel;
    return CardPadrao(
      borda: noAr ? Colors.greenAccent : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox.square(
              dimension: 72,
              child: foto == null
                  ? ColoredBox(
                      color: AppColors.navy,
                      child: Icon(Icons.home_outlined, color: Colors.white38),
                    )
                  : ImagemAnexo(
                      foto,
                      alternativa: ColoredBox(color: AppColors.navy),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      i.codigo,
                      style: TextStyle(
                        color: AppColors.gold.withValues(alpha: 0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (noAr)
                      const GoldChip('No ar', color: Colors.greenAccent),
                  ],
                ),
                Text(
                  i.titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (i.enderecoResumo.isNotEmpty)
                  Text(
                    i.enderecoResumo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                for (final p in pendencias)
                  Text(
                    '⚠ $p',
                    style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 12,
                    ),
                  ),
                if (noAr)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      foregroundColor: AppColors.goldLight,
                    ),
                    onPressed: () => launchUrl(
                      Uri.parse('$_site/imovel/${i.codigo}'),
                      webOnlyWindowName: '_blank',
                    ),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Ver no site'),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _chave(
                'Publicar',
                i.publicarSite,
                (v) => _resultado(
                  _vm.publicar(i, v),
                  v ? 'Publicado no site.' : 'Retirado do site.',
                ),
              ),
              _chave(
                'Destaque',
                i.destaqueSite,
                i.publicarSite
                    ? (v) => _resultado(
                        _vm.destacar(i, v),
                        v ? 'Em destaque na página inicial.' : 'Sem destaque.',
                      )
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chave(String rotulo, bool valor, ValueChanged<bool>? onChanged) =>
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            rotulo,
            style: TextStyle(
              color: onChanged == null ? Colors.white30 : Colors.white70,
              fontSize: 13,
            ),
          ),
          Switch(
            value: valor,
            activeThumbColor: AppColors.gold,
            onChanged: onChanged,
          ),
        ],
      );
}
