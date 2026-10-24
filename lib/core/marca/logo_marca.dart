import 'package:flutter/material.dart';

import '../api/api_config.dart';
import '../config/empresa_info.dart';
import '../theme/app_theme.dart';
import 'marca.dart';

/// Logotipo da imobiliária em uso: o da Personalização (depois do login),
/// o do cadastro da plataforma ou, sem logotipo, o nome dela. Antes de a
/// imobiliária ser identificada, nada (o app não tem marca própria).
class LogoMarca extends StatelessWidget {
  const LogoMarca({super.key, this.altura = 120, this.semLogo});

  final double altura;

  /// Mostrado no lugar do nome quando não há logotipo (espaços pequenos).
  final Widget? semLogo;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([MarcaAtual.mudancas, EmpresaInfo.mudancas]),
      builder: (context, _) {
        final marca = MarcaAtual.atual;
        if (marca == null) return semLogo ?? SizedBox(height: altura);
        final bytes = EmpresaInfo.logo;
        if (bytes != null) {
          return Image.memory(bytes, height: altura, fit: BoxFit.contain);
        }
        final alternativa = semLogo ?? _Nome(marca.nome, altura);
        final caminho = marca.logo;
        if (caminho == null) return alternativa;
        return Image.network(
          Uri.parse(ApiConfig.url).resolve(caminho).toString(),
          height: altura,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => alternativa,
        );
      },
    );
  }
}

class _Nome extends StatelessWidget {
  const _Nome(this.nome, this.altura);

  final String nome;
  final double altura;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: altura,
    child: Center(
      child: Text(
        nome,
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: estiloTitulo(
          tamanho: (altura * 0.22).clamp(18, 34).toDouble(),
          cor: AppColors.gold,
        ),
      ),
    ),
  );
}
