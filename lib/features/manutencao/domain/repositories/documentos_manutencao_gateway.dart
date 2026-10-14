import '../entities/diario_documento.dart';

/// Geração e impressão dos documentos de manutenção.
abstract interface class DocumentosManutencaoGateway {
  Future<void> imprimirDiario(DiarioDocumento documento);
}
