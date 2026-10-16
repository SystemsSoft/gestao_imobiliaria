import 'dart:typed_data';

import '../../../../core/config/empresa_info.dart';

/// Dados da imobiliária e logotipo (Personalização).
abstract interface class EmpresaRepository {
  Future<DadosEmpresa> obter();
  Future<void> salvar(DadosEmpresa dados);

  /// Logotipo personalizado; null = padrão do sistema.
  Future<Uint8List?> obterLogo();
  Future<void> salvarLogo(Uint8List imagem);
  Future<void> removerLogo();
}
