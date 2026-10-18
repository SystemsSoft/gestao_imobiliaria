import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/midia_anexo.dart';
import '../../domain/entities/portal.dart';
import '../../domain/repositories/portal_repository.dart';

/// Fotos e vídeos que o inquilino anexou ao chamado (no detalhe da
/// manutenção). Não mostra nada se não houver anexos.
class AnexosChamado extends StatefulWidget {
  const AnexosChamado({super.key, required this.manutencaoId});

  final String manutencaoId;

  @override
  State<AnexosChamado> createState() => _AnexosChamadoState();
}

class _AnexosChamadoState extends State<AnexosChamado> {
  late final Future<List<ArquivoContrato>> _anexos =
      sl<PortalInquilinoRepository>().arquivos(
        manutencaoId: widget.manutencaoId,
      );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ArquivoContrato>>(
      future: _anexos,
      builder: (context, s) {
        final itens = s.data ?? const [];
        if (itens.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.photo_library_outlined,
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Fotos e vídeos do inquilino',
                    style: estiloTitulo(tamanho: 20),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final a in itens)
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => abrirAnexo(context, a.referencia),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox.square(
                          dimension: 110,
                          child: ImagemAnexo(
                            a.referencia,
                            alternativa: const ColoredBox(
                              color: AppColors.navy,
                              child: Icon(
                                Icons.play_circle_outline,
                                color: AppColors.gold,
                                size: 36,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
