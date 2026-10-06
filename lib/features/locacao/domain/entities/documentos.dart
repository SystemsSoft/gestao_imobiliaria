import '../../../crm/domain/entities/contato.dart';
import '../../../crm/domain/entities/imovel.dart';
import 'cobranca.dart';
import 'contrato_locacao.dart';
import 'ir_mensal.dart';
import 'linha_repasse.dart';

/// Contrato já preenchido, pronto para impressão.
class ContratoDocumento {
  const ContratoDocumento({
    required this.titulo,
    required this.texto,
    required this.assinaturas,
  });

  final String titulo;
  final String texto;

  /// Rótulos das linhas de assinatura (ex.: "LOCADOR: Fulano").
  final List<String> assinaturas;
}

/// Dados para boleto e recibo de uma cobrança.
class CobrancaDocumento {
  const CobrancaDocumento({
    required this.cobranca,
    required this.contrato,
    required this.locatario,
    required this.imovel,
  });

  final Cobranca cobranca;
  final ContratoLocacao contrato;
  final Contato? locatario;
  final Imovel? imovel;
}

class DemonstrativoRepasse {
  const DemonstrativoRepasse({
    required this.beneficiario,
    required this.competencia,
    required this.linhas,
    required this.imovelPorContrato,
  });

  final Contato beneficiario;
  final DateTime competencia;
  final List<LinhaRepasse> linhas;

  /// Descrição do imóvel de cada contrato (id do contrato → texto).
  final Map<String, String> imovelPorContrato;
}

class InformeRendimentos {
  const InformeRendimentos({
    required this.beneficiario,
    required this.ano,
    required this.meses,
  });

  final Contato beneficiario;
  final int ano;
  final List<IrMensal> meses;
}
