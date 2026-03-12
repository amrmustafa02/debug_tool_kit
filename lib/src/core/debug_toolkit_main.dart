import 'package:debug_toolkit/src/data/dio_interceptor.dart';
import 'package:debug_toolkit/src/data/system_info_collector.dart';
import 'package:debug_toolkit/src/domain/models/debug_tool.dart';
import 'package:debug_toolkit/src/domain/models/log_entry.dart';
import 'package:debug_toolkit/src/domain/services/log_manager.dart';
import 'package:debug_toolkit/src/domain/services/network_manager.dart';
import 'package:debug_toolkit/src/domain/services/variable_inspector.dart';
import 'package:debug_toolkit/src/presentation/debug_overlay.dart';
import 'package:debug_toolkit/src/presentation/debug_panel_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DebugToolkit {
  DebugToolkit._();

  static LogManager? _logManager;
  static NetworkManager? _networkManager;
  static SystemInfoCollector? _systemInfoCollector;
  static VariableInspector? _variableInspector;
  static DebugDioInterceptor? _dioInterceptor;
  static DebugOverlay? _overlay;
  static final List<DebugTool> _tools = [];
  static bool _initialized = false;
  static bool _showFloatingButton = true;

  static LogManager get logManager {
    assert(_initialized, 'DebugToolkit.initialize() must be called first');
    return _logManager!;
  }

  static NetworkManager get networkManager {
    assert(_initialized, 'DebugToolkit.initialize() must be called first');
    return _networkManager!;
  }

  /// Initialize the debug toolkit. Call once in your app's main() or initState().
  /// No-op in release mode.
  static void initialize({
    int maxLogs = 500,
    int maxRequests = 200,
    bool showFloatingButton = true,
    String? environment,
  }) {
    if (!kDebugMode) return;
    if (_initialized) return;

    _showFloatingButton = showFloatingButton;
    _logManager = LogManager(maxLogs: maxLogs);
    _networkManager = NetworkManager(maxRequests: maxRequests);
    _systemInfoCollector = SystemInfoCollector();
    _variableInspector = VariableInspector();
    _dioInterceptor = DebugDioInterceptor(_networkManager!);

    if (environment != null) {
      _systemInfoCollector?.setEnvironment(environment);
    }

    _initialized = true;
  }

  /// Show the floating debug button overlay.
  /// Call this after the first frame (e.g., in a post-frame callback).
  static void showOverlay(BuildContext context) {
    if (!kDebugMode || !_initialized || !_showFloatingButton) return;
    if (_overlay != null) return;

    _overlay = DebugOverlay(onTap: () => showPanel(context));
    // _overlay?.show(context);
  }

  /// Hide the floating debug button.
  static void hideOverlay() {
    if (!kDebugMode) return;
    _overlay?.hide();
    _overlay = null;
  }

  /// Log a message to the debug panel.
  static void log(
    String message, {
    LogLevel level = LogLevel.info,
    String? tag,
  }) {
    if (!kDebugMode || !_initialized) return;
    _logManager!.log(message, level: level, tag: tag);
  }

  /// Get a Dio interceptor that captures network calls.
  static Interceptor dioInterceptor() {
    assert(kDebugMode && _initialized,
        'DebugToolkit.initialize() must be called first');
    return _dioInterceptor!;
  }

  /// Open the debug panel screen.
  static void showPanel(BuildContext context) {
    if (!kDebugMode || !_initialized) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DebugPanelScreen(
          networkManager: _networkManager!,
          logManager: _logManager!,
          systemInfoCollector: _systemInfoCollector!,
          variableInspector: _variableInspector,
          extraTools: _tools,
        ),
      ),
    );
  }

  /// Register a custom debug tool tab.
  static void registerTool(DebugTool tool) {
    if (!kDebugMode) return;
    _tools.add(tool);
  }

  /// Clean up resources.
  static void dispose() {
    if (!kDebugMode) return;
    hideOverlay();
    _logManager?.dispose();
    _networkManager?.dispose();
    _variableInspector?.dispose();
    _tools.clear();
    _initialized = false;
    _logManager = null;
    _networkManager = null;
    _systemInfoCollector = null;
    _variableInspector = null;
    _dioInterceptor = null;
    _overlay = null;
  }
}
