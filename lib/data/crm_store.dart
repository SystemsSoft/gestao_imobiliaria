import 'package:flutter/foundation.dart';

import '../models/contato.dart';
import '../models/evento.dart';
import '../models/imovel.dart';

/// Repositório em memória de imóveis, contatos e eventos da agenda.
/// Os dados são perdidos ao recarregar o app até existir um backend.
class CrmStore extends ChangeNotifier {
  CrmStore();

  static final CrmStore instance = CrmStore();

  final List<Imovel> _imoveis = [];
  final List<Contato> _contatos = [];
  final List<Evento> _eventos = [];
  int _seqCodigo = 0;

  @visibleForTesting
  void limpar() {
    _imoveis.clear();
    _contatos.clear();
    _eventos.clear();
    _seqCodigo = 0;
    notifyListeners();
  }

  List<Imovel> get imoveis => List.unmodifiable(_imoveis);
  List<Contato> get contatos => List.unmodifiable(_contatos);
  List<Evento> get eventos => List.unmodifiable(_eventos);

  String novoId() => DateTime.now().microsecondsSinceEpoch.toString();

  /// Código sequencial exibido do imóvel (ex.: IM-0001).
  String proximoCodigo() {
    _seqCodigo++;
    return 'IM-${_seqCodigo.toString().padLeft(4, '0')}';
  }

  Imovel? imovelPorId(String? id) =>
      id == null ? null : _imoveis.where((e) => e.id == id).firstOrNull;

  Contato? contatoPorId(String? id) =>
      id == null ? null : _contatos.where((e) => e.id == id).firstOrNull;

  void salvarImovel(Imovel imovel) {
    _upsert(_imoveis, imovel, (e) => e.id);
    notifyListeners();
  }

  void removerImovel(String id) {
    _imoveis.removeWhere((e) => e.id == id);
    for (var i = 0; i < _eventos.length; i++) {
      final e = _eventos[i];
      if (e.imovelId == id) {
        _eventos[i] = Evento(
          id: e.id,
          titulo: e.titulo,
          criadoEm: e.criadoEm,
          tipo: e.tipo,
          descricao: e.descricao,
          dataHora: e.dataHora,
          prioridade: e.prioridade,
          contatoId: e.contatoId,
          concluido: e.concluido,
        );
      }
    }
    notifyListeners();
  }

  void salvarContato(Contato contato) {
    _upsert(_contatos, contato, (e) => e.id);
    notifyListeners();
  }

  void removerContato(String id) {
    _contatos.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  void salvarEvento(Evento evento) {
    _upsert(_eventos, evento, (e) => e.id);
    notifyListeners();
  }

  void removerEvento(String id) {
    _eventos.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  void alternarConcluido(Evento evento) =>
      salvarEvento(evento.copyWith(concluido: !evento.concluido));

  void _upsert<T>(List<T> list, T item, String Function(T) idOf) {
    final i = list.indexWhere((e) => idOf(e) == idOf(item));
    if (i >= 0) {
      list[i] = item;
    } else {
      list.add(item);
    }
  }
}
