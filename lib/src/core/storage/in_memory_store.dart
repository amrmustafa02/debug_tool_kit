import 'dart:async';

class InMemoryStore<T> {
  final int maxItems;
  final List<T> _items = [];
  final _controller = StreamController<List<T>>.broadcast();

  InMemoryStore({this.maxItems = 500});

  List<T> get items => List.unmodifiable(_items);

  Stream<List<T>> get stream => _controller.stream;

  void add(T item) {
    _items.insert(0, item);
    if (_items.length > maxItems) {
      _items.removeRange(maxItems, _items.length);
    }
    _notify();
  }

  void update(bool Function(T) test, T Function(T) updater) {
    final index = _items.indexWhere(test);
    if (index != -1) {
      _items[index] = updater(_items[index]);
      _notify();
    }
  }

  void remove(bool Function(T) test) {
    _items.removeWhere(test);
    _notify();
  }

  void clear() {
    _items.clear();
    _notify();
  }

  void _notify() {
    _controller.add(List.unmodifiable(_items));
  }

  void dispose() {
    _controller.close();
  }
}
