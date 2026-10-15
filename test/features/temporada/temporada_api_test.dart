import 'package:flutter_test/flutter_test.dart';
import 'package:marceloimob_gestao/core/api/api_client.dart';
import 'package:marceloimob_gestao/core/api/status_conexao.dart';
import 'package:marceloimob_gestao/core/utils/id.dart';
import 'package:marceloimob_gestao/features/temporada/data/repositories/reserva_api_repository.dart';
import 'package:marceloimob_gestao/features/temporada/domain/entities/reserva.dart';
import 'package:marceloimob_gestao/features/temporada/domain/entities/reserva_enums.dart';
import 'package:marceloimob_gestao/features/temporada/domain/usecases/reserva_usecases.dart';

import '../../apoio/servidor_falso.dart';

Reserva _reserva({String? id, bool bloqueio = false}) => Reserva(
  id: id ?? gerarId(),
  imovelId: 'imovel',
  hospedeId: bloqueio ? null : 'hospede',
  bloqueio: bloqueio,
  motivoBloqueio: bloqueio ? 'Manutenção' : '',
  checkIn: DateTime(2026, 12, 20),
  checkOut: DateTime(2026, 12, 27),
  hospedes: 3,
  valorDiaria: 450,
  taxaLimpeza: 150,
  valorPago: 1000,
  origem: OrigemReserva.airbnb,
);

void main() {
  late ServidorFalso servidor;
  late ReservaApiRepository repo;

  setUp(() {
    servidor = ServidorFalso();
    repo = ReservaApiRepository(servidor.cliente(), StatusConexao());
  });

  test('reserva recebe o número do servidor e mantém os dados', () async {
    final salva = await SalvarReserva(repo, ConsultarDisponibilidade(repo))(
      _reserva(),
    );
    expect(salva.numero, 'RES-0001');
    expect((salva.noites, salva.total, salva.saldo), (7, 3300.0, 2300.0));
    expect(salva.origem, OrigemReserva.airbnb);
    expect(
      servidor.colecao('temporada/reservas')[salva.id]!['checkOut'],
      '2026-12-27',
    );
    expect((await repo.listar()).single.checkIn, DateTime(2026, 12, 20));
  });

  test('quitar e cancelar gravam no servidor', () async {
    final salva = await SalvarReserva(repo, ConsultarDisponibilidade(repo))(
      _reserva(),
    );
    await QuitarReserva(repo)(salva);
    expect(
      servidor.colecao('temporada/reservas')[salva.id]!['valorPago'],
      3300,
    );
    final quitada = (await repo.obter(salva.id))!;
    await AlterarSituacaoReserva(
      repo,
      SalvarReserva(repo, ConsultarDisponibilidade(repo)),
    )(quitada, SituacaoReserva.cancelada);
    expect(
      servidor.colecao('temporada/reservas')[salva.id]!['situacao'],
      'cancelada',
    );
  });

  test('conflito recusado pelo servidor chega com a mensagem dele', () async {
    await repo.listar(); // agenda carregada (vazia)
    // Outro usuário reserva o período direto no servidor.
    servidor.colecao('temporada/reservas')['outra'] = {
      'id': 'outra',
      'numero': 'RES-0009',
      'imovelId': 'imovel',
      'checkIn': '2026-12-20',
      'checkOut': '2026-12-27',
    };
    servidor.recusar = (_, _) =>
        'Período indisponível: conflita com a reserva RES-0009 '
        '(20/12/2026 a 27/12/2026).';
    await expectLater(
      SalvarReserva(repo, ConsultarDisponibilidade(repo))(_reserva()),
      throwsA(
        isA<ApiException>().having(
          (e) => e.mensagem,
          'mensagem',
          contains('RES-0009'),
        ),
      ),
    );
    // A agenda foi recarregada e já mostra a reserva do outro usuário.
    expect((await repo.listar()).single.numero, 'RES-0009');
  });

  test('bloqueio e exclusão', () async {
    final b = await repo.salvar(_reserva(bloqueio: true));
    expect(b.bloqueio, isTrue);
    expect(b.total, 0);
    await repo.remover(b.id);
    expect(await repo.listar(), isEmpty);
    expect(servidor.colecao('temporada/reservas'), isEmpty);
  });
}
