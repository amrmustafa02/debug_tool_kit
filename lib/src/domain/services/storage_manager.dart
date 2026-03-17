import 'dart:io';

import 'package:debug_toolkit/src/domain/models/file_entry.dart';

class StorageManager {
  final String rootPath;

  StorageManager({required this.rootPath});

  Future<List<FileEntry>> listDirectory(String path) async {
    try {
      final dir = Directory(path);
      if (!await dir.exists()) return [];

      final entities = await dir.list(followLinks: false).toList();
      final entries = entities
          .where((e) => !e.uri.pathSegments.last.startsWith('.'))
          .map(FileEntry.fromFileSystemEntity)
          .toList();

      entries.sort((a, b) {
        if (a.isDirectory != b.isDirectory) {
          return a.isDirectory ? -1 : 1;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      return entries;
    } on FileSystemException {
      return [];
    }
  }
}
