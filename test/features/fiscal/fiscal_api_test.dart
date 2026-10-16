import 'package:flutter_test/flutter_test.dart';
import 'package:marceloimob_gestao/core/api/status_conexao.dart';
import 'package:marceloimob_gestao/features/fiscal/data/repositories/declarante_api_repository.dart';
import 'package:marceloimob_gestao/features/fiscal/domain/entities/declarante_dimob.dart';
import 'package:marceloimob_gestao/features/fiscal/domain/usecases/fiscal_usecases.dart';

import '../../apoio/servidor_falso.dart';

void main() {
  test('declarante padrão, gravação e leitura', () async {
    final servidor = ServidorFalso();
    final repo = DeclaranteApiRepository(servidor.cliente(), StatusConexao());
    expect((await repo.obter()).nome, 'Marcelo Bonifácio');

    await SalvarDeclarante(repo)(
      DeclaranteDimob(
        documento: '11.222.333/0001-81',
        nome: 'Marcelo Bonifácio Imóveis',
        responsavelCpf: '529.982.247-25',
        retificadora: true,
        numeroRecibo: '1234567890',
      ),
    );
    expect(servidor.colecao('fiscal')['declarante']!['retificadora'], isTrue);
    final lido = await repo.obter();
    expect(
      (lido.documento, lido.numeroRecibo),
      ('11.222.333/0001-81', '1234567890'),
    );
  });
}
