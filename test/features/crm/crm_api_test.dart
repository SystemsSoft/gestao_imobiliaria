import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:marceloimob_gestao/core/api/api_client.dart';
import 'package:marceloimob_gestao/core/api/status_conexao.dart';
import 'package:marceloimob_gestao/core/utils/id.dart';
import 'package:marceloimob_gestao/features/crm/data/datasources/crm_api_datasource.dart';
import 'package:marceloimob_gestao/features/crm/data/models/crm_json.dart';
import 'package:marceloimob_gestao/features/crm/data/repositories/crm_api_repositories.dart';
import 'package:marceloimob_gestao/features/crm/domain/entities/contato.dart';
import 'package:marceloimob_gestao/features/crm/domain/entities/enums.dart';
import 'package:marceloimob_gestao/features/crm/domain/entities/evento.dart';
import 'package:marceloimob_gestao/features/crm/domain/entities/imovel.dart';
import 'package:http/testing.dart';

import '../../apoio/servidor_falso.dart';

void main() {
  late ServidorFalso servidor;
  late CrmApiDataSource ds;
  late StatusConexao status;

  setUp(() {
    servidor = ServidorFalso()
      ..recusar = (_, corpo) =>
          corpo['titulo'] == 'erro' ? 'Informe o título do imóvel.' : null;
    status = StatusConexao();
    ds = CrmApiDataSource(servidor.cliente(), status);
  });

  test('ids são UUID v4', () {
    expect(
      gerarId(),
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-'
          r'[0-9a-f]{12}$',
        ),
      ),
    );
  });

  test('imóvel: grava com PUT, recebe o código e atualiza o cache', () async {
    final repo = ImovelApiRepository(ds);
    final id = gerarId();
    final salvo = await repo.salvar(
      Imovel(
        id: id,
        codigo: '',
        titulo: 'Apto Barra',
        finalidades: {Finalidade.venda, Finalidade.locacao},
        tipo: TipoImovel.casaCondominio,
        valorVenda: 1250000.5,
        comodidades: {'Piscina'},
        personalizadas: const [
          CaracteristicaPersonalizada(nome: 'Pé-direito', valor: '4 m'),
        ],
        anexos: const [
          Anexo(tipo: AnexoTipo.foto, titulo: 'Sala', url: 'https://x/1.jpg'),
        ],
        dataCaptacao: DateTime(2026, 9, 1),
      ),
    );
    expect(servidor.requisicoes.last, 'PUT /api/v1/crm/imoveis/$id');
    expect(salvo.codigo, 'IM-0001');
    expect(salvo.criadoEm, DateTime(2026, 10, 15, 10));
    expect(salvo.tipo, TipoImovel.casaCondominio);
    expect(salvo.finalidades, {Finalidade.venda, Finalidade.locacao});
    expect(salvo.personalizadas.single.valor, '4 m');
    expect(salvo.dataCaptacao, DateTime(2026, 9, 1));
    expect(servidor.colecao('crm/imoveis')[id]!['dataCaptacao'], '2026-09-01');
    expect((await repo.listar()).single.valorVenda, 1250000.5);

    await repo.remover(id);
    expect(await repo.listar(), isEmpty);
  });

  test('contato com perfil e evento ida e volta', () async {
    final contato = Contato(
      id: gerarId(),
      nome: 'Ana Souza',
      criadoEm: DateTime(2026),
      papeis: {PapelContato.comprador},
      dataNascimento: DateTime(1990, 5, 10),
      perfil: const PerfilInteresse(
        finalidade: Finalidade.locacao,
        tipos: {TipoImovel.apartamento},
        valorMax: 5000,
        quartosMin: 2,
      ),
    );
    await ContatoApiRepository(ds).salvar(contato);
    final lido = contatoDeJson(servidor.colecao('crm/contatos')[contato.id]!);
    expect(lido.perfil!.finalidade, Finalidade.locacao);
    expect(lido.perfil!.tipos, {TipoImovel.apartamento});
    expect(lido.dataNascimento, DateTime(1990, 5, 10));

    final evento = Evento(
      id: gerarId(),
      titulo: 'Visita',
      criadoEm: DateTime(2026),
      tipo: TipoEvento.visita,
      dataHora: DateTime(2026, 10, 20, 9, 30),
      contatoId: contato.id,
    );
    await EventoApiRepository(ds).salvar(evento);
    expect(
      servidor.colecao('crm/eventos')[evento.id]!['dataHora'],
      '2026-10-20T09:30:00',
    );
    expect(
      (await EventoApiRepository(ds).listar()).single.dataHora,
      DateTime(2026, 10, 20, 9, 30),
    );
  });

  test('erros do servidor chegam com a mensagem dele', () async {
    expect(
      () => ImovelApiRepository(
        ds,
      ).salvar(Imovel(id: gerarId(), codigo: '', titulo: 'erro')),
      throwsA(
        isA<ApiException>().having(
          (e) => e.mensagem,
          'mensagem',
          'Informe o título do imóvel.',
        ),
      ),
    );
  });

  test('sem conexão: avisa e permite tentar de novo', () async {
    var falhar = true;
    final ds = CrmApiDataSource(
      ApiClient(
        'http://servidor',
        cliente: MockClient((r) async {
          if (falhar) throw http.ClientException('offline');
          return servidor.responder(r);
        }),
      ),
      status,
    );
    expect(await ImovelApiRepository(ds).listar(), isEmpty);
    expect(status.erro, contains('Não foi possível conectar'));

    falhar = false;
    await status.tentarNovamente();
    expect(status.erro, isNull);
  });
}
