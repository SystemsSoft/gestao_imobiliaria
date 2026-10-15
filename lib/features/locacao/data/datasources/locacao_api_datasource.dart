import '../../../../core/api/api_client.dart';
import '../../../../core/api/status_conexao.dart';
import '../../../../core/data/remote_collection.dart';
import '../../domain/entities/cobranca.dart';
import '../../domain/entities/contrato_locacao.dart';
import '../../domain/entities/despesa.dart';
import '../../domain/repositories/repasse_repository.dart';
import '../models/locacao_json.dart';

/// Locação no servidor (`/api/v1/locacao`), com cache local para as telas.
class LocacaoApiDataSource {
  LocacaoApiDataSource(this.api, StatusConexao status)
    : contratos = RemoteCollection(
        idOf: (e) => e.id,
        status: status,
        carregar: () async => [
          for (final j in await api.listarTudo('locacao/contratos'))
            contratoDeJson(j),
        ],
      ),
      despesas = RemoteCollection(
        idOf: (e) => e.id,
        status: status,
        carregar: () async => [
          for (final j in await api.listarTudo('locacao/despesas'))
            despesaDeJson(j),
        ],
      ),
      cobrancas = RemoteCollection(
        idOf: (e) => e.id,
        status: status,
        carregar: () async => [
          for (final j in await api.listarTudo('locacao/cobrancas'))
            cobrancaDeJson(j),
        ],
      ),
      repasses = RemoteCollection(
        idOf: (e) => chaveRepasse(e.cobrancaId, e.contatoId),
        status: status,
        carregar: () async => [
          for (final j in (await api.get('locacao/repasses') as List))
            RepasseRealizado.deJson(j as Map<String, dynamic>),
        ],
      );

  final ApiClient api;
  final RemoteCollection<ContratoLocacao> contratos;
  final RemoteCollection<Despesa> despesas;
  final RemoteCollection<Cobranca> cobrancas;
  final RemoteCollection<RepasseRealizado> repasses;
}
