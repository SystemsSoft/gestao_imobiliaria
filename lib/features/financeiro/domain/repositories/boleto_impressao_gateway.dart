import '../../../crm/domain/entities/contato.dart';
import '../entities/boleto_bancario.dart';
import '../entities/conta_bancaria.dart';
import '../entities/lancamento.dart';

class BoletoDocumento {
  const BoletoDocumento({
    required this.boleto,
    required this.lancamento,
    required this.conta,
    required this.pagador,
  });

  final BoletoBancario boleto;
  final Lancamento lancamento;
  final ContaBancaria conta;
  final Contato? pagador;
}

abstract interface class BoletoImpressaoGateway {
  Future<void> imprimirBoleto(BoletoDocumento documento);
}
