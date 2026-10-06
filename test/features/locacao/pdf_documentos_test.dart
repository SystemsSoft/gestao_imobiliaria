import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:marceloimob_gestao/features/crm/domain/entities/contato.dart';
import 'package:marceloimob_gestao/features/crm/domain/entities/imovel.dart';
import 'package:marceloimob_gestao/features/locacao/data/documentos/pdf_documentos_locacao_gateway.dart';
import 'package:marceloimob_gestao/features/locacao/domain/entities/cobranca.dart';
import 'package:marceloimob_gestao/features/locacao/domain/entities/contrato_locacao.dart';
import 'package:marceloimob_gestao/features/locacao/domain/entities/documentos.dart';
import 'package:marceloimob_gestao/features/locacao/domain/entities/ir_mensal.dart';
import 'package:marceloimob_gestao/features/locacao/domain/entities/locacao_enums.dart';
import 'package:marceloimob_gestao/features/locacao/domain/usecases/repasse_usecases.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final gateway = PdfDocumentosLocacaoGateway();
  final contato = Contato(id: 'p', nome: 'José Ação', criadoEm: DateTime(2026));
  final contrato = ContratoLocacao(
    id: 'k',
    numero: 'LOC-0001',
    imovelId: 'i',
    locatarioId: 'p',
    beneficiarios: const [Beneficiario(contatoId: 'p', percentual: 100)],
    dataInicio: DateTime(2026),
    valorAluguel: 2500,
  );
  final cobranca = Cobranca(
    id: 'c',
    contratoId: 'k',
    competencia: DateTime(2026),
    vencimento: DateTime(2026, 1, 10),
    itens: const [
      ItemCobranca(
        descricao: 'Aluguel 01/2026',
        valor: 2500,
        tipo: TipoItemCobranca.aluguel,
      ),
    ],
    status: StatusCobranca.paga,
    dataPagamento: DateTime(2026, 1, 10),
    valorPago: 2500,
  );
  final doc = CobrancaDocumento(
    cobranca: cobranca,
    contrato: contrato,
    locatario: contato,
    imovel: Imovel(id: 'i', codigo: 'IM-1', titulo: 'Casa', cidade: 'Niterói'),
  );

  void ehPdf(List<int> bytes) =>
      expect(ascii.decode(bytes.take(5).toList()), '%PDF-');

  test('gera contrato, boleto e recibo', () async {
    ehPdf(
      await gateway.gerarContrato(
        const ContratoDocumento(
          titulo: 'CONTRATO DE LOCAÇÃO',
          texto: 'Cláusula 1ª – São Paulo, ação, opção.\n\nCláusula 2ª.',
          assinaturas: ['LOCADOR', 'LOCATÁRIO'],
        ),
      ),
    );
    ehPdf(await gateway.gerarBoleto(doc));
    ehPdf(await gateway.gerarRecibo(doc));
  });

  test('gera demonstrativo de repasse e informe de rendimentos', () async {
    final linhas = const CalcularRepasse()(
      cobranca: cobranca,
      contrato: contrato,
      despesas: const [],
      locatarioPessoaJuridica: false,
      beneficiarioPessoaJuridica: (_) => false,
    );
    ehPdf(
      await gateway.gerarDemonstrativo(
        DemonstrativoRepasse(
          beneficiario: contato,
          competencia: DateTime(2026),
          linhas: linhas,
          imovelPorContrato: const {'k': 'IM-1 • Casa'},
        ),
      ),
    );
    ehPdf(
      await gateway.gerarInforme(
        InformeRendimentos(
          beneficiario: contato,
          ano: 2026,
          meses: [
            for (var m = 1; m <= 12; m++)
              IrMensal(mes: m, rendimentoBruto: 2500),
          ],
        ),
      ),
    );
  });
}
