import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:marceloimob_gestao/core/config/empresa_info.dart';
import 'package:marceloimob_gestao/core/di/injector.dart';
import 'package:marceloimob_gestao/core/errors/domain_exception.dart';
import 'package:marceloimob_gestao/core/pdf/pdf_kit.dart';
import 'package:marceloimob_gestao/features/contratos/domain/entities/campos_modelo.dart';
import 'package:marceloimob_gestao/features/personalizacao/domain/usecases/personalizacao_usecases.dart';
import 'package:pdf/widgets.dart' as pw;

/// PNG 1x1 válido.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(configurarDependencias);
  tearDown(() => EmpresaInfo.aplicar(DadosEmpresa.padrao));

  const dados = DadosEmpresa(
    nome: 'Marcelo Bonifácio Imóveis',
    atividade: 'Corretor de Imóveis',
    creci: 'CRECI 065655 RJ',
    documento: '11.222.333/0001-81',
    endereco: 'Rua Moreira César, 100, Icaraí, Niterói/RJ',
    telefone: '(21) 99999-0000',
    chavePix: '11222333000181',
  );

  test('dados salvos passam a valer nos documentos e contratos', () async {
    await sl<SalvarDadosEmpresa>()(dados);
    expect(EmpresaInfo.nome, 'Marcelo Bonifácio Imóveis');
    expect(EmpresaInfo.chavePix, '11222333000181');
    expect(valoresEmpresa()['empresa_documento'], '11.222.333/0001-81');
    expect(EmpresaInfo.atual.contatos, contains('CNPJ/CPF 11.222.333/0001-81'));

    // Ao entrar de novo, a Personalização é recarregada.
    EmpresaInfo.aplicar(DadosEmpresa.padrao);
    await sl<CarregarPersonalizacao>()();
    expect(
      EmpresaInfo.atual.endereco,
      'Rua Moreira César, 100, Icaraí, Niterói/RJ',
    );
  });

  test('logotipo: PNG/JPG até 2 MB, e volta ao padrão', () async {
    await expectLater(
      sl<SalvarLogo>()(utf8.encode('GIF89a...')),
      throwsA(isA<DomainException>()),
    );
    await sl<SalvarLogo>()(_png);
    expect(EmpresaInfo.logo, _png);
    await sl<RemoverLogo>()();
    expect(EmpresaInfo.logo, isNull);
  });

  test('PDF usa o logotipo e os dados personalizados', () async {
    await sl<SalvarDadosEmpresa>()(dados);
    await sl<SalvarLogo>()(_png);
    final logo = await PdfKit.logo();
    expect(logo.bytes, _png);
    final doc = pw.Document(theme: await PdfKit.tema())
      ..addPage(pw.Page(build: (_) => PdfKit.cabecalho(logo, 'RECIBO')));
    final bytes = await doc.save();
    expect(latin1.decode(bytes.sublist(0, 4)), '%PDF');
  });

  test('nome vazio é recusado', () {
    expect(
      () => sl<SalvarDadosEmpresa>()(const DadosEmpresa(nome: ' ')),
      throwsA(isA<DomainException>()),
    );
  });
}
