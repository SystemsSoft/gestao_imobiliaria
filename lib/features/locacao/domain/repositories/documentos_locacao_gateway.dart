import '../entities/documentos.dart';

/// Geração e impressão dos documentos da locação.
abstract interface class DocumentosLocacaoGateway {
  Future<void> imprimirContrato(ContratoDocumento documento);
  Future<void> imprimirBoleto(CobrancaDocumento documento);
  Future<void> imprimirRecibo(CobrancaDocumento documento);
  Future<void> imprimirDemonstrativo(DemonstrativoRepasse demonstrativo);
  Future<void> imprimirInforme(InformeRendimentos informe);
}
