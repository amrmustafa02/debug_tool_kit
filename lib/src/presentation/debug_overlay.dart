import 'package:flutter/material.dart';

class DebugOverlay {
  OverlayEntry? _overlayEntry;
  final VoidCallback onTap;

  DebugOverlay({required this.onTap});

  void show(BuildContext context) {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => _DraggableDebugButton(
        onTap: onTap,
        onRemove: hide,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

class _DraggableDebugButton extends StatefulWidget {
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _DraggableDebugButton({required this.onTap, required this.onRemove});

  @override
  State<_DraggableDebugButton> createState() => _DraggableDebugButtonState();
}

class _DraggableDebugButtonState extends State<_DraggableDebugButton> {
  double _x = 16;
  double _y = 100;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;

    return Positioned(
      left: _x,
      top: _y,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _x = (_x + details.delta.dx).clamp(0, screen.width - 44);
            _y = (_y + details.delta.dy).clamp(0, screen.height - 44);
          });
        },
        onTap: widget.onTap,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blue, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(Icons.bug_report, color: Colors.blue, size: 22),
          ),
        ),
      ),
    );
  }
}
