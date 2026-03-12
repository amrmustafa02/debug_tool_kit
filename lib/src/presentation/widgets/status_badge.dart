import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final int? statusCode;

  const StatusBadge({super.key, this.statusCode});

  Color get _color {
    if (statusCode == null) return Colors.grey;
    if (statusCode! >= 200 && statusCode! < 300) return Colors.green;
    if (statusCode! >= 300 && statusCode! < 400) return Colors.orange;
    if (statusCode! >= 400 && statusCode! < 500) return Colors.red;
    if (statusCode! >= 500) return Colors.redAccent;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _color, width: 0.5),
      ),
      child: Text(
        statusCode?.toString() ?? '...',
        style: TextStyle(color: _color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
