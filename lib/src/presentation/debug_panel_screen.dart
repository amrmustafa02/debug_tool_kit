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

class DebugPanelScreen extends StatefulWidget {
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
  State<DebugPanelScreen> createState() => _DebugPanelScreenState();
}

class _DebugPanelScreenState extends State<DebugPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<_TabData> _tabs;

  // Track which tab indices support clearing
  // 0 = Network, 1 = Logs
  static const _networkTabIndex = 0;
  static const _logsTabIndex = 1;

  @override
  void initState() {
    super.initState();
    final hasVariables = widget.variableInspector != null;
    _tabs = [
      _TabData(icon: Icons.wifi, label: 'Network'),
      _TabData(icon: Icons.article, label: 'Logs'),
      if (hasVariables)
        _TabData(icon: Icons.data_object, label: 'Variables'),
      _TabData(icon: Icons.info_outline, label: 'System'),
      ...widget.extraTools
          .map((t) => _TabData(icon: t.icon, label: t.name)),
    ];
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _canClearCurrentTab {
    final index = _tabController.index;
    return index == _networkTabIndex || index == _logsTabIndex;
  }

  void _clearCurrentTab() {
    final index = _tabController.index;
    if (index == _networkTabIndex) {
      widget.networkManager.clear();
    } else if (index == _logsTabIndex) {
      widget.logManager.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasVariables = widget.variableInspector != null;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Theme(
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
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Debug Panel', style: TextStyle(fontSize: 16)),
          actions: [
            if (_canClearCurrentTab)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                tooltip: 'Clear ${_tabs[_tabController.index].label}',
                color: Colors.red,
                onPressed: _clearCurrentTab,
              ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: _tabs.length > 4,
            tabs: _tabs
                .map((t) =>
                    Tab(icon: Icon(t.icon, size: 18), text: t.label))
                .toList(),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            NetworkListView(networkManager: widget.networkManager),
            LogsListView(logManager: widget.logManager),
            if (hasVariables)
              VariablesListView(inspector: widget.variableInspector!),
            SystemInfoView(collector: widget.systemInfoCollector),
            ...widget.extraTools.map((t) => t.builder(context)),
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
