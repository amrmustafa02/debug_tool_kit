import 'dart:io';

import 'package:debug_toolkit/src/domain/models/file_entry.dart';
import 'package:debug_toolkit/src/presentation/widgets/copy_button.dart';
import 'package:flutter/material.dart';

class MediaPreviewScreen extends StatelessWidget {
  final FileEntry entry;

  const MediaPreviewScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Theme(
        data: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF1A1A1A),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1A1A1A),
            elevation: 0,
          ),
        ),
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              entry.name,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              CopyButton(text: entry.path, label: 'Path'),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              Expanded(child: _buildPreview()),
              _buildInfoBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    switch (entry.mediaType) {
      case FileMediaType.image:
        return _ImagePreview(path: entry.path);
      case FileMediaType.video:
        return _MediaPlaceholder(
          icon: Icons.videocam,
          color: Colors.purple,
          label: 'Video File',
        );
      case FileMediaType.audio:
        return _MediaPlaceholder(
          icon: Icons.audiotrack,
          color: Colors.cyan,
          label: 'Audio File',
        );
      case FileMediaType.none:
        return _MediaPlaceholder(
          icon: Icons.insert_drive_file,
          color: Colors.grey,
          label: 'File',
        );
    }
  }

  Widget _buildInfoBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF2A2A2A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(label: 'Size', value: entry.formattedSize),
          const SizedBox(height: 6),
          _InfoRow(label: 'Modified', value: entry.formattedDate),
          const SizedBox(height: 6),
          _InfoRow(label: 'Type', value: entry.mediaType.name.toUpperCase()),
          const SizedBox(height: 6),
          _InfoRow(label: 'Path', value: entry.path),
        ],
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final String path;

  const _ImagePreview({required this.path});

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 5.0,
      child: Center(
        child: Image.file(
          File(path),
          fit: BoxFit.contain,
          errorBuilder: (_, error, __) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.broken_image, size: 64, color: Colors.grey[600]),
              const SizedBox(height: 12),
              Text(
                'Failed to load image',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                error.toString(),
                style: TextStyle(color: Colors.grey[600], fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MediaPlaceholder extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _MediaPlaceholder({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
