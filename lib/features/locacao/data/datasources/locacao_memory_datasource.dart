import 'dart:async';

import '../../../../core/data/memory_collection.dart';
import '../../domain/entities/cobranca.dart';
import '../../domain/entities/contrato_locacao.dart';
import '../../domain/entities/despesa.dart';

/// Armazenamento em memória da locação, até existir um backend.
class LocacaoMemoryDataSource {
  final contratos = MemoryCollection<ContratoLocacao>((e) => e.id);
  final despesas = MemoryCollection<Despesa>((e) => e.id);
  final cobrancas = MemoryCollection<Cobranca>((e) => e.id);
  int seqContrato = 0;

  final Map<String, DateTime> _repasses = {};
  final _repassesChanges = StreamController<Map<String, DateTime>>.broadcast();

  Map<String, DateTime> get repasses => Map.unmodifiable(_repasses);

  Stream<Map<String, DateTime>> watchRepasses() {
    late final StreamController<Map<String, DateTime>> c;
    StreamSubscription<Map<String, DateTime>>? sub;
    c = StreamController(
      onListen: () {
        c.add(repasses);
        sub = _repassesChanges.stream.listen(c.add);
      },
      onCancel: () => sub?.cancel(),
    );
    return c.stream;
  }

  void marcarRepasse(String chave, DateTime? data) {
    data == null ? _repasses.remove(chave) : _repasses[chave] = data;
    _repassesChanges.add(repasses);
  }
}
