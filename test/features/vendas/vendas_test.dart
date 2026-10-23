import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_imobiliaria/core/di/injector.dart';
import 'package:gestao_imobiliaria/core/errors/domain_exception.dart';
import 'package:gestao_imobiliaria/features/contratos/domain/entities/modelo_contrato.dart';
import 'package:gestao_imobiliaria/features/contratos/domain/repositories/modelo_contrato_repository.dart';
import 'package:gestao_imobiliaria/features/contratos/domain/usecases/modelo_usecases.dart';
import 'package:gestao_imobiliaria/features/crm/domain/entities/contato.dart';
import 'package:gestao_imobiliaria/features/crm/domain/entities/imovel.dart';
import 'package:gestao_imobiliaria/features/crm/domain/repositories/contato_repository.dart';
import 'package:gestao_imobiliaria/features/crm/domain/repositories/imovel_repository.dart';
import 'package:gestao_imobiliaria/features/vendas/data/documentos/pdf_documentos_venda_gateway.dart';
import 'package:gestao_imobiliaria/features/vendas/domain/entities/documentos_venda.dart';
import 'package:gestao_imobiliaria/features/vendas/domain/entities/venda.dart';
import 'package:gestao_imobiliaria/features/vendas/domain/entities/venda_enums.dart';
import 'package:gestao_imobiliaria/features/vendas/domain/repositories/parcela_repository.dart';
import 'package:gestao_imobiliaria/features/vendas/domain/repositories/venda_repository.dart';
import 'package:gestao_imobiliaria/features/vendas/domain/services/calculadora_financiamento.dart';
import 'package:gestao_imobiliaria/features/vendas/domain/usecases/montar_contrato_venda.dart';
import 'package:gestao_imobiliaria/features/vendas/domain/usecases/parcela_usecases.dart';
import 'package:gestao_imobiliaria/features/vendas/domain/usecases/venda_usecases.dart';

const _calc = CalculadoraFinanciamento();

PlanoFinanciamento _plano(
  SistemaAmortizacao s, {
  int n = 12,
  double taxa = 1,
}) => PlanoFinanciamento(
  numeroParcelas: n,
  taxaJurosMes: taxa,
  sistema: s,
  primeiroVencimento: DateTime(2027, 1, 10),
);

Venda _venda({
  double valor = 300000,
  double entrada = 60000,
  List<String> compradores = const ['comp'],
  List<Participacao> corretores = const [
    Participacao(percentual: 70),
    Participacao(contatoId: 'corretor', percentual: 30),
  ],
  PlanoFinanciamento? plano,
}) => Venda(
  id: 'v1',
  numero: '',
  imovelId: 'i1',
  compradores: compradores,
  vendedores: const [Participacao(contatoId: 'vend', percentual: 100)],
  dataVenda: DateTime(2026, 12, 10),
  valorVenda: valor,
  valorEntrada: entrada,
  formaPagamento: FormaPagamento.financiamentoProprio,
  plano: plano ?? _plano(SistemaAmortizacao.price),
  corretores: corretores,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CalculadoraFinanciamento', () {
    test('Price: parcelas fixas e saldo zerado', () {
      final t = _calc.calcular(100000, _plano(SistemaAmortizacao.price));
      expect(t, hasLength(12));
      expect(t.first.valor, 8884.88);
      expect(t.first.juros, 1000);
      expect(t.last.saldoDevedor, 0);
      final amortizado = t.fold<double>(0, (s, p) => s + p.amortizacao);
      expect(amortizado, closeTo(100000, 0.001));
      expect(t.last.valor, closeTo(8884.88, 0.05));
    });

    test('SAC: amortização constante e parcelas decrescentes', () {
      final t = _calc.calcular(12000, _plano(SistemaAmortizacao.sac));
      expect(t.first.amortizacao, 1000);
      expect(t.first.valor, 1120);
      expect(t.last.valor, 1010);
      expect(t.last.saldoDevedor, 0);
    });

    test('sem juros: parcelas iguais', () {
      final t = _calc.calcular(
        12000,
        _plano(SistemaAmortizacao.semJuros, taxa: 5),
      );
      expect(t.every((p) => p.valor == 1000 && p.juros == 0), isTrue);
    });

    test('vencimento ajusta para o fim de meses curtos', () {
      final jan31 = DateTime(2027, 1, 31);
      expect(_calc.vencimento(jan31, 1), DateTime(2027, 2, 28));
      expect(_calc.vencimento(jan31, 2), DateTime(2027, 3, 31));
    });
  });

  group('Vendas', () {
    setUp(() async {
      await configurarDependencias();
      final c = sl<ContatoRepository>();
      await c.salvar(
        Contato(
          id: 'comp',
          nome: 'João Comprador',
          criadoEm: DateTime(2026),
          documento: '111.222.333-44',
        ),
      );
      await c.salvar(
        Contato(id: 'vend', nome: 'Maria Vendedora', criadoEm: DateTime(2026)),
      );
      await c.salvar(
        Contato(
          id: 'corretor',
          nome: 'Pedro Corretor',
          criadoEm: DateTime(2026),
        ),
      );
      await sl<ImovelRepository>().salvar(
        Imovel(
          id: 'i1',
          codigo: 'IM-0001',
          titulo: 'Casa',
          cidade: 'Niterói',
          matricula: '12.345',
        ),
      );
    });

    test('gera entrada + parcelas e numera a venda', () async {
      final v = await sl<SalvarVenda>()(_venda());
      expect(v.numero, 'VEN-0001');
      final ps = await sl<ParcelaRepository>().daVenda('v1');
      expect(ps, hasLength(13));
      expect(
        ps.where((p) => p.tipo == TipoParcela.entrada).single.valor,
        60000,
      );
      expect(ResumoFinanciamento(ps).saldoDevedor, 300000);
    });

    test('validações de negócio', () {
      final salvar = sl<SalvarVenda>();
      expect(
        () => salvar(_venda(compradores: const ['vend'])),
        throwsA(isA<DomainException>()),
      );
      expect(
        () => salvar(_venda(entrada: 400000)),
        throwsA(isA<DomainException>()),
      );
      expect(
        () => salvar(_venda(corretores: const [Participacao(percentual: 50)])),
        throwsA(isA<DomainException>()),
      );
    });

    test(
      'pagamento com atraso, quitação, estorno e bloqueio do plano',
      () async {
        final salvar = sl<SalvarVenda>();
        final venda = await salvar(
          _venda(
            valor: 30000,
            entrada: 0,
            plano: _plano(SistemaAmortizacao.semJuros, n: 2),
          ),
        );
        var ps = await sl<ParcelaRepository>().daVenda('v1');
        final pagar = sl<RegistrarPagamentoParcela>();

        // 10 dias de atraso: multa 2% e juros 1% a.m. pro rata.
        await pagar(ps[0], DateTime(2027, 1, 20));
        ps = await sl<ParcelaRepository>().daVenda('v1');
        final paga = ps.firstWhere((p) => p.numero == 1);
        expect(paga.multa, 300);
        expect(paga.jurosMora, 50);
        expect(paga.valorPago, 15350);

        expect(
          () => salvar(
            _venda(
              valor: 30000,
              entrada: 0,
              plano: _plano(SistemaAmortizacao.price, n: 2),
            ).copyWith(numero: venda.numero),
          ),
          throwsA(isA<DomainException>()),
        );

        await pagar(ps.firstWhere((p) => p.numero == 2), DateTime(2027, 2, 10));
        expect(
          (await sl<VendaRepository>().obter('v1'))!.status,
          StatusVenda.quitada,
        );

        await sl<EstornarPagamentoParcela>()(paga);
        expect(
          (await sl<VendaRepository>().obter('v1'))!.status,
          StatusVenda.ativa,
        );
      },
    );

    test('contrato de compra e venda preenche todos os campos', () async {
      final v = await sl<SalvarVenda>()(_venda());
      final modelo = (await sl<ModeloContratoRepository>().listar()).firstWhere(
        (m) => m.tipo == TipoModelo.venda,
      );
      final contatos = await sl<ContatoRepository>().listar();
      final doc = const MontarContratoVenda()(
        modelo: modelo,
        venda: v,
        contato: (id) => contatos.where((c) => c.id == id).firstOrNull,
        imovel: await sl<ImovelRepository>().obter('i1'),
        data: DateTime(2026, 12, 10),
      );
      expect(doc.texto, isNot(contains('{{')));
      expect(doc.texto, contains('trezentos mil reais'));
      expect(doc.texto, contains('12 parcelas mensais'));
      expect(doc.texto, contains('matrícula nº 12.345'));
      expect(doc.assinaturas, contains('COMPRADOR: João Comprador'));
    });

    test('modelo de venda não aceita campos de locação', () {
      expect(
        () => sl<SalvarModelo>()(
          const ModeloContrato(
            id: 'x',
            nome: 'X',
            tipo: TipoModelo.venda,
            texto: '{{valor_aluguel}}',
          ),
        ),
        throwsA(isA<DomainException>()),
      );
    });

    test('comissão: marcar como paga', () async {
      final v = await sl<SalvarVenda>()(_venda());
      await sl<MarcarComissaoPaga>()(v, 1, DateTime(2026, 12, 15));
      final atual = (await sl<VendaRepository>().obter('v1'))!;
      expect(atual.corretores[1].pagaEm, DateTime(2026, 12, 15));
      expect(atual.valorComissao, 18000);
    });
  });

  test('gera carnê, promissórias e recibo de comissão em PDF', () async {
    final g = PdfDocumentosVendaGateway();
    final venda = _venda().copyWith(numero: 'VEN-0001');
    final parcelas = gerarParcelas(venda);
    final comprador = Contato(
      id: 'c',
      nome: 'José Ação',
      criadoEm: DateTime(2026),
    );
    final doc = ParcelasDocumento(
      venda: venda,
      compradores: [comprador],
      credor: const Credor(nome: 'Maria Vendedora', documento: '123'),
      imovel: Imovel(
        id: 'i',
        codigo: 'IM-1',
        titulo: 'Casa',
        cidade: 'Niterói',
      ),
      parcelas: parcelas,
    );
    void ehPdf(List<int> b) =>
        expect(ascii.decode(b.take(5).toList()), '%PDF-');
    ehPdf(await g.gerarCarne(doc));
    ehPdf(await g.gerarPromissorias(doc));
    ehPdf(
      await g.gerarReciboComissao(
        ReciboComissaoDocumento(
          venda: venda,
          imovel: doc.imovel,
          recebedor: const Credor(nome: 'Pedro Corretor', documento: ''),
          pagadores: [comprador],
          percentualParticipacao: 30,
          valor: 5400,
          data: DateTime(2026, 12, 15),
        ),
      ),
    );
  });
}
