import '../entities/portal.dart';

abstract interface class PortalInquilinoRepository {
  Future<List<AcessoInquilino>> acessos();

  /// Libera o acesso ou gera nova senha provisória (derruba as sessões).
  Future<SenhaProvisoria> liberarAcesso(String contatoId);
  Future<void> revogarAcesso(String contatoId);

  Future<List<ArquivoContrato>> arquivos({
    String? contratoId,
    String? manutencaoId,
  });
  Future<void> salvarArquivo(ArquivoContrato arquivo);
  Future<void> removerArquivo(String id);

  Future<List<ComunicadoInquilino>> comunicados({String? contratoId});
  Future<void> enviarComunicado({
    String? contratoId,
    required String titulo,
    required String mensagem,
  });
  Future<void> removerComunicado(String id);
}
