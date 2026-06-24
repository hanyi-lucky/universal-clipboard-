import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/clipboard_provider.dart';

class MergeBar extends StatelessWidget {
  const MergeBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ClipboardProvider>(
      builder: (context, provider, _) {
        if (!provider.isMergeMode) return const SizedBox.shrink();

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text('分隔符:'),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: provider.mergeSeparator,
                    items: const [
                      DropdownMenuItem(value: '\n', child: Text('换行符')),
                      DropdownMenuItem(value: ',', child: Text('逗号')),
                      DropdownMenuItem(value: ';', child: Text('分号')),
                      DropdownMenuItem(value: ' ', child: Text('空格')),
                    ],
                    onChanged: (v) {
                      if (v != null) provider.setSeparator(v);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                constraints: const BoxConstraints(maxHeight: 80),
                child: SingleChildScrollView(
                  child: Text(
                    provider.mergePreview.isEmpty ? '选择条目查看拼接预览' : provider.mergePreview,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.copy),
                  label: Text('复制拼接内容 (${provider.selectedIds.length}条)'),
                  onPressed: provider.selectedIds.isEmpty
                      ? null
                      : () => provider.copyMerged(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
