import 'package:debug_toolkit/src/core/storage/in_memory_store.dart';
import 'package:debug_toolkit/src/domain/models/network_entry.dart';

class NetworkManager {
  final InMemoryStore<NetworkEntry> _store;

  NetworkManager({int maxRequests = 200})
      : _store = InMemoryStore(maxItems: maxRequests);

  List<NetworkEntry> get entries => _store.items;

  Stream<List<NetworkEntry>> get stream => _store.stream;

  void addRequest(NetworkEntry entry) {
    _store.add(entry);
  }

  void completeRequest(
    String id, {
    int? statusCode,
    dynamic responseBody,
    Duration? duration,
    String? error,
  }) {
    _store.update(
      (e) => e.id == id,
      (e) {
        e.statusCode = statusCode;
        e.responseBody = responseBody;
        e.duration = duration;
        e.error = error;
        e.isComplete = true;
        return e;
      },
    );
  }

  List<NetworkEntry> filterByMethod(String method) {
    return entries.where((e) => e.method == method).toList();
  }

  List<NetworkEntry> filterByStatusRange(int min, int max) {
    return entries
        .where((e) => e.statusCode != null && e.statusCode! >= min && e.statusCode! < max)
        .toList();
  }

  List<NetworkEntry> search(String query) {
    final q = query.toLowerCase();
    return entries.where((e) => e.url.toLowerCase().contains(q)).toList();
  }

  void clear() => _store.clear();

  void dispose() => _store.dispose();
}
