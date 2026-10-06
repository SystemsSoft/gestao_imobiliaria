import '../entities/contrato_documento.dart';

abstract interface class ContratoImpressaoGateway {
  Future<void> imprimirContrato(ContratoDocumento documento);
}
