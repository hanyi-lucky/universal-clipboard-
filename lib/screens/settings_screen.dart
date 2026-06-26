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
              _buildSection(context, '外观', [
                _buildThemeTile(context, settings, ThemeMode.system, '跟随系统', Icons.brightness_auto),
                _buildThemeTile(context, settings, ThemeMode.light, '浅色模式', Icons.light_mode),
                _buildThemeTile(context, settings, ThemeMode.dark, '深色模式', Icons.dark_mode),
              ]),
              _buildSection(context, '同步设置', [
                SwitchListTile(
                  title: const Text('自动同步'),
                  subtitle: const Text('检测到新内容时自动同步到云端'),
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
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: settings.historyLimit > 10
                            ? () => settings.setHistoryLimit(settings.historyLimit - 10)
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
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
                  leading: Icon(Icons.info_outline),
                ),
                ListTile(
                  title: const Text('开源协议'),
                  subtitle: const Text('MIT License'),
                  leading: const Icon(Icons.code),
                ),
              ]),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildThemeTile(
    BuildContext context,
    SettingsProvider settings,
    ThemeMode mode,
    String label,
    IconData icon,
  ) {
    final isSelected = settings.themeMode == mode;
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: () => settings.setThemeMode(mode),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...children,
        const Divider(height: 1),
      ],
    );
  }
}
