class NetworkEntry {
  final String id;
  final DateTime timestamp;
  final String method;
  final String url;
  final Map<String, dynamic>? requestHeaders;
  final dynamic requestBody;
  dynamic responseBody;
  int? statusCode;
  Duration? duration;
  String? error;
  bool isComplete;

  NetworkEntry({
    required this.id,
    required this.timestamp,
    required this.method,
    required this.url,
    this.requestHeaders,
    this.requestBody,
    this.responseBody,
    this.statusCode,
    this.duration,
    this.error,
    this.isComplete = false,
  });

  bool get isSuccess => statusCode != null && statusCode! >= 200 && statusCode! < 300;
  bool get isClientError => statusCode != null && statusCode! >= 400 && statusCode! < 500;
  bool get isServerError => statusCode != null && statusCode! >= 500;

  String get formattedTime =>
      '${timestamp.hour.toString().padLeft(2, '0')}:'
      '${timestamp.minute.toString().padLeft(2, '0')}:'
      '${timestamp.second.toString().padLeft(2, '0')}';

  String get formattedDuration {
    if (duration == null) return '...';
    if (duration!.inSeconds > 0) return '${duration!.inMilliseconds}ms';
    return '${duration!.inMilliseconds}ms';
  }
}
