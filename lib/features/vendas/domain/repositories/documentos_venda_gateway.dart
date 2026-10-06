import '../entities/documentos_venda.dart';

abstract interface class DocumentosVendaGateway {
  Future<void> imprimirCarne(ParcelasDocumento documento);
  Future<void> imprimirPromissorias(ParcelasDocumento documento);
  Future<void> imprimirReciboComissao(ReciboComissaoDocumento documento);
}
