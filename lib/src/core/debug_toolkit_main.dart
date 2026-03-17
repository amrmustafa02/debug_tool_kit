import 'package:debug_toolkit/src/data/dio_interceptor.dart';
import 'package:debug_toolkit/src/data/system_info_collector.dart';
import 'package:debug_toolkit/src/domain/models/debug_tool.dart';
import 'package:debug_toolkit/src/domain/models/log_entry.dart';
import 'package:debug_toolkit/src/domain/services/log_manager.dart';
import 'package:debug_toolkit/src/domain/services/network_manager.dart';
import 'package:debug_toolkit/src/domain/services/storage_manager.dart';
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
  static StorageManager? _storageManager;
  static DebugOverlay? _overlay;
  static final List<DebugTool> _tools = [];
  static bool _initialized = false;
  static bool _showFloatingButton = true;
  static bool _allowInReleaseMode = false;

  static bool get _isEnabled => _allowInReleaseMode || kDebugMode;

  static LogManager? get logManager {
    if (!_isEnabled || !_initialized) return null;
    return _logManager!;
  }

  static NetworkManager? get networkManager {
    if (!_isEnabled || !_initialized) return null;
    return _networkManager!;
  }

  /// Initialize the debug toolkit. Call once in your app's main() or initState().
  /// No-op in release mode unless [allowInReleaseMode] is true.
  static void initialize({
    int maxLogs = 500,
    int maxRequests = 200,
    bool showFloatingButton = true,
    bool allowInReleaseMode = false,
    String? environment,
    String? storagePath,
  }) {
    _allowInReleaseMode = allowInReleaseMode;
    if (!_isEnabled) return;
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

    if (storagePath != null) {
      _storageManager = StorageManager(rootPath: storagePath);
    }

    _initialized = true;
  }

  /// Show the floating debug button overlay.
  /// Call this after the first frame (e.g., in a post-frame callback).
  static void showOverlay(BuildContext context) {
    if (!_isEnabled || !_initialized || !_showFloatingButton) return;
    if (_overlay != null) return;

    _overlay = DebugOverlay(onTap: () => showPanel(context));
    // _overlay?.show(context);
  }

  /// Hide the floating debug button.
  static void hideOverlay() {
    if (!_isEnabled) return;
    _overlay?.hide();
    _overlay = null;
  }

  /// Log a message to the debug panel.
  static void log(
    String message, {
    LogLevel level = LogLevel.info,
    String? tag,
  }) {
    if (!_isEnabled || !_initialized) return;
    _logManager!.log(message, level: level, tag: tag);
  }

  /// Get a Dio interceptor that captures network calls.
  /// Returns a no-op interceptor if the toolkit is disabled.
  static Interceptor dioInterceptor() {
    if (!_isEnabled || !_initialized) return Interceptor();
    return _dioInterceptor!;
  }

  /// Open the debug panel screen.
  static void showPanel(BuildContext context) {
    if (!_isEnabled || !_initialized) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Container(
          color: const Color(0xFF1A1A1A),
          child: DebugPanelScreen(
            networkManager: _networkManager!,
            logManager: _logManager!,
            systemInfoCollector: _systemInfoCollector!,
            variableInspector: _variableInspector,
            storageManager: _storageManager,
            extraTools: _tools,
          ),
        ),
      ),
    );
  }

  /// Set the FCM token to display in the System tab.
  static void setFcmToken(String token) {
    if (!_isEnabled || !_initialized) return;
    _systemInfoCollector!.setFcmToken(token);
  }

  /// Register a custom debug tool tab.
  static void registerTool(DebugTool tool) {
    if (!_isEnabled) return;
    _tools.add(tool);
  }

  /// Clean up resources.
  static void dispose() {
    if (!_isEnabled) return;
    hideOverlay();
    _logManager?.dispose();
    _networkManager?.dispose();
    _variableInspector?.dispose();
    _tools.clear();
    _initialized = false;
    _allowInReleaseMode = false;
    _logManager = null;
    _networkManager = null;
    _systemInfoCollector = null;
    _variableInspector = null;
    _dioInterceptor = null;
    _storageManager = null;
    _overlay = null;
  }
}
