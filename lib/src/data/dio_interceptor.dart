import 'package:debug_toolkit/src/domain/models/network_entry.dart';
import 'package:debug_toolkit/src/domain/services/network_manager.dart';
import 'package:dio/dio.dart';

const _stopwatchKey = '_debug_toolkit_stopwatch';
const _entryIdKey = '_debug_toolkit_entry_id';

class DebugDioInterceptor extends Interceptor {
  final NetworkManager _networkManager;

  DebugDioInterceptor(this._networkManager);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final stopwatch = Stopwatch()..start();
    final entryId = DateTime.now().microsecondsSinceEpoch.toString();

    options.extra[_stopwatchKey] = stopwatch;
    options.extra[_entryIdKey] = entryId;

    final entry = NetworkEntry(
      id: entryId,
      timestamp: DateTime.now(),
      method: options.method,
      url: options.uri.toString(),
      requestHeaders: options.headers,
      requestBody: options.data,
    );

    _networkManager.addRequest(entry);
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final stopwatch = response.requestOptions.extra[_stopwatchKey] as Stopwatch?;
    final entryId = response.requestOptions.extra[_entryIdKey] as String?;

    stopwatch?.stop();

    if (entryId != null) {
      _networkManager.completeRequest(
        entryId,
        statusCode: response.statusCode,
        responseBody: response.data,
        duration: stopwatch?.elapsed,
      );
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final stopwatch = err.requestOptions.extra[_stopwatchKey] as Stopwatch?;
    final entryId = err.requestOptions.extra[_entryIdKey] as String?;

    stopwatch?.stop();

    if (entryId != null) {
      _networkManager.completeRequest(
        entryId,
        statusCode: err.response?.statusCode,
        responseBody: err.response?.data,
        duration: stopwatch?.elapsed,
        error: err.message,
      );
    }

    handler.next(err);
  }
}
