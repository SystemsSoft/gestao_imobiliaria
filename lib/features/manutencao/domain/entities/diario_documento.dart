import '../../../crm/domain/entities/contato.dart';
import '../../../crm/domain/entities/imovel.dart';
import 'manutencao.dart';

/// Dados reunidos para emitir o diário de uma manutenção.
class DiarioDocumento {
  const DiarioDocumento({
    required this.manutencao,
    required this.emitidoEm,
    this.imovel,
    this.proprietario,
  });

  final Manutencao manutencao;
  final Imovel? imovel;
  final Contato? proprietario;
  final DateTime emitidoEm;
}
