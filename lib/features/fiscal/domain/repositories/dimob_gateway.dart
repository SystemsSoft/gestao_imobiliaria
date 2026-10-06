import '../entities/dimob.dart';

abstract interface class DimobGateway {
  /// Abre a impressão (ou salvamento em PDF) da conferência da DIMOB.
  Future<void> imprimirConferencia(DeclaracaoDimob declaracao);
}
