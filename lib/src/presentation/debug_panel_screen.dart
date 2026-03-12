import 'package:debug_toolkit/src/data/system_info_collector.dart';
import 'package:debug_toolkit/src/domain/models/debug_tool.dart';
import 'package:debug_toolkit/src/domain/services/log_manager.dart';
import 'package:debug_toolkit/src/domain/services/network_manager.dart';
import 'package:debug_toolkit/src/domain/services/variable_inspector.dart';
import 'package:debug_toolkit/src/presentation/tabs/logs_tab/logs_list_view.dart';
import 'package:debug_toolkit/src/presentation/tabs/network_tab/network_list_view.dart';
import 'package:debug_toolkit/src/presentation/tabs/system_tab/system_info_view.dart';
import 'package:debug_toolkit/src/presentation/tabs/variables_tab/variables_list_view.dart';
import 'package:flutter/material.dart';

class DebugPanelScreen extends StatelessWidget {
  final NetworkManager networkManager;
  final LogManager logManager;
  final SystemInfoCollector systemInfoCollector;
  final VariableInspector? variableInspector;
  final List<DebugTool> extraTools;

  const DebugPanelScreen({
    super.key,
    required this.networkManager,
    required this.logManager,
    required this.systemInfoCollector,
    this.variableInspector,
    this.extraTools = const [],
  });

  @override
  Widget build(BuildContext context) {
    final hasVariables = variableInspector != null;
    final tabs = <_TabData>[
      _TabData(icon: Icons.wifi, label: 'Network'),
      _TabData(icon: Icons.article, label: 'Logs'),
      if (hasVariables) _TabData(icon: Icons.data_object, label: 'Variables'),
      _TabData(icon: Icons.info_outline, label: 'System'),
      ...extraTools.map((t) => _TabData(icon: t.icon, label: t.name)),
    ];

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A1A),
          elevation: 0,
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
        ),
      ),
      child: DefaultTabController(
        length: tabs.length,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Debug Panel', style: TextStyle(fontSize: 16)),
            bottom: TabBar(
              isScrollable: tabs.length > 4,
              tabs: tabs
                  .map((t) => Tab(icon: Icon(t.icon, size: 18), text: t.label))
                  .toList(),
            ),
          ),
          body: TabBarView(
            children: [
              NetworkListView(networkManager: networkManager),
              LogsListView(logManager: logManager),
              if (hasVariables)
                VariablesListView(inspector: variableInspector!),
              SystemInfoView(collector: systemInfoCollector),
              ...extraTools.map((t) => t.builder(context)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabData {
  final IconData icon;
  final String label;
  const _TabData({required this.icon, required this.label});
}
