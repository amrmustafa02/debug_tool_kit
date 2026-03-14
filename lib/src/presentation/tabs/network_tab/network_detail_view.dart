import 'dart:convert';

import 'package:debug_toolkit/src/domain/models/network_entry.dart';
import 'package:debug_toolkit/src/presentation/widgets/copy_button.dart';
import 'package:debug_toolkit/src/presentation/widgets/json_viewer.dart';
import 'package:debug_toolkit/src/presentation/widgets/status_badge.dart';
import 'package:flutter/material.dart';

class NetworkDetailView extends StatelessWidget {
  final NetworkEntry entry;

  const NetworkDetailView({super.key, required this.entry});

  String _formatBody(dynamic body) {
    if (body == null) return 'null';
    if (body is String) {
      try {
        return const JsonEncoder.withIndent('  ').convert(jsonDecode(body));
      } catch (_) {
        return body;
      }
    }
    try {
      return const JsonEncoder.withIndent('  ').convert(body);
    } catch (_) {
      return body.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1A1A1A)),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(entry.method, style: const TextStyle(fontSize: 16)),
          actions: [
            CopyButton(
              text: _buildFullText(),
              label: 'Copy all',
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildSection('Request Headers', entry.requestHeaders),
            _buildSection('Request Body', entry.requestBody),
            _buildSection('Response Body', entry.responseBody),
            if (entry.error != null) _buildTextSection('Error', entry.error!),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusBadge(statusCode: entry.statusCode),
              const SizedBox(width: 8),
              Text(entry.formattedDuration,
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const Spacer(),
              Text(entry.formattedTime,
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            entry.url,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, dynamic body) {
    if (body == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 4),
        title: Text(title,
            style: const TextStyle(color: Colors.white70, fontSize: 14)),
        initiallyExpanded: title == 'Response Body',
        collapsedIconColor: Colors.grey,
        iconColor: Colors.grey,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                JsonViewer(data: body),
                Positioned(
                  top: 0,
                  right: 0,
                  child: CopyButton(text: _formatBody(body)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 4),
        title: Text(title,
            style: const TextStyle(color: Colors.white70, fontSize: 14)),
        initiallyExpanded: true,
        collapsedIconColor: Colors.grey,
        iconColor: Colors.grey,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                SelectableText(
                  content,
                  style: const TextStyle(
                    color: Color(0xFFFF5370),
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: CopyButton(text: content),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildFullText() {
    final buffer = StringBuffer();
    buffer.writeln('${entry.method} ${entry.url}');
    buffer.writeln('Status: ${entry.statusCode}');
    buffer.writeln('Duration: ${entry.formattedDuration}');
    buffer.writeln('Time: ${entry.formattedTime}');
    buffer.writeln('\n--- Request Headers ---');
    buffer.writeln(_formatBody(entry.requestHeaders));
    buffer.writeln('\n--- Request Body ---');
    buffer.writeln(_formatBody(entry.requestBody));
    buffer.writeln('\n--- Response Body ---');
    buffer.writeln(_formatBody(entry.responseBody));
    if (entry.error != null) {
      buffer.writeln('\n--- Error ---');
      buffer.writeln(entry.error);
    }
    return buffer.toString();
  }
}
