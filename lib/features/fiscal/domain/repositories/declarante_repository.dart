import '../entities/declarante_dimob.dart';

abstract interface class DeclaranteRepository {
  Stream<DeclaranteDimob> observar();
  Future<DeclaranteDimob> obter();
  Future<void> salvar(DeclaranteDimob declarante);
}
