import 'package:flutter_test/flutter_test.dart';
import 'package:marceloimob_gestao/core/di/injector.dart';
import 'package:marceloimob_gestao/core/errors/domain_exception.dart';
import 'package:marceloimob_gestao/features/crm/domain/entities/contato.dart';
import 'package:marceloimob_gestao/features/crm/domain/entities/enums.dart';
import 'package:marceloimob_gestao/features/crm/domain/entities/imovel.dart';
import 'package:marceloimob_gestao/features/crm/domain/repositories/contato_repository.dart';
import 'package:marceloimob_gestao/features/crm/domain/repositories/imovel_repository.dart';
import 'package:marceloimob_gestao/features/locacao/domain/entities/contrato_locacao.dart';
import 'package:marceloimob_gestao/features/locacao/domain/entities/despesa.dart';
import 'package:marceloimob_gestao/features/locacao/domain/entities/locacao_enums.dart';
import 'package:marceloimob_gestao/features/locacao/domain/entities/modelo_contrato.dart';
import 'package:marceloimob_gestao/features/locacao/domain/repositories/cobranca_repository.dart';
import 'package:marceloimob_gestao/features/locacao/domain/repositories/despesa_repository.dart';
import 'package:marceloimob_gestao/features/locacao/domain/repositories/modelo_contrato_repository.dart';
import 'package:marceloimob_gestao/features/locacao/domain/services/tabela_ir.dart';
import 'package:marceloimob_gestao/features/locacao/domain/usecases/cobranca_usecases.dart';
import 'package:marceloimob_gestao/features/locacao/domain/usecases/contrato_usecases.dart';
import 'package:marceloimob_gestao/features/locacao/domain/usecases/imposto_renda.dart';
import 'package:marceloimob_gestao/features/locacao/domain/usecases/modelo_usecases.dart';
import 'package:marceloimob_gestao/features/locacao/domain/usecases/repasse_usecases.dart';

ContratoLocacao _contrato({
  String id = 'k1',
  String locatario = 'loc',
  double aluguel = 3000,
  List<Beneficiario> beneficiarios = const [
    Beneficiario(contatoId: 'prop', percentual: 100),
  ],
}) => ContratoLocacao(
  id: id,
  numero: '',
  imovelId: 'i1',
  locatarioId: locatario,
  beneficiarios: beneficiarios,
  dataInicio: DateTime(2026, 1, 5),
  valorAluguel: aluguel,
  taxaAdministracao: 10,
  taxaIntermediacao: 100,
);

Future<void> _semear() async {
  final contatos = sl<ContatoRepository>();
  await contatos.salvar(
    Contato(
      id: 'prop',
      nome: 'Carlos Proprietário',
      criadoEm: DateTime(2026),
      documento: '123.456.789-01',
    ),
  );
  await contatos.salvar(
    Contato(id: 'loc', nome: 'Ana Locatária', criadoEm: DateTime(2026)),
  );
  await contatos.salvar(
    Contato(
      id: 'pj',
      nome: 'Empresa X Ltda',
      criadoEm: DateTime(2026),
      tipoPessoa: TipoPessoa.juridica,
    ),
  );
  await sl<ImovelRepository>().salvar(
    Imovel(
      id: 'i1',
      codigo: 'IM-0001',
      titulo: 'Apto Icaraí',
      logradouro: 'Rua A',
      numero: '10',
      bairro: 'Icaraí',
      cidade: 'Niterói',
      uf: 'RJ',
      proprietarioId: 'prop',
    ),
  );
  final despesas = sl<DespesaRepository>();
  await despesas.salvar(
    Despesa(
      id: 'd1',
      contratoId: 'k1',
      descricao: 'Condomínio',
      valor: 800,
      competenciaInicio: DateTime(2026),
    ),
  );
  await despesas.salvar(
    Despesa(
      id: 'd2',
      contratoId: 'k1',
      descricao: 'IPTU',
      valor: 200,
      competenciaInicio: DateTime(2026),
      responsavel: ResponsavelDespesa.proprietario,
      dedutivelIR: true,
    ),
  );
  await despesas.salvar(
    Despesa(
      id: 'd3',
      contratoId: 'k1',
      descricao: 'Reparo',
      valor: 500,
      competenciaInicio: DateTime(2026, 2),
      natureza: NaturezaDespesa.extraordinaria,
      responsavel: ResponsavelDespesa.proprietario,
    ),
  );
}

void main() {
  setUp(() async {
    await configurarDependencias();
    await _semear();
  });

  group('SalvarContrato', () {
    test('exige 100% entre os beneficiários e numera o contrato', () async {
      final salvar = sl<SalvarContrato>();
      expect(
        () => salvar(
          _contrato(
            beneficiarios: const [
              Beneficiario(contatoId: 'prop', percentual: 60),
            ],
          ),
        ),
        throwsA(isA<DomainException>()),
      );
      expect((await salvar(_contrato())).numero, 'LOC-0001');
    });

    test('locatário não pode ser beneficiário', () {
      expect(
        () => sl<SalvarContrato>()(
          _contrato(
            beneficiarios: const [
              Beneficiario(contatoId: 'loc', percentual: 100),
            ],
          ),
        ),
        throwsA(isA<DomainException>()),
      );
    });
  });

  group('Cobranças', () {
    test(
      'gera aluguel + despesas do locatário e atualiza as abertas',
      () async {
        await sl<SalvarContrato>()(_contrato());
        final gerar = sl<GerarCobrancasDoMes>();
        expect(await gerar(DateTime(2026, 1)), (criadas: 1, atualizadas: 0));
        expect(await gerar(DateTime(2026, 1)), (criadas: 0, atualizadas: 1));
        expect(await gerar(DateTime(2025, 12)), (criadas: 0, atualizadas: 0));

        final c = (await sl<CobrancaRepository>().listar()).single;
        expect(c.total, 3800);
        expect(c.vencimento, DateTime(2026, 1, 10));
      },
    );

    test('multa e juros pro rata após o vencimento', () async {
      final k = await sl<SalvarContrato>()(_contrato());
      await sl<GerarCobrancasDoMes>()(DateTime(2026, 1));
      final c = (await sl<CobrancaRepository>().listar()).single;
      final e = const CalcularEncargos()(k, c, DateTime(2026, 1, 20));
      expect(e.diasAtraso, 10);
      expect(e.multa, 380);
      expect(e.juros, closeTo(12.67, 0.001));
      expect(const CalcularEncargos()(k, c, DateTime(2026, 1, 10)).multa, 0);
    });
  });

  group('Repasse e IR', () {
    test(
      'desconta taxa, intermediação no 1º mês e despesas do proprietário',
      () async {
        final k = await sl<SalvarContrato>()(_contrato());
        await sl<GerarCobrancasDoMes>()(DateTime(2026, 1));
        final aberta = (await sl<CobrancaRepository>().listar()).single;
        await sl<RegistrarPagamento>()(aberta, DateTime(2026, 1, 10));
        final paga = (await sl<CobrancaRepository>().listar()).single;
        expect(paga.status, StatusCobranca.paga);
        expect(paga.valorPago, 3800);

        final l = const CalcularRepasse()(
          cobranca: paga,
          contrato: k,
          despesas: await sl<DespesaRepository>().listar(),
          locatarioPessoaJuridica: false,
          beneficiarioPessoaJuridica: (_) => false,
        ).single;
        expect(l.aluguel, 3000);
        expect(l.taxaAdministracao, 300);
        expect(l.taxaIntermediacao, 3000);
        expect(l.despesasProprietario, 200);
        expect(l.baseIR, 2500); // 3000 − 300 adm − 200 IPTU dedutível
        expect(l.irrf, 0);
        expect(l.liquido, -500);
      },
    );

    test('IRRF quando o locatário é PJ, com redutor de 2026', () async {
      final k = await sl<SalvarContrato>()(
        _contrato(id: 'k2', locatario: 'pj', aluguel: 8000),
      );
      await sl<GerarCobrancasDoMes>()(DateTime(2026, 3));
      final c = (await sl<CobrancaRepository>().listar()).firstWhere(
        (c) => c.contratoId == k.id,
      );
      await sl<RegistrarPagamento>()(c, DateTime(2026, 3, 10));

      final meses = const CalcularResumoIrAnual()(
        beneficiarioId: 'prop',
        ano: 2026,
        cobrancas: await sl<CobrancaRepository>().listar(),
        contratos: [k],
        despesas: const [],
        pessoaJuridica: (id) => id == 'pj',
      );
      final marco = meses[2];
      expect(marco.rendimentoBruto, 8000);
      expect(marco.baseIrrf, 7200); // − 10% de administração
      // 7200 × 27,5% − 908,73 = 1071,27; redutor = 978,62 − 0,133145 × 7200
      expect(marco.irrfRetido, closeTo(1051.29, 0.01));
      expect(marco.impostoCarneLeao, 0);
    });

    test('tabela: isenção até R\$ 5 mil a partir de 2026', () {
      const t = TabelaIR();
      expect(t.impostoMensal(5000, ano: 2026), 0);
      expect(t.impostoMensal(5000, ano: 2025), closeTo(466.27, 0.01));
      expect(t.impostoMensal(2000, ano: 2025), 0);
    });
  });

  group('Modelos de contrato', () {
    test('preenche todos os campos do modelo padrão', () async {
      final k = await sl<SalvarContrato>()(_contrato());
      final modelo = (await sl<ModeloContratoRepository>().listar()).single;
      final contatos = await sl<ContatoRepository>().listar();
      final doc = const PreencherModeloContrato()(
        modelo: modelo,
        contrato: k,
        contato: (id) => contatos.where((c) => c.id == id).firstOrNull,
        imovel: await sl<ImovelRepository>().obter('i1'),
        data: DateTime(2026, 1, 5),
      );
      expect(doc.titulo, 'CONTRATO DE LOCAÇÃO RESIDENCIAL Nº LOC-0001');
      expect(doc.texto, contains('Ana Locatária'));
      expect(doc.texto, contains('3.000,00 (três mil reais)'));
      expect(doc.texto, contains('Niterói, 5 de janeiro de 2026.'));
      expect(doc.texto, isNot(contains('{{')));
      expect(doc.assinaturas, contains('LOCADOR: Carlos Proprietário'));
    });

    test('rejeita campos desconhecidos e mantém ao menos um modelo', () async {
      expect(
        () => sl<SalvarModelo>()(
          const ModeloContrato(id: 'x', nome: 'X', texto: '{{inexistente}}'),
        ),
        throwsA(isA<DomainException>()),
      );
      final unico = (await sl<ModeloContratoRepository>().listar()).single;
      expect(
        () => sl<RemoverModelo>()(unico.id),
        throwsA(isA<DomainException>()),
      );
    });
  });
}
