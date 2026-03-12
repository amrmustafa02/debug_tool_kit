import 'dart:developer' as developer;

import 'package:debug_toolkit/src/domain/models/variable_node.dart';
import 'package:flutter/foundation.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

/// Connects to the Dart VM Service to inspect in-memory variables,
/// similar to how IDE debuggers read variables.
class VmServiceConnector {
  VmService? _service;
  String? _isolateId;

  bool get isConnected => _service != null && _isolateId != null;

  Future<bool> connect() async {
    if (isConnected) return true;

    try {
      final info = await developer.Service.getInfo();
      final uri = info.serverWebSocketUri;
      if (uri == null) return false;

      _service = await vmServiceConnectUri(uri.toString());

      final vm = await _service!.getVM();
      final isolates = vm.isolates;
      if (isolates == null || isolates.isEmpty) return false;

      _isolateId = isolates.first.id;
      return true;
    } catch (e) {
      debugPrint('VmServiceConnector: Failed to connect: $e');
      _service = null;
      _isolateId = null;
      return false;
    }
  }

  /// Returns user libraries (filters out dart:, package:flutter, etc.)
  Future<List<LibraryRef>> getUserLibraries() async {
    if (!isConnected) return [];

    try {
      final isolate = await _service!.getIsolate(_isolateId!);
      final libs = isolate.libraries ?? [];

      return libs.where((lib) {
        final uri = lib.uri ?? '';
        if (uri.startsWith('dart:')) return false;
        if (uri.startsWith('package:flutter/')) return false;
        if (uri.startsWith('package:debug_toolkit/')) return false;
        if (uri.startsWith('package:dio/')) return false;
        if (uri.startsWith('package:device_info_plus/')) return false;
        if (uri.startsWith('package:package_info_plus/')) return false;
        if (uri.startsWith('package:vm_service/')) return false;
        if (uri.contains('_internal')) return false;
        if (uri.contains('gen_l10n')) return false;
        return true;
      }).toList();
    } catch (e) {
      debugPrint('VmServiceConnector: Failed to get libraries: $e');
      return [];
    }
  }

  /// Gets top-level variables and classes with static fields from a library.
  Future<List<VariableNode>> getLibraryVariables(String libraryId) async {
    if (!isConnected) return [];

    try {
      final lib =
          await _service!.getObject(_isolateId!, libraryId) as Library;
      final nodes = <VariableNode>[];

      // Top-level variables
      for (final fieldRef in lib.variables ?? <FieldRef>[]) {
        final node = await _resolveFieldRef(fieldRef);
        if (node != null) nodes.add(node);
      }

      // Classes and their static fields
      for (final classRef in lib.classes ?? <ClassRef>[]) {
        final className = classRef.name ?? 'Unknown';
        // Skip private generated classes
        if (className.startsWith('_') && className.contains('State')) continue;

        try {
          final cls =
              await _service!.getObject(_isolateId!, classRef.id!) as Class;
          final staticFields = <VariableNode>[];

          for (final fieldRef in cls.fields ?? <FieldRef>[]) {
            if (fieldRef.isStatic != true) continue;
            final node = await _resolveFieldRef(fieldRef);
            if (node != null) staticFields.add(node);
          }

          if (staticFields.isNotEmpty) {
            nodes.add(VariableNode(
              name: className,
              typeName: 'class',
              displayValue: '${staticFields.length} static field(s)',
              objectId: classRef.id,
              isExpandable: true,
            ));
          }
        } catch (_) {
          // Skip classes that can't be inspected
        }
      }

      return nodes;
    } catch (e) {
      debugPrint('VmServiceConnector: Failed to get library variables: $e');
      return [];
    }
  }

  /// Gets children of an expandable node (object fields, list elements, map entries).
  Future<List<VariableNode>> getChildren(String objectId) async {
    if (!isConnected) return [];

    try {
      final obj = await _service!.getObject(_isolateId!, objectId);

      if (obj is Instance) {
        return _resolveInstanceChildren(obj);
      }

      if (obj is Class) {
        final nodes = <VariableNode>[];
        for (final fieldRef in obj.fields ?? <FieldRef>[]) {
          if (fieldRef.isStatic != true) continue;
          final node = await _resolveFieldRef(fieldRef);
          if (node != null) nodes.add(node);
        }
        return nodes;
      }

      return [];
    } catch (e) {
      debugPrint('VmServiceConnector: Failed to get children: $e');
      return [];
    }
  }

  Future<List<VariableNode>> _resolveInstanceChildren(Instance instance) async {
    final nodes = <VariableNode>[];

    // PlainInstance — show fields
    if (instance.fields != null) {
      for (final field in instance.fields!) {
        final name = field.name?.toString() ??
            field.decl?.name ??
            '?';
        final node = await _resolveValue(name, field.value);
        if (node != null) nodes.add(node);
      }
    }

    // List/Set — show elements
    if (instance.elements != null) {
      for (var i = 0; i < instance.elements!.length; i++) {
        final node = await _resolveValue('[$i]', instance.elements![i]);
        if (node != null) nodes.add(node);
      }
    }

    // Map — show associations
    if (instance.associations != null) {
      for (final assoc in instance.associations!) {
        final keyStr = await _valueToString(assoc.key);
        final node = await _resolveValue(keyStr, assoc.value);
        if (node != null) nodes.add(node);
      }
    }

    return nodes;
  }

  Future<VariableNode?> _resolveFieldRef(FieldRef fieldRef) async {
    final name = fieldRef.name ?? '?';

    try {
      // Fetch the full Field object to access staticValue
      final field =
          await _service!.getObject(_isolateId!, fieldRef.id!) as Field;

      if (field.staticValue != null) {
        return _resolveValue(name, field.staticValue);
      }

      // For non-static fields, show the declared type
      final declaredType = field.declaredType;
      if (declaredType is InstanceRef) {
        return VariableNode(
          name: name,
          typeName: declaredType.classRef?.name ?? 'dynamic',
          displayValue: '(instance field)',
        );
      }

      return VariableNode(
        name: name,
        typeName: 'dynamic',
        displayValue: '...',
      );
    } catch (e) {
      return VariableNode(
        name: name,
        typeName: '?',
        displayValue: 'Error: $e',
      );
    }
  }

  Future<VariableNode?> _resolveValue(String name, dynamic value) async {
    if (value is Sentinel) {
      return VariableNode(
        name: name,
        typeName: 'Sentinel',
        displayValue: value.valueAsString ?? 'Not initialized',
      );
    }

    if (value is InstanceRef) {
      final kind = value.kind ?? '';
      final className = value.classRef?.name ?? 'Object';

      // Primitives
      if (kind == InstanceKind.kNull) {
        return VariableNode(
          name: name,
          typeName: 'Null',
          displayValue: 'null',
        );
      }

      if (kind == InstanceKind.kBool ||
          kind == InstanceKind.kInt ||
          kind == InstanceKind.kDouble) {
        return VariableNode(
          name: name,
          typeName: className,
          displayValue: value.valueAsString ?? '?',
        );
      }

      if (kind == InstanceKind.kString) {
        final str = value.valueAsString ?? '';
        final truncated = str.length > 100 ? '${str.substring(0, 100)}...' : str;
        return VariableNode(
          name: name,
          typeName: 'String',
          displayValue: '"$truncated"',
        );
      }

      // Collections
      if (kind == InstanceKind.kList) {
        final len = value.length ?? 0;
        return VariableNode(
          name: name,
          typeName: 'List',
          displayValue: 'List ($len)',
          objectId: value.id,
          isExpandable: len > 0,
        );
      }

      if (kind == InstanceKind.kMap) {
        final len = value.length ?? 0;
        return VariableNode(
          name: name,
          typeName: 'Map',
          displayValue: 'Map ($len)',
          objectId: value.id,
          isExpandable: len > 0,
        );
      }

      // Objects
      return VariableNode(
        name: name,
        typeName: className,
        displayValue: value.valueAsString ?? className,
        objectId: value.id,
        isExpandable: kind == InstanceKind.kPlainInstance,
      );
    }

    return VariableNode(
      name: name,
      typeName: value.runtimeType.toString(),
      displayValue: value.toString(),
    );
  }

  Future<String> _valueToString(dynamic value) async {
    if (value is InstanceRef) {
      if (value.valueAsString != null) return value.valueAsString!;
      return value.classRef?.name ?? '?';
    }
    return value.toString();
  }

  void dispose() {
    _service?.dispose();
    _service = null;
    _isolateId = null;
  }
}
