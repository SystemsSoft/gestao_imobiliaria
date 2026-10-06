import '../../../crm/domain/entities/contato.dart';
import '../../../crm/domain/entities/imovel.dart';
import 'parcela.dart';
import 'venda.dart';

/// Quem recebe as parcelas (vendedor ou imobiliária).
class Credor {
  const Credor({required this.nome, required this.documento});

  final String nome;
  final String documento;
}

/// Dados comuns ao carnê e às notas promissórias.
class ParcelasDocumento {
  const ParcelasDocumento({
    required this.venda,
    required this.compradores,
    required this.credor,
    required this.imovel,
    required this.parcelas,
  });

  final Venda venda;
  final List<Contato> compradores;
  final Credor credor;
  final Imovel? imovel;
  final List<Parcela> parcelas;
}

class ReciboComissaoDocumento {
  const ReciboComissaoDocumento({
    required this.venda,
    required this.imovel,
    required this.recebedor,
    required this.pagadores,
    required this.percentualParticipacao,
    required this.valor,
    required this.data,
  });

  final Venda venda;
  final Imovel? imovel;

  /// Corretor ou imobiliária que recebe a comissão.
  final Credor recebedor;

  /// Quem paga a corretagem (vendedores).
  final List<Contato> pagadores;
  final double percentualParticipacao;
  final double valor;
  final DateTime data;
}
