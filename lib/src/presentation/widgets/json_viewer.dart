import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Postman-style JSON viewer with syntax highlighting,
/// collapsible nodes, and large-response handling.
class JsonViewer extends StatelessWidget {
  final dynamic data;
  final int maxLines;

  const JsonViewer({super.key, required this.data, this.maxLines = 500});

  @override
  Widget build(BuildContext context) {
    final parsed = _parse(data);
    if (parsed == null) {
      return SelectableText(
        data?.toString() ?? 'null',
        style: const TextStyle(
          color: Colors.greenAccent,
          fontSize: 12,
          fontFamily: 'monospace',
        ),
      );
    }

    final lineCount = _estimateLines(parsed);
    if (lineCount > maxLines) {
      return _LargeResponseViewer(data: parsed, lineCount: lineCount);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: _JsonNode(data: parsed, depth: 0),
    );
  }

  static dynamic _parse(dynamic data) {
    if (data == null) return null;
    if (data is Map || data is List) return data;
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map || decoded is List) return decoded;
      } catch (_) {}
    }
    return null;
  }

  static int _estimateLines(dynamic data) {
    if (data is Map) {
      int count = 2; // braces
      for (final v in data.values) {
        count += _estimateLines(v);
      }
      return count;
    }
    if (data is List) {
      int count = 2; // brackets
      for (final v in data) {
        count += _estimateLines(v);
      }
      return count;
    }
    return 1;
  }
}

/// Handles very large responses with a collapsed preview + expand option.
class _LargeResponseViewer extends StatefulWidget {
  final dynamic data;
  final int lineCount;

  const _LargeResponseViewer({required this.data, required this.lineCount});

  @override
  State<_LargeResponseViewer> createState() => _LargeResponseViewerState();
}

class _LargeResponseViewerState extends State<_LargeResponseViewer> {
  bool _showTree = false;
  bool _showRaw = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.orange, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Large response (~${widget.lineCount} lines)',
                  style: const TextStyle(color: Colors.orange, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Preview: first-level keys only
        if (!_showTree && !_showRaw) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _JsonNode(data: widget.data, depth: 0, initiallyCollapsed: true),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _ActionChip(
                label: 'Expand tree view',
                icon: Icons.account_tree_outlined,
                onTap: () => setState(() => _showTree = true),
              ),
              const SizedBox(width: 8),
              _ActionChip(
                label: 'Show raw JSON',
                icon: Icons.code,
                onTap: () => setState(() => _showRaw = true),
              ),
            ],
          ),
        ],
        if (_showTree) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: _ActionChip(
              label: 'Collapse',
              icon: Icons.unfold_less,
              onTap: () => setState(() => _showTree = false),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _JsonNode(data: widget.data, depth: 0),
          ),
        ],
        if (_showRaw) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: _ActionChip(
              label: 'Hide raw',
              icon: Icons.unfold_less,
              onTap: () => setState(() => _showRaw = false),
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            const JsonEncoder.withIndent('  ').convert(widget.data),
            style: const TextStyle(
              color: Colors.greenAccent,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionChip(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF353535),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

/// A single JSON node – recursively builds the tree.
class _JsonNode extends StatefulWidget {
  final dynamic data;
  final int depth;
  final String? keyName;
  final bool isLast;
  final bool initiallyCollapsed;

  const _JsonNode({
    required this.data,
    required this.depth,
    this.keyName,
    this.isLast = true,
    this.initiallyCollapsed = false,
  });

  @override
  State<_JsonNode> createState() => _JsonNodeState();
}

class _JsonNodeState extends State<_JsonNode> {
  late bool _collapsed;

  @override
  void initState() {
    super.initState();
    _collapsed = widget.initiallyCollapsed || widget.depth >= 3;
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final comma = widget.isLast ? '' : ',';

    if (data is Map) {
      return _buildCollapsible(
        openBracket: '{',
        closeBracket: '}$comma',
        childCount: data.length,
        children: _buildMapChildren(data),
      );
    }

    if (data is List) {
      return _buildCollapsible(
        openBracket: '[',
        closeBracket: ']$comma',
        childCount: data.length,
        children: _buildListChildren(data),
      );
    }

    // Primitive value
    return Padding(
      padding: EdgeInsets.only(left: widget.depth * 16.0),
      child: _buildPrimitiveLine(data, comma),
    );
  }

  Widget _buildCollapsible({
    required String openBracket,
    required String closeBracket,
    required int childCount,
    required List<Widget> children,
  }) {
    final indent = widget.depth * 16.0;

    return IntrinsicWidth(
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header line: key: { ▼  or  key: { ... } (collapsed)
        GestureDetector(
          onTap: () => setState(() => _collapsed = !_collapsed),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: EdgeInsets.only(left: indent),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _collapsed
                      ? Icons.arrow_right_rounded
                      : Icons.arrow_drop_down_rounded,
                  color: Colors.white38,
                  size: 18,
                ),
                _collapsed
                    ? _buildCollapsedLine(
                        openBracket, closeBracket, childCount)
                    : _buildExpandedHeader(openBracket),
              ],
            ),
          ),
        ),
        // Children
        if (!_collapsed) ...[
          ...children,
          Padding(
            padding: EdgeInsets.only(left: indent + 18),
            child: Text(
              closeBracket,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
        ],
      ],
    ),
    );
  }

  Widget _buildCollapsedLine(
      String open, String close, int childCount) {
    final keyWidget = _buildKeyWidget();
    return Text.rich(
      TextSpan(
        children: [
          if (keyWidget != null) keyWidget,
          TextSpan(
            text: '$open ... $close',
            style: const TextStyle(color: Colors.white54),
          ),
          TextSpan(
            text: '  // $childCount ${childCount == 1 ? 'item' : 'items'}',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.25), fontStyle: FontStyle.italic),
          ),
        ],
        style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
      ),
    );
  }

  Widget _buildExpandedHeader(String openBracket) {
    final keyWidget = _buildKeyWidget();
    return Text.rich(
      TextSpan(
        children: [
          if (keyWidget != null) keyWidget,
          TextSpan(
              text: openBracket,
              style: const TextStyle(color: Colors.white70)),
        ],
        style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
      ),
    );
  }

  Widget _buildPrimitiveLine(dynamic value, String comma) {
    final keyWidget = _buildKeyWidget();
    return Padding(
      padding: const EdgeInsets.only(left: 18),
      child: Text.rich(
        TextSpan(
          children: [
            if (keyWidget != null) keyWidget,
            _valueSpan(value),
            if (comma.isNotEmpty)
              TextSpan(
                  text: comma, style: const TextStyle(color: Colors.white54)),
          ],
          style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
        ),
      ),
    );
  }

  InlineSpan? _buildKeyWidget() {
    if (widget.keyName == null) return null;
    return TextSpan(children: [
      TextSpan(
        text: '"${widget.keyName}"',
        style: const TextStyle(color: Color(0xFF82AAFF)), // blue keys
      ),
      const TextSpan(
          text: ': ', style: TextStyle(color: Colors.white54)),
    ]);
  }

  static InlineSpan _valueSpan(dynamic value) {
    if (value == null) {
      return const TextSpan(
          text: 'null', style: TextStyle(color: Color(0xFFFF5370)));
    }
    if (value is bool) {
      return TextSpan(
        text: value.toString(),
        style: const TextStyle(color: Color(0xFFFF5370)), // red
      );
    }
    if (value is num) {
      return TextSpan(
        text: value.toString(),
        style: const TextStyle(color: Color(0xFFF78C6C)), // orange
      );
    }
    // String
    String display = value.toString();
    if (display.length > 300) {
      display = '${display.substring(0, 300)}...';
    }
    return TextSpan(
      text: '"$display"',
      style: const TextStyle(color: Color(0xFFC3E88D)), // green
    );
  }

  List<Widget> _buildMapChildren(Map data) {
    final keys = data.keys.toList();
    // Limit visible children to avoid rendering thousands at once
    final limit = math.min(keys.length, 200);
    final widgets = <Widget>[];

    for (int i = 0; i < limit; i++) {
      final key = keys[i];
      widgets.add(_JsonNode(
        data: data[key],
        depth: widget.depth + 1,
        keyName: key.toString(),
        isLast: i == keys.length - 1,
      ));
    }

    if (keys.length > limit) {
      widgets.add(Padding(
        padding: EdgeInsets.only(left: (widget.depth + 1) * 16.0 + 18),
        child: Text(
          '// ... ${keys.length - limit} more keys',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 12,
            fontFamily: 'monospace',
            fontStyle: FontStyle.italic,
          ),
        ),
      ));
    }

    return widgets;
  }

  List<Widget> _buildListChildren(List data) {
    final limit = math.min(data.length, 200);
    final widgets = <Widget>[];

    for (int i = 0; i < limit; i++) {
      widgets.add(_JsonNode(
        data: data[i],
        depth: widget.depth + 1,
        isLast: i == data.length - 1,
      ));
    }

    if (data.length > limit) {
      widgets.add(Padding(
        padding: EdgeInsets.only(left: (widget.depth + 1) * 16.0 + 18),
        child: Text(
          '// ... ${data.length - limit} more items',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 12,
            fontFamily: 'monospace',
            fontStyle: FontStyle.italic,
          ),
        ),
      ));
    }

    return widgets;
  }
}
