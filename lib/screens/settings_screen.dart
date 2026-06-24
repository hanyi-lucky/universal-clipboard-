import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return ListView(
            children: [
              _buildSection(context, '同步设置', [
                SwitchListTile(
                  title: const Text('自动同步'),
                  value: settings.autoSync,
                  onChanged: (v) => settings.setAutoSync(v),
                ),
                ListTile(
                  title: const Text('历史记录保留'),
                  subtitle: Text('${settings.historyLimit}条'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: settings.historyLimit > 10
                            ? () => settings.setHistoryLimit(settings.historyLimit - 10)
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: settings.historyLimit < 500
                            ? () => settings.setHistoryLimit(settings.historyLimit + 10)
                            : null,
                      ),
                    ],
                  ),
                ),
              ]),
              _buildSection(context, '关于', [
                const ListTile(
                  title: Text('版本'),
                  subtitle: Text('1.0.0'),
                ),
              ]),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey),
          ),
        ),
        ...children,
        const Divider(),
      ],
    );
  }
}
