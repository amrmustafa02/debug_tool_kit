import 'package:debug_toolkit/src/domain/models/variable_node.dart';
import 'package:debug_toolkit/src/domain/services/variable_inspector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VariableTreeNodeWidget extends StatefulWidget {
  final VariableNode node;
  final VariableInspector inspector;
  final int depth;

  const VariableTreeNodeWidget({
    super.key,
    required this.node,
    required this.inspector,
    this.depth = 0,
  });

  @override
  State<VariableTreeNodeWidget> createState() => _VariableTreeNodeWidgetState();
}

class _VariableTreeNodeWidgetState extends State<VariableTreeNodeWidget> {
  bool _expanded = false;
  List<VariableNode>? _children;
  bool _loading = false;

  Color _typeColor(String typeName) {
    switch (typeName) {
      case 'String':
        return Colors.green;
      case 'int':
      case 'double':
      case 'num':
        return Colors.blue;
      case 'bool':
        return Colors.orange;
      case 'Null':
        return Colors.red;
      case 'List':
      case 'Map':
      case 'Set':
        return Colors.purple;
      case 'class':
        return Colors.teal;
      default:
        return Colors.cyan;
    }
  }

  Future<void> _toggle() async {
    if (!widget.node.isExpandable) return;

    if (_expanded) {
      setState(() => _expanded = false);
      return;
    }

    if (_children == null) {
      setState(() => _loading = true);
      try {
        final children = await widget.inspector.expandNode(widget.node);
        if (mounted) {
          setState(() {
            _children = children;
            _loading = false;
            _expanded = true;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _loading = false);
      }
    } else {
      setState(() => _expanded = true);
    }
  }

  void _copyValue() {
    final text = '${widget.node.name}: ${widget.node.displayValue}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final indent = 16.0 * widget.depth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: node.isExpandable ? _toggle : null,
          onLongPress: _copyValue,
          child: Container(
            padding: EdgeInsets.only(
              left: 8 + indent,
              right: 8,
              top: 6,
              bottom: 6,
            ),
            color: widget.depth % 2 == 0
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.02),
            child: Row(
              children: [
                // Expand/collapse arrow
                SizedBox(
                  width: 20,
                  child: node.isExpandable
                      ? _loading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: Colors.grey,
                              ),
                            )
                          : Icon(
                              _expanded
                                  ? Icons.arrow_drop_down
                                  : Icons.arrow_right,
                              color: Colors.grey[400],
                              size: 20,
                            )
                      : const SizedBox.shrink(),
                ),
                // Variable name
                Text(
                  node.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 8),
                // Type badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: _typeColor(node.typeName).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    node.typeName,
                    style: TextStyle(
                      color: _typeColor(node.typeName),
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Value
                Expanded(
                  child: Text(
                    node.displayValue,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Children
        if (_expanded && _children != null)
          ..._children!.map(
            (child) => VariableTreeNodeWidget(
              node: child,
              inspector: widget.inspector,
              depth: widget.depth + 1,
            ),
          ),
      ],
    );
  }
}
