import '../../domain/entities/contato.dart';
import '../../domain/entities/evento.dart';
import '../../domain/entities/imovel.dart';
import '../../domain/repositories/contato_repository.dart';
import '../../domain/repositories/evento_repository.dart';
import '../../domain/repositories/imovel_repository.dart';
import '../datasources/crm_api_datasource.dart';
import '../models/crm_json.dart';

// Gravações usam PUT /{id}: o servidor cria quando o id ainda não existe,
// então repetir a mesma gravação nunca duplica o registro.

class ImovelApiRepository implements ImovelRepository {
  const ImovelApiRepository(this._ds);
  final CrmApiDataSource _ds;

  @override
  Stream<List<Imovel>> observar() => _ds.imoveis.watch();

  @override
  Future<List<Imovel>> listar() => _ds.imoveis.all();

  @override
  Future<Imovel?> obter(String id) => _ds.imoveis.byId(id);

  @override
  Future<Imovel> salvar(Imovel imovel) async {
    final json = await _ds.api.put(
      'crm/imoveis/${imovel.id}',
      imovelParaJson(imovel),
    );
    final salvo = imovelDeJson(json as Map<String, dynamic>);
    _ds.imoveis.cache.upsert(salvo);
    return salvo;
  }

  @override
  Future<void> remover(String id) async {
    await _ds.api.delete('crm/imoveis/$id');
    _ds.imoveis.cache.removeWhere((e) => e.id == id);
  }
}

class ContatoApiRepository implements ContatoRepository {
  const ContatoApiRepository(this._ds);
  final CrmApiDataSource _ds;

  @override
  Stream<List<Contato>> observar() => _ds.contatos.watch();

  @override
  Future<List<Contato>> listar() => _ds.contatos.all();

  @override
  Future<Contato?> obter(String id) => _ds.contatos.byId(id);

  @override
  Future<void> salvar(Contato contato) async {
    final json = await _ds.api.put(
      'crm/contatos/${contato.id}',
      contatoParaJson(contato),
    );
    _ds.contatos.cache.upsert(contatoDeJson(json as Map<String, dynamic>));
  }

  /// O servidor também tira o contato dos imóveis de que era proprietário.
  @override
  Future<void> remover(String id) async {
    await _ds.api.delete('crm/contatos/$id');
    _ds.contatos.cache.removeWhere((e) => e.id == id);
    for (final i in _ds.imoveis.cache.all.where(
      (i) => i.proprietarioId == id,
    )) {
      _ds.imoveis.cache.upsert(i.semProprietario());
    }
  }
}

class EventoApiRepository implements EventoRepository {
  const EventoApiRepository(this._ds);
  final CrmApiDataSource _ds;

  @override
  Stream<List<Evento>> observar() => _ds.eventos.watch();

  @override
  Future<List<Evento>> listar() => _ds.eventos.all();

  @override
  Future<void> salvar(Evento evento) async {
    final json = await _ds.api.put(
      'crm/eventos/${evento.id}',
      eventoParaJson(evento),
    );
    _ds.eventos.cache.upsert(eventoDeJson(json as Map<String, dynamic>));
  }

  @override
  Future<void> remover(String id) async {
    await _ds.api.delete('crm/eventos/$id');
    _ds.eventos.cache.removeWhere((e) => e.id == id);
  }
}
