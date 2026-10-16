import 'package:flutter/foundation.dart';

/// Dados da imobiliária, editáveis em Personalização.
@immutable
class DadosEmpresa {
  const DadosEmpresa({
    required this.nome,
    this.atividade = '',
    this.creci = '',
    this.documento = '',
    this.endereco = '',
    this.telefone = '',
    this.email = '',
    this.site = '',
    this.chavePix = '',
  });

  static const padrao = DadosEmpresa(
    nome: 'Marcelo Bonifácio',
    atividade: 'Corretor de Imóveis',
    creci: 'CRECI 065655 RJ',
  );

  final String nome;
  final String atividade;
  final String creci;

  /// CNPJ ou CPF.
  final String documento;
  final String endereco;
  final String telefone;
  final String email;
  final String site;
  final String chavePix;

  /// "Corretor de Imóveis • CRECI 065655 RJ".
  String get atividadeECreci =>
      [atividade, creci].where((e) => e.isNotEmpty).join(' • ');

  /// Documento, endereço e contatos numa linha (para cabeçalhos).
  String get contatos => [
    if (documento.isNotEmpty) 'CNPJ/CPF $documento',
    endereco,
    telefone,
    email,
    site,
  ].where((e) => e.isNotEmpty).join(' • ');
}

/// Dados da imobiliária em uso: contratos, boletos, recibos, repasses e
/// relatórios leem daqui. Carregados da Personalização ao entrar.
class EmpresaInfo {
  EmpresaInfo._();

  static DadosEmpresa _atual = DadosEmpresa.padrao;
  static Uint8List? _logo;

  /// Avisa quem mostra o logotipo/dados na tela.
  static final mudancas = ValueNotifier<int>(0);

  static DadosEmpresa get atual => _atual;

  /// Logotipo personalizado (null = logotipo padrão do sistema).
  static Uint8List? get logo => _logo;

  static String get nome => _atual.nome;
  static String get atividade => _atual.atividade;
  static String get creci => _atual.creci;
  static String get chavePix => _atual.chavePix;

  static void aplicar(DadosEmpresa dados, {Uint8List? logo}) {
    _atual = dados;
    _logo = logo;
    mudancas.value++;
  }
}
