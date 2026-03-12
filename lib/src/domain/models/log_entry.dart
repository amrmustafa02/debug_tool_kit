enum LogLevel { debug, info, warning, error }

class LogEntry {
  final String id;
  final DateTime timestamp;
  final LogLevel level;
  final String? tag;
  final String message;

  LogEntry({
    required this.id,
    required this.timestamp,
    required this.level,
    this.tag,
    required this.message,
  });

  String get formattedTime =>
      '${timestamp.hour.toString().padLeft(2, '0')}:'
      '${timestamp.minute.toString().padLeft(2, '0')}:'
      '${timestamp.second.toString().padLeft(2, '0')}.'
      '${timestamp.millisecond.toString().padLeft(3, '0')}';
}
