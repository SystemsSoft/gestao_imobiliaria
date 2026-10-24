import 'package:flutter/material.dart';

import '../config/empresa_info.dart';
import '../theme/app_theme.dart';

/// Imobiliária em uso, identificada pelo domínio em que o app abriu ou pelo
/// código digitado: nome, paleta e logotipo cadastrados no painel da
/// plataforma (`GET /api/v1/marca`).
@immutable
class Marca {
  const Marca({
    required this.imobiliaria,
    required this.nome,
    required this.origem,
    this.corPrimaria,
    this.corDestaque,
    this.logo,
  });

  /// As cores padrão do sistema: a imobiliária não escolheu outras.
  static const _primariaPadrao = '#061a48';
  static const _destaquePadrao = '#f5c432';

  factory Marca.fromJson(Map<String, dynamic> json) => Marca(
    imobiliaria: json['imobiliaria'] as String,
    nome: json['nome'] as String? ?? '',
    origem: json['origem'] as String? ?? '',
    corPrimaria: _cor(json['corPrimaria'], _primariaPadrao),
    corDestaque: _cor(json['corDestaque'], _destaquePadrao),
    logo: json['temLogo'] == true ? json['logo'] as String? : null,
  );

  /// Identificador: vai no cabeçalho `X-Imobiliaria` de toda chamada.
  final String imobiliaria;
  final String nome;

  /// Como o servidor a reconheceu: `dominio`, `cabecalho` ou `parametro`.
  final String origem;

  /// Cores da imobiliária (null = a padrão do sistema).
  final Color? corPrimaria;
  final Color? corDestaque;

  /// Caminho do logotipo no servidor (null = sem logotipo).
  final String? logo;

  /// Aberta pelo domínio da imobiliária (não dá para trocar no app).
  bool get peloDominio => origem == 'dominio';

  static Color? _cor(Object? valor, String padrao) {
    if (valor is! String) return null;
    final hex = valor.toLowerCase();
    if (hex == padrao || !RegExp(r'^#[0-9a-f]{6}$').hasMatch(hex)) return null;
    return Color(int.parse('ff${hex.substring(1)}', radix: 16));
  }
}

/// Marca em uso no app. Até a imobiliária ser identificada não há nome nem
/// logotipo, e a paleta é a padrão do sistema.
class MarcaAtual {
  MarcaAtual._();

  /// Avisa o app para redesenhar tudo com a nova identidade.
  static final mudancas = ValueNotifier<Marca?>(null);

  static Marca? get atual => mudancas.value;

  /// Identificador para o cabeçalho `X-Imobiliaria` (null = ainda não há).
  static String? get imobiliaria => atual?.imobiliaria;

  static void aplicar(Marca? marca) {
    AppColors.aplicarPaleta(
      primaria: marca?.corPrimaria,
      destaque: marca?.corDestaque,
    );
    EmpresaInfo.aplicar(
      marca == null ? DadosEmpresa.padrao : DadosEmpresa(nome: marca.nome),
    );
    mudancas.value = marca;
  }
}
