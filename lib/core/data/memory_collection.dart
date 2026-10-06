import 'dart:async';

/// Coleção em memória observável, usada pelas fontes de dados locais até
/// existir um backend.
class MemoryCollection<T> {
  MemoryCollection(this._idOf);

  final String Function(T) _idOf;
  final List<T> _items = [];
  final _changes = StreamController<List<T>>.broadcast();

  List<T> get all => List.unmodifiable(_items);

  T? byId(String id) => _items.where((e) => _idOf(e) == id).firstOrNull;

  /// Emite a lista atual ao assinar e depois a cada alteração.
  Stream<List<T>> watch() {
    late final StreamController<List<T>> controller;
    StreamSubscription<List<T>>? sub;
    controller = StreamController<List<T>>(
      onListen: () {
        controller.add(all);
        sub = _changes.stream.listen(controller.add);
      },
      onCancel: () => sub?.cancel(),
    );
    return controller.stream;
  }

  void upsert(T item) {
    final i = _items.indexWhere((e) => _idOf(e) == _idOf(item));
    i >= 0 ? _items[i] = item : _items.add(item);
    _emit();
  }

  void removeWhere(bool Function(T) test) {
    _items.removeWhere(test);
    _emit();
  }

  void clear() {
    _items.clear();
    _emit();
  }

  void _emit() => _changes.add(all);
}
