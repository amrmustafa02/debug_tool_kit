import 'package:debug_toolkit/src/domain/models/log_entry.dart';
import 'package:debug_toolkit/src/domain/services/log_manager.dart';
import 'package:debug_toolkit/src/presentation/widgets/copy_button.dart';
import 'package:debug_toolkit/src/presentation/widgets/debug_search_bar.dart';
import 'package:flutter/material.dart';

class LogsListView extends StatefulWidget {
  final LogManager logManager;

  const LogsListView({super.key, required this.logManager});

  @override
  State<LogsListView> createState() => _LogsListViewState();
}

class _LogsListViewState extends State<LogsListView> {
  String _searchQuery = '';
  LogLevel? _levelFilter;

  static const _levelColors = {
    LogLevel.debug: Colors.grey,
    LogLevel.info: Colors.blue,
    LogLevel.warning: Colors.orange,
    LogLevel.error: Colors.red,
  };

  List<LogEntry> _applyFilters(List<LogEntry> entries) {
    var filtered = entries;

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((e) {
        return e.message.toLowerCase().contains(q) ||
            (e.tag?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    if (_levelFilter != null) {
      filtered = filtered.where((e) => e.level == _levelFilter).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DebugSearchBar(hint: 'Search logs...', onChanged: (q) => setState(() => _searchQuery = q)),
        _buildFilterBar(),
        Expanded(
          child: StreamBuilder<List<LogEntry>>(
            stream: widget.logManager.stream,
            initialData: widget.logManager.entries,
            builder: (context, snapshot) {
              final entries = _applyFilters(snapshot.data ?? []);
              if (entries.isEmpty) {
                return const Center(
                  child: Text('No logs', style: TextStyle(color: Colors.grey)),
                );
              }
              return ListView.separated(
                itemCount: entries.length,
                separatorBuilder: (_, __) => Divider(color: Colors.grey[800], height: 1),
                itemBuilder: (context, index) => _LogTile(
                  entry: entries[index],
                  onDelete: () => widget.logManager.delete(entries[index].id),
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
          ...LogLevel.values.map((level) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: Text(
                    level.name.toUpperCase(),
                    style: const TextStyle(fontSize: 11),
                  ),
                  selected: _levelFilter == level,
                  onSelected: (s) => setState(() => _levelFilter = s ? level : null),
                  selectedColor: _levelColors[level]!.withValues(alpha: 0.3),
                  backgroundColor: const Color(0xFF2A2A2A),
                  labelStyle: TextStyle(
                    color: _levelFilter == level ? _levelColors[level] : Colors.grey[400],
                  ),
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                ),
              )),
          const SizedBox(width: 8),
          ActionChip(
            label: const Text('Clear All', style: TextStyle(fontSize: 11, color: Colors.red)),
            onPressed: () {
              widget.logManager.clear();
              setState(() {
                _levelFilter = null;
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

class _LogTile extends StatelessWidget {
  final LogEntry entry;
  final VoidCallback onDelete;

  const _LogTile({required this.entry, required this.onDelete});

  static const _levelColors = {
    LogLevel.debug: Colors.grey,
    LogLevel.info: Colors.blue,
    LogLevel.warning: Colors.orange,
    LogLevel.error: Colors.red,
  };

  @override
  Widget build(BuildContext context) {
    final color = _levelColors[entry.level]!;

    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red.withValues(alpha: 0.3),
        child: const Icon(Icons.delete, color: Colors.red, size: 20),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        leading: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        minLeadingWidth: 12,
        title: Text(
          entry.message,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          maxLines: null,
        ),
        subtitle: Text(
          '${entry.formattedTime}${entry.tag != null ? '  [${entry.tag}]' : ''}',
          style: TextStyle(color: Colors.grey[600], fontSize: 11),
        ),
        trailing: CopyButton(text: entry.message),
      ),
    );
  }
}
