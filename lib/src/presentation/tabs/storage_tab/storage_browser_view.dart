import 'package:debug_toolkit/src/domain/models/file_entry.dart';
import 'package:debug_toolkit/src/domain/services/storage_manager.dart';
import 'package:debug_toolkit/src/presentation/widgets/debug_search_bar.dart';
import 'package:flutter/material.dart';

class StorageBrowserView extends StatefulWidget {
  final StorageManager manager;

  const StorageBrowserView({super.key, required this.manager});

  @override
  State<StorageBrowserView> createState() => _StorageBrowserViewState();
}

class _StorageBrowserViewState extends State<StorageBrowserView> {
  final List<String> _pathStack = [];
  List<FileEntry> _entries = [];
  bool _loading = true;
  String _searchQuery = '';

  String get _currentPath => _pathStack.last;

  @override
  void initState() {
    super.initState();
    _pathStack.add(widget.manager.rootPath);
    _loadDirectory();
  }

  Future<void> _loadDirectory() async {
    setState(() => _loading = true);

    final entries = await widget.manager.listDirectory(_currentPath);

    if (mounted) {
      setState(() {
        _entries = entries;
        _loading = false;
      });
    }
  }

  void _navigateToDirectory(String path) {
    setState(() => _pathStack.add(path));
    _loadDirectory();
  }

  void _navigateToIndex(int index) {
    setState(() {
      while (_pathStack.length > index + 1) {
        _pathStack.removeLast();
      }
    });
    _loadDirectory();
  }

  bool _handlePop() {
    if (_pathStack.length > 1) {
      setState(() => _pathStack.removeLast());
      _loadDirectory();
      return false;
    }
    return true;
  }

  List<FileEntry> get _filteredEntries {
    if (_searchQuery.isEmpty) return _entries;
    final query = _searchQuery.toLowerCase();
    return _entries.where((e) => e.name.toLowerCase().contains(query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _pathStack.length <= 1,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handlePop();
      },
      child: Column(
        children: [
          _buildBreadcrumb(),
          DebugSearchBar(
            hint: 'Search files...',
            onChanged: (q) => setState(() => _searchQuery = q),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBreadcrumb() {
    final rootName =
        widget.manager.rootPath.split('/').lastWhere((s) => s.isNotEmpty);
    final segments = <String>[rootName];

    for (var i = 1; i < _pathStack.length; i++) {
      final path = _pathStack[i];
      segments.add(path.split('/').lastWhere((s) => s.isNotEmpty));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: const Color(0xFF2A2A2A),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        child: Row(
          children: [
            for (var i = 0; i < segments.length; i++) ...[
              if (i > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.chevron_right,
                      size: 16, color: Colors.grey[600]),
                ),
              GestureDetector(
                onTap: i < segments.length - 1
                    ? () => _navigateToIndex(i)
                    : null,
                child: Text(
                  segments[i],
                  style: TextStyle(
                    color: i == segments.length - 1
                        ? Colors.white
                        : Colors.grey[400],
                    fontSize: 13,
                    fontWeight: i == segments.length - 1
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = _filteredEntries;

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open, size: 48, color: Colors.grey[700]),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty ? 'No matching files' : 'Empty directory',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDirectory,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 0),
        itemCount: filtered.length,
        separatorBuilder: (_, __) =>
            Divider(color: Colors.grey[800], height: 1),
        itemBuilder: (context, index) {
          final entry = filtered[index];
          return _FileEntryTile(
            entry: entry,
            onTap: entry.isDirectory
                ? () => _navigateToDirectory(entry.path)
                : null,
          );
        },
      ),
    );
  }
}

class _FileEntryTile extends StatelessWidget {
  final FileEntry entry;
  final VoidCallback? onTap;

  const _FileEntryTile({required this.entry, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: _buildIcon(),
      title: Text(
        entry.name,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        entry.isDirectory ? 'Directory' : '${entry.formattedSize} • ${entry.formattedDate}',
        style: TextStyle(color: Colors.grey[500], fontSize: 11),
      ),
      trailing: _buildTrailing(),
      onTap: onTap,
    );
  }

  Widget _buildIcon() {
    if (entry.isDirectory) {
      return const Icon(Icons.folder, color: Colors.amber, size: 24);
    }
    switch (entry.mediaType) {
      case FileMediaType.image:
        return const Icon(Icons.image, color: Colors.green, size: 24);
      case FileMediaType.video:
        return const Icon(Icons.videocam, color: Colors.purple, size: 24);
      case FileMediaType.audio:
        return const Icon(Icons.audiotrack, color: Colors.cyan, size: 24);
      case FileMediaType.none:
        return Icon(Icons.insert_drive_file, color: Colors.grey[400], size: 24);
    }
  }

  Widget? _buildTrailing() {
    if (entry.isDirectory) {
      return Icon(Icons.chevron_right, color: Colors.grey[600], size: 20);
    }
    if (entry.mediaType.isPlayable) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: _mediaColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          entry.mediaType.name.toUpperCase(),
          style: TextStyle(color: _mediaColor, fontSize: 10, fontWeight: FontWeight.w600),
        ),
      );
    }
    return null;
  }

  Color get _mediaColor {
    switch (entry.mediaType) {
      case FileMediaType.image:
        return Colors.green;
      case FileMediaType.video:
        return Colors.purple;
      case FileMediaType.audio:
        return Colors.cyan;
      case FileMediaType.none:
        return Colors.grey;
    }
  }
}
