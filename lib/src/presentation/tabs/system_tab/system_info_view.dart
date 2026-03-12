import 'package:debug_toolkit/src/data/system_info_collector.dart';
import 'package:debug_toolkit/src/presentation/widgets/copy_button.dart';
import 'package:flutter/material.dart';

class SystemInfoView extends StatefulWidget {
  final SystemInfoCollector collector;

  const SystemInfoView({super.key, required this.collector});

  @override
  State<SystemInfoView> createState() => _SystemInfoViewState();
}

class _SystemInfoViewState extends State<SystemInfoView> {
  Map<String, String>? _info;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    final info = await widget.collector.collect();
    if (mounted) {
      setState(() {
        _info = info;
        _loading = false;
      });
    }
  }

  String get _allInfoText {
    if (_info == null) return '';
    return _info!.entries.map((e) => '${e.key}: ${e.value}').join('\n');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_info == null || _info!.isEmpty) {
      return const Center(
        child: Text('No system info available', style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CopyButton(text: _allInfoText, label: 'Copy all'),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _info!.length,
            separatorBuilder: (_, __) => Divider(color: Colors.grey[800], height: 1),
            itemBuilder: (context, index) {
              final entry = _info!.entries.elementAt(index);
              final isLongValue = entry.value.length > 40;
              return ListTile(
                dense: true,
                title: Text(
                  entry.key,
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
                subtitle: isLongValue
                    ? SelectableText(
                        entry.value,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        maxLines: 3,
                      )
                    : null,
                trailing: isLongValue
                    ? CopyButton(text: entry.value)
                    : Text(
                        entry.value,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
              );
            },
          ),
        ),
      ],
    );
  }
}
