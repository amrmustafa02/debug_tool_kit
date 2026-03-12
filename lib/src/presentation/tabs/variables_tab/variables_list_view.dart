import 'package:debug_toolkit/src/domain/services/variable_inspector.dart';
import 'package:debug_toolkit/src/presentation/tabs/variables_tab/variable_tree_node_widget.dart';
import 'package:debug_toolkit/src/presentation/widgets/debug_search_bar.dart';
import 'package:flutter/material.dart';

class VariablesListView extends StatefulWidget {
  final VariableInspector inspector;

  const VariablesListView({super.key, required this.inspector});

  @override
  State<VariablesListView> createState() => _VariablesListViewState();
}

class _VariablesListViewState extends State<VariablesListView> {
  String _searchQuery = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVariables();
  }

  Future<void> _loadVariables() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await widget.inspector.initialize();
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      await widget.inspector.refresh();
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Connecting to VM Service...',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Failed to connect to VM Service',
                style: TextStyle(color: Colors.grey[300], fontSize: 15),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadVariables,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<List<LibraryGroup>>(
      stream: widget.inspector.stream,
      initialData: widget.inspector.groups,
      builder: (context, snapshot) {
        final groups = snapshot.data ?? [];

        // Filter by search query
        final filteredGroups = _searchQuery.isEmpty
            ? groups
            : groups
                .map((g) => LibraryGroup(
                      name: g.name,
                      variables: g.variables
                          .where((v) => v.name
                              .toLowerCase()
                              .contains(_searchQuery.toLowerCase()))
                          .toList(),
                    ))
                .where((g) => g.variables.isNotEmpty)
                .toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Row(
                children: [
                  Expanded(
                    child: DebugSearchBar(
                      hint: 'Search variables...',
                      onChanged: (q) => setState(() => _searchQuery = q),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    color: Colors.grey[400],
                    tooltip: 'Refresh',
                    onPressed: _refresh,
                  ),
                ],
              ),
            ),
            if (filteredGroups.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    _searchQuery.isEmpty
                        ? 'No variables found'
                        : 'No matching variables',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: filteredGroups.length,
                  itemBuilder: (context, index) {
                    final group = filteredGroups[index];
                    return _LibraryGroupWidget(
                      group: group,
                      inspector: widget.inspector,
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _LibraryGroupWidget extends StatefulWidget {
  final LibraryGroup group;
  final VariableInspector inspector;

  const _LibraryGroupWidget({required this.group, required this.inspector});

  @override
  State<_LibraryGroupWidget> createState() => _LibraryGroupWidgetState();
}

class _LibraryGroupWidgetState extends State<_LibraryGroupWidget> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: const Color(0xFF252525),
            child: Row(
              children: [
                Icon(
                  _expanded ? Icons.folder_open : Icons.folder,
                  size: 16,
                  color: Colors.amber,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.group.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${widget.group.variables.length}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                const SizedBox(width: 4),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: Colors.grey[500],
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          ...widget.group.variables.map(
            (node) => VariableTreeNodeWidget(
              node: node,
              inspector: widget.inspector,
            ),
          ),
        Divider(color: Colors.grey[800], height: 1),
      ],
    );
  }
}
