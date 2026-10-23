import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_imobiliaria/core/api/status_conexao.dart';
import 'package:gestao_imobiliaria/core/utils/id.dart';
import 'package:gestao_imobiliaria/features/contratos/data/repositories/modelo_contrato_api_repository.dart';
import 'package:gestao_imobiliaria/features/contratos/domain/entities/modelo_contrato.dart';
import 'package:gestao_imobiliaria/features/contratos/domain/entities/parametro_modelo.dart';
import 'package:gestao_imobiliaria/features/contratos/domain/usecases/modelo_usecases.dart';

import '../../apoio/servidor_falso.dart';

void main() {
  late ServidorFalso servidor;
  late ModeloContratoApiRepository repo;

  setUp(() {
    servidor = ServidorFalso();
    repo = ModeloContratoApiRepository(servidor.cliente(), StatusConexao());
  });

  test('servidor vazio recebe os modelos padrão uma única vez', () async {
    final modelos = await repo.listar();
    expect(modelos.map((m) => m.tipo).toSet(), {
      TipoModelo.locacao,
      TipoModelo.venda,
    });
    expect(servidor.colecao('contratos/modelos'), hasLength(2));
    expect(modelos.first.nome, endsWith('(padrão)'));
    expect(modelos.first.baseId, isNotNull);

    // Outro app abrindo depois não duplica.
    final outro = ModeloContratoApiRepository(
      servidor.cliente(),
      StatusConexao(),
    );
    await outro.listar();
    expect(servidor.colecao('contratos/modelos'), hasLength(2));
  });

  test('salvar modelo próprio com parâmetros', () async {
    await repo.listar();
    await SalvarModelo(repo)(
      ModeloContrato(
        id: '',
        nome: 'Autorização de venda com exclusividade',
        tipo: TipoModelo.autorizacao,
        texto: 'Autorizo a venda pelo prazo de {{periodo_exclusivo}} dias.',
        parametros: const [
          ParametroModelo(
            chave: 'periodo_exclusivo',
            rotulo: 'Prazo (dias)',
            tipo: TipoParametro.numero,
            valorPadrao: '90',
          ),
        ],
      ),
    );
    final salvo = (await repo.listar()).firstWhere(
      (m) => m.tipo == TipoModelo.autorizacao,
    );
    expect(salvo.parametros.single.tipo, TipoParametro.numero);
    expect(salvo.parametros.single.valorPadrao, '90');
    expect(servidor.colecao('contratos/modelos'), hasLength(3));

    await repo.remover(salvo.id);
    expect(servidor.colecao('contratos/modelos'), hasLength(2));
    expect(gerarId(), isNot(salvo.id));
  });
}
