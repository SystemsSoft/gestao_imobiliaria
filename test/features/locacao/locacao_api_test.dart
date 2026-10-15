import 'package:flutter_test/flutter_test.dart';
import 'package:marceloimob_gestao/core/api/status_conexao.dart';
import 'package:marceloimob_gestao/core/utils/id.dart';
import 'package:marceloimob_gestao/features/locacao/data/datasources/locacao_api_datasource.dart';
import 'package:marceloimob_gestao/features/locacao/data/repositories/locacao_api_repositories.dart';
import 'package:marceloimob_gestao/features/locacao/domain/entities/cobranca.dart';
import 'package:marceloimob_gestao/features/locacao/domain/entities/contrato_locacao.dart';
import 'package:marceloimob_gestao/features/locacao/domain/entities/despesa.dart';
import 'package:marceloimob_gestao/features/locacao/domain/entities/locacao_enums.dart';
import 'package:marceloimob_gestao/features/locacao/domain/repositories/repasse_repository.dart';
import 'package:marceloimob_gestao/features/locacao/domain/usecases/contrato_usecases.dart';
import 'package:marceloimob_gestao/features/manutencao/data/repositories/manutencao_api_repository.dart';
import 'package:marceloimob_gestao/features/manutencao/domain/entities/manutencao.dart';

import '../../apoio/servidor_falso.dart';

ContratoLocacao _contrato({String numero = ''}) => ContratoLocacao(
  id: gerarId(),
  numero: numero,
  imovelId: 'imovel',
  locatarioId: 'inquilino',
  beneficiarios: const [Beneficiario(contatoId: 'dono', percentual: 100)],
  dataInicio: DateTime(2026, 1, 1),
  valorAluguel: 3000,
  garantia: GarantiaLocacao.seguroFianca,
  taxaAdministracao: 8.5,
);

void main() {
  late ServidorFalso servidor;
  late LocacaoApiDataSource ds;

  setUp(() {
    servidor = ServidorFalso();
    ds = LocacaoApiDataSource(servidor.cliente(), StatusConexao());
  });

  test('contrato recebe o número do servidor e mantém os dados', () async {
    final repo = ContratoLocacaoApiRepository(ds);
    final salvo = await SalvarContrato(repo)(_contrato());
    expect(salvo.numero, 'LOC-0001');
    expect(salvo.garantia, GarantiaLocacao.seguroFianca);
    expect(salvo.taxaAdministracao, 8.5);
    expect(salvo.dataInicio, DateTime(2026, 1, 1));
    expect(
      servidor.colecao('locacao/contratos')[salvo.id]!['dataInicio'],
      '2026-01-01',
    );
    expect((await repo.listar()).single.beneficiarios.single.contatoId, 'dono');
  });

  test('despesa e cobrança paga ida e volta', () async {
    final despesa = Despesa(
      id: gerarId(),
      contratoId: 'c1',
      descricao: 'IPTU',
      valor: 150,
      responsavel: ResponsavelDespesa.proprietario,
      competenciaInicio: DateTime(2026, 1),
      dedutivelIR: true,
    );
    await DespesaApiRepository(ds).salvar(despesa);
    final d = (await DespesaApiRepository(ds).listar()).single;
    expect(
      (d.dedutivelIR, d.responsavel),
      (true, ResponsavelDespesa.proprietario),
    );

    final cobranca = Cobranca(
      id: gerarId(),
      contratoId: 'c1',
      competencia: DateTime(2026, 2),
      vencimento: DateTime(2026, 2, 10),
      itens: const [
        ItemCobranca(
          descricao: 'Aluguel 02/2026',
          valor: 3000,
          tipo: TipoItemCobranca.aluguel,
        ),
      ],
      status: StatusCobranca.paga,
      dataPagamento: DateTime(2026, 2, 15),
      valorPago: 3330.5,
      multa: 300,
      juros: 30.5,
    );
    await CobrancaApiRepository(ds).salvar(cobranca);
    final c = (await CobrancaApiRepository(ds).listar()).single;
    expect(c.valorAluguel, 3000);
    expect(
      (c.status, c.dataPagamento, c.juros),
      (StatusCobranca.paga, DateTime(2026, 2, 15), 30.5),
    );
  });

  test('repasses: marcar e desmarcar refletem no mapa observado', () async {
    final repo = RepasseApiRepository(ds);
    final mapas = <Map<String, DateTime>>[];
    final sub = repo.observarRealizados().listen(mapas.add);
    await repo.marcar('cob', 'dono', DateTime(2026, 2, 20));
    await Future<void>.delayed(Duration.zero);
    expect(mapas.last, {chaveRepasse('cob', 'dono'): DateTime(2026, 2, 20)});
    await repo.marcar('cob', 'dono', null);
    await Future<void>.delayed(Duration.zero);
    expect(mapas.last, isEmpty);
    await sub.cancel();
  });

  test('excluir contrato limpa despesas e cobranças do cache', () async {
    final contratos = ContratoLocacaoApiRepository(ds);
    final despesas = DespesaApiRepository(ds);
    final cobrancas = CobrancaApiRepository(ds);
    final c = await contratos.salvar(_contrato());
    await despesas.salvar(
      Despesa(
        id: gerarId(),
        contratoId: c.id,
        descricao: 'Condomínio',
        valor: 500,
        competenciaInicio: DateTime(2026),
      ),
    );
    await RemoverContrato(contratos, despesas, cobrancas)(c.id);
    expect(
      servidor.requisicoes.last,
      'DELETE /api/v1/locacao/contratos/${c.id}',
    );
    expect(await despesas.listar(), isEmpty);
  });

  test('manutenção grava a pauta com o diário', () async {
    final repo = ManutencaoApiRepository(servidor.cliente(), StatusConexao());
    final m = Manutencao(
      id: gerarId(),
      contexto: ContextoManutencao.venda,
      imovelId: 'imovel',
      tipo: TipoManutencao.eletrica,
      descricao: 'Trocar disjuntores',
      criadaEm: DateTime(2026),
      dataPrevista: DateTime(2026, 10, 30),
      diario: [
        RegistroDiario(
          id: gerarId(),
          data: DateTime(2026, 10, 5),
          profissional: 'Carlos Eletricista',
          servico: 'Troca do quadro',
          valorMaterial: 400,
          valorMaoDeObra: 600,
          valorTaxa: 80,
        ),
      ],
    );
    await repo.observar().first;
    await repo.salvar(m);
    final lida = repo.porId(m.id)!;
    expect(lida.criadaEm, DateTime(2026, 10, 15, 10));
    expect(lida.dataPrevista, DateTime(2026, 10, 30));
    expect(lida.total, 1080);
    expect(lida.diario.single.profissional, 'Carlos Eletricista');
  });
}
