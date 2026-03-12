import 'dart:async';

import 'package:debug_toolkit/src/data/vm_service_connector.dart';
import 'package:debug_toolkit/src/domain/models/variable_node.dart';

/// Groups of variables organized by library name.
class LibraryGroup {
  final String name;
  final List<VariableNode> variables;

  const LibraryGroup({required this.name, required this.variables});
}

/// Orchestrates variable discovery via the Dart VM Service.
class VariableInspector {
  final VmServiceConnector _connector;
  final _controller = StreamController<List<LibraryGroup>>.broadcast();
  List<LibraryGroup> _groups = [];

  VariableInspector({VmServiceConnector? connector})
      : _connector = connector ?? VmServiceConnector();

  List<LibraryGroup> get groups => _groups;

  Stream<List<LibraryGroup>> get stream => _controller.stream;

  bool get isConnected => _connector.isConnected;

  /// Connect to VM service and load root variables.
  Future<void> initialize() async {
    final connected = await _connector.connect();
    if (connected) {
      await refresh();
    }
  }

  /// Re-scan all user libraries for variables.
  Future<void> refresh() async {
    if (!_connector.isConnected) {
      final connected = await _connector.connect();
      if (!connected) return;
    }

    final libs = await _connector.getUserLibraries();
    final groups = <LibraryGroup>[];

    for (final lib in libs) {
      final uri = lib.uri ?? '';
      // Extract a short readable name from the library URI
      final name = _shortLibraryName(uri);
      final variables = await _connector.getLibraryVariables(lib.id!);
      if (variables.isNotEmpty) {
        groups.add(LibraryGroup(name: name, variables: variables));
      }
    }

    _groups = groups;
    _controller.add(_groups);
  }

  /// Load children of an expandable node.
  Future<List<VariableNode>> expandNode(VariableNode node) async {
    if (node.objectId == null) return [];
    return _connector.getChildren(node.objectId!);
  }

  String _shortLibraryName(String uri) {
    // "package:my_app/src/models/user.dart" → "models/user.dart"
    // "file:///path/to/lib/main.dart" → "main.dart"
    if (uri.startsWith('package:')) {
      final parts = uri.split('/');
      if (parts.length > 2) {
        return parts.sublist(1).join('/');
      }
      return parts.last;
    }
    if (uri.contains('/lib/')) {
      return uri.split('/lib/').last;
    }
    return uri.split('/').last;
  }

  void dispose() {
    _controller.close();
    _connector.dispose();
  }
}
