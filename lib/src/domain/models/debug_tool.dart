import 'package:flutter/widgets.dart';

class DebugTool {
  final String name;
  final IconData icon;
  final WidgetBuilder builder;

  const DebugTool({
    required this.name,
    required this.icon,
    required this.builder,
  });
}
