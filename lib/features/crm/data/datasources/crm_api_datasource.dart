import '../../../../core/api/api_client.dart';
import '../../../../core/api/status_conexao.dart';
import '../../../../core/data/remote_collection.dart';
import '../../domain/entities/contato.dart';
import '../../domain/entities/evento.dart';
import '../../domain/entities/imovel.dart';
import '../models/crm_json.dart';

/// CRM no servidor (`/api/v1/crm`), com cache local para as telas.
class CrmApiDataSource {
  CrmApiDataSource(this.api, StatusConexao status)
    : imoveis = RemoteCollection(
        idOf: (e) => e.id,
        status: status,
        carregar: () async => [
          for (final j in await api.listarTudo('crm/imoveis')) imovelDeJson(j),
        ],
      ),
      contatos = RemoteCollection(
        idOf: (e) => e.id,
        status: status,
        carregar: () async => [
          for (final j in await api.listarTudo('crm/contatos'))
            contatoDeJson(j),
        ],
      ),
      eventos = RemoteCollection(
        idOf: (e) => e.id,
        status: status,
        carregar: () async => [
          for (final j in await api.listarTudo('crm/eventos')) eventoDeJson(j),
        ],
      );

  final ApiClient api;
  final RemoteCollection<Imovel> imoveis;
  final RemoteCollection<Contato> contatos;
  final RemoteCollection<Evento> eventos;
}
