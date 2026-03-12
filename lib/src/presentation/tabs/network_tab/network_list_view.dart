import 'package:debug_toolkit/src/domain/models/network_entry.dart';
import 'package:debug_toolkit/src/domain/services/network_manager.dart';
import 'package:debug_toolkit/src/presentation/tabs/network_tab/network_detail_view.dart';
import 'package:debug_toolkit/src/presentation/widgets/debug_search_bar.dart';
import 'package:debug_toolkit/src/presentation/widgets/status_badge.dart';
import 'package:flutter/material.dart';

class NetworkListView extends StatefulWidget {
  final NetworkManager networkManager;

  const NetworkListView({super.key, required this.networkManager});

  @override
  State<NetworkListView> createState() => _NetworkListViewState();
}

class _NetworkListViewState extends State<NetworkListView> {
  String _searchQuery = '';
  String? _methodFilter;
  String? _statusFilter;

  static const _methods = ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'];
  static const _statusFilters = {
    '2xx': [200, 300],
    '4xx': [400, 500],
    '5xx': [500, 600],
  };

  List<NetworkEntry> _applyFilters(List<NetworkEntry> entries) {
    var filtered = entries;

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((e) => e.url.toLowerCase().contains(q)).toList();
    }

    if (_methodFilter != null) {
      filtered = filtered.where((e) => e.method == _methodFilter).toList();
    }

    if (_statusFilter != null) {
      final range = _statusFilters[_statusFilter]!;
      filtered = filtered
          .where((e) =>
              e.statusCode != null &&
              e.statusCode! >= range[0] &&
              e.statusCode! < range[1])
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DebugSearchBar(hint: 'Search URL...', onChanged: (q) => setState(() => _searchQuery = q)),
        _buildFilterBar(),
        Expanded(
          child: StreamBuilder<List<NetworkEntry>>(
            stream: widget.networkManager.stream,
            initialData: widget.networkManager.entries,
            builder: (context, snapshot) {
              final entries = _applyFilters(snapshot.data ?? []);
              if (entries.isEmpty) {
                return const Center(
                  child: Text('No requests', style: TextStyle(color: Colors.grey)),
                );
              }
              return ListView.separated(
                itemCount: entries.length,
                separatorBuilder: (_, __) => Divider(color: Colors.grey[800], height: 1),
                itemBuilder: (context, index) => _RequestTile(
                  entry: entries[index],
                  onTap: () => Navigator.push(
                    context,
                    _darkPageRoute(NetworkDetailView(entry: entries[index])),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          ..._methods.map((m) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: Text(m, style: const TextStyle(fontSize: 11)),
                  selected: _methodFilter == m,
                  onSelected: (s) => setState(() => _methodFilter = s ? m : null),
                  selectedColor: Colors.blue.withValues(alpha: 0.3),
                  backgroundColor: const Color(0xFF2A2A2A),
                  labelStyle: TextStyle(
                    color: _methodFilter == m ? Colors.blue : Colors.grey[400],
                  ),
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                ),
              )),
          const SizedBox(width: 8),
          ..._statusFilters.keys.map((s) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: Text(s, style: const TextStyle(fontSize: 11)),
                  selected: _statusFilter == s,
                  onSelected: (sel) => setState(() => _statusFilter = sel ? s : null),
                  selectedColor: Colors.orange.withValues(alpha: 0.3),
                  backgroundColor: const Color(0xFF2A2A2A),
                  labelStyle: TextStyle(
                    color: _statusFilter == s ? Colors.orange : Colors.grey[400],
                  ),
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                ),
              )),
          const SizedBox(width: 8),
          ActionChip(
            label: const Text('Clear', style: TextStyle(fontSize: 11, color: Colors.red)),
            onPressed: () {
              widget.networkManager.clear();
              setState(() {
                _methodFilter = null;
                _statusFilter = null;
                _searchQuery = '';
              });
            },
            backgroundColor: const Color(0xFF2A2A2A),
            side: BorderSide.none,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

PageRoute<T> _darkPageRoute<T>(Widget page) {
  return MaterialPageRoute<T>(
    builder: (_) => Container(
      color: const Color(0xFF1A1A1A),
      child: page,
    ),
  );
}

class _RequestTile extends StatelessWidget {
  final NetworkEntry entry;
  final VoidCallback onTap;

  const _RequestTile({required this.entry, required this.onTap});

  Color get _methodColor {
    switch (entry.method) {
      case 'GET':
        return Colors.green;
      case 'POST':
        return Colors.blue;
      case 'PUT':
      case 'PATCH':
        return Colors.orange;
      case 'DELETE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(entry.url);
    final path = uri?.path ?? entry.url;

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      onTap: onTap,
      leading: SizedBox(
        width: 48,
        child: Text(
          entry.method,
          style: TextStyle(
            color: _methodColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
      title: Text(
        path,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${entry.formattedTime}  ${entry.formattedDuration}',
        style: TextStyle(color: Colors.grey[600], fontSize: 11),
      ),
      trailing: StatusBadge(statusCode: entry.statusCode),
    );
  }
}
