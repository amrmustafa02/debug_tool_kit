import 'package:debug_toolkit/src/core/storage/in_memory_store.dart';
import 'package:debug_toolkit/src/domain/models/log_entry.dart';

class LogManager {
  final InMemoryStore<LogEntry> _store;

  LogManager({int maxLogs = 500}) : _store = InMemoryStore(maxItems: maxLogs);

  List<LogEntry> get entries => _store.items;

  Stream<List<LogEntry>> get stream => _store.stream;

  void log(String message, {LogLevel level = LogLevel.info, String? tag}) {
    final entry = LogEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      level: level,
      tag: tag,
      message: message,
    );
    _store.add(entry);
  }

  List<LogEntry> filterByLevel(LogLevel level) {
    return entries.where((e) => e.level == level).toList();
  }

  List<LogEntry> search(String query) {
    final q = query.toLowerCase();
    return entries.where((e) {
      return e.message.toLowerCase().contains(q) ||
          (e.tag?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  void delete(String id) {
    _store.remove((e) => e.id == id);
  }

  void clear() => _store.clear();

  void dispose() => _store.dispose();
}
