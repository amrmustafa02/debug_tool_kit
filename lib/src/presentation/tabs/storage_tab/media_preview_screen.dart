import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:debug_toolkit/src/domain/models/file_entry.dart';
import 'package:debug_toolkit/src/presentation/widgets/copy_button.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

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
        return _VideoPreview(path: entry.path);
      case FileMediaType.audio:
        return _AudioPreview(path: entry.path);
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

// ─── Image Preview ───────────────────────────────────────────

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
          errorBuilder: (_, error, __) => _ErrorView(
            icon: Icons.broken_image,
            message: 'Failed to load image',
            detail: error.toString(),
          ),
        ),
      ),
    );
  }
}

// ─── Video Preview ───────────────────────────────────────────

class _VideoPreview extends StatefulWidget {
  final String path;

  const _VideoPreview({required this.path});

  @override
  State<_VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<_VideoPreview> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.path));
    _controller.initialize().then((_) {
      if (mounted) setState(() => _initialized = true);
    }).catchError((e) {
      if (mounted) setState(() => _error = e.toString());
    });
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _ErrorView(
        icon: Icons.videocam_off,
        message: 'Failed to load video',
        detail: _error!,
      );
    }

    if (!_initialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
          ),
        ),
        _buildVideoControls(),
      ],
    );
  }

  Widget _buildVideoControls() {
    final position = _controller.value.position;
    final duration = _controller.value.duration;
    final isPlaying = _controller.value.isPlaying;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF252525),
      child: Column(
        children: [
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: Colors.purple,
              inactiveTrackColor: Colors.grey[700],
              thumbColor: Colors.purple,
            ),
            child: Slider(
              value: duration.inMilliseconds > 0
                  ? position.inMilliseconds / duration.inMilliseconds
                  : 0.0,
              onChanged: (v) {
                _controller.seekTo(Duration(
                  milliseconds: (v * duration.inMilliseconds).toInt(),
                ));
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(position),
                style: TextStyle(color: Colors.grey[400], fontSize: 11),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.replay_10, size: 22),
                    color: Colors.white,
                    onPressed: () => _controller.seekTo(
                      position - const Duration(seconds: 10),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isPlaying ? Icons.pause_circle : Icons.play_circle,
                      size: 36,
                    ),
                    color: Colors.purple,
                    onPressed: () {
                      isPlaying ? _controller.pause() : _controller.play();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.forward_10, size: 22),
                    color: Colors.white,
                    onPressed: () => _controller.seekTo(
                      position + const Duration(seconds: 10),
                    ),
                  ),
                ],
              ),
              Text(
                _formatDuration(duration),
                style: TextStyle(color: Colors.grey[400], fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Audio Preview ───────────────────────────────────────────

class _AudioPreview extends StatefulWidget {
  final String path;

  const _AudioPreview({required this.path});

  @override
  State<_AudioPreview> createState() => _AudioPreviewState();
}

class _AudioPreviewState extends State<_AudioPreview> {
  final AudioPlayer _player = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _error;

  @override
  void initState() {
    super.initState();
    _player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playerState = state);
    });
    _player.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
    _player.onDurationChanged.listen((dur) {
      if (mounted) setState(() => _duration = dur);
    });
    _player.setSource(DeviceFileSource(widget.path)).catchError((e) {
      if (mounted) setState(() => _error = e.toString());
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _ErrorView(
        icon: Icons.music_off,
        message: 'Failed to load audio',
        detail: _error!,
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.cyan.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.audiotrack, size: 64, color: Colors.cyan),
            ),
            const SizedBox(height: 32),
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: Colors.cyan,
                inactiveTrackColor: Colors.grey[700],
                thumbColor: Colors.cyan,
              ),
              child: Slider(
                value: _duration.inMilliseconds > 0
                    ? _position.inMilliseconds / _duration.inMilliseconds
                    : 0.0,
                onChanged: (v) {
                  _player.seek(Duration(
                    milliseconds: (v * _duration.inMilliseconds).toInt(),
                  ));
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(_position),
                    style: TextStyle(color: Colors.grey[400], fontSize: 11),
                  ),
                  Text(
                    _formatDuration(_duration),
                    style: TextStyle(color: Colors.grey[400], fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.replay_10, size: 22),
                  color: Colors.white,
                  onPressed: () => _player.seek(
                    _position - const Duration(seconds: 10),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    _playerState == PlayerState.playing
                        ? Icons.pause_circle
                        : Icons.play_circle,
                    size: 52,
                  ),
                  color: Colors.cyan,
                  onPressed: () {
                    if (_playerState == PlayerState.playing) {
                      _player.pause();
                    } else {
                      _player.play(DeviceFileSource(widget.path));
                    }
                  },
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.forward_10, size: 22),
                  color: Colors.white,
                  onPressed: () => _player.seek(
                    _position + const Duration(seconds: 10),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared Widgets ──────────────────────────────────────────

String _formatDuration(Duration d) {
  final hours = d.inHours;
  final minutes = d.inMinutes.remainder(60);
  final seconds = d.inSeconds.remainder(60);
  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
  return '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
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

class _ErrorView extends StatelessWidget {
  final IconData icon;
  final String message;
  final String detail;

  const _ErrorView({
    required this.icon,
    required this.message,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              detail,
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
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
