import 'dart:io';

enum FileMediaType {
  image,
  video,
  audio,
  none;

  static FileMediaType fromExtension(String ext) {
    switch (ext.toLowerCase()) {
      case '.png':
      case '.jpg':
      case '.jpeg':
      case '.gif':
      case '.bmp':
      case '.webp':
      case '.svg':
      case '.heic':
        return FileMediaType.image;
      case '.mp4':
      case '.mov':
      case '.avi':
      case '.mkv':
      case '.webm':
      case '.flv':
      case '.wmv':
        return FileMediaType.video;
      case '.mp3':
      case '.wav':
      case '.aac':
      case '.ogg':
      case '.flac':
      case '.m4a':
      case '.wma':
        return FileMediaType.audio;
      default:
        return FileMediaType.none;
    }
  }

  bool get isPlayable => this != FileMediaType.none;
}

class FileEntry {
  final String name;
  final String path;
  final int sizeInBytes;
  final bool isDirectory;
  final FileMediaType mediaType;
  final DateTime modified;

  const FileEntry({
    required this.name,
    required this.path,
    required this.sizeInBytes,
    required this.isDirectory,
    required this.mediaType,
    required this.modified,
  });

  static FileEntry fromFileSystemEntity(FileSystemEntity entity) {
    final stat = entity.statSync();
    final name = entity.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
    final isDir = stat.type == FileSystemEntityType.directory;
    final ext = isDir ? '' : '.' + name.split('.').last;

    return FileEntry(
      name: name,
      path: entity.path,
      sizeInBytes: stat.size,
      isDirectory: isDir,
      mediaType: isDir ? FileMediaType.none : FileMediaType.fromExtension(ext),
      modified: stat.modified,
    );
  }

  String get formattedSize {
    if (isDirectory) return '';
    if (sizeInBytes < 1024) return '$sizeInBytes B';
    if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    }
    if (sizeInBytes < 1024 * 1024 * 1024) {
      return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(sizeInBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String get formattedDate {
    return '${modified.year}-${_pad(modified.month)}-${_pad(modified.day)} '
        '${_pad(modified.hour)}:${_pad(modified.minute)}';
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}
