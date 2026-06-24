import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/clipboard_provider.dart';
import '../widgets/clipboard_item.dart';
import '../widgets/merge_bar.dart';
import '../widgets/status_indicator.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通用剪切板'),
        actions: [
          IconButton(
            icon: const Icon(Icons.merge_type),
            onPressed: () {
              final provider = context.read<ClipboardProvider>();
              if (provider.isMergeMode) {
                provider.exitMergeMode();
              } else {
                provider.enterMergeMode();
              }
            },
            tooltip: '多选拼接',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ClipboardProvider>().refresh(),
            tooltip: '刷新',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            tooltip: '设置',
          ),
        ],
      ),
      body: Consumer<ClipboardProvider>(
        builder: (context, provider, _) {
          final history = provider.history;

          return Column(
            children: [
              const StatusIndicator(),
              if (history.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text('暂无剪切板历史\n复制内容后自动同步', textAlign: TextAlign.center),
                  ),
                )
              else
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => provider.refresh(),
                    child: ListView.builder(
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        final entry = history[index];
                        final isSelected = provider.selectedIds.contains(entry.id);
                        final orderList = provider.selectedIds.toList();
                        final order = isSelected ? orderList.indexOf(entry.id) + 1 : null;

                        return ClipboardItem(
                          entry: entry,
                          isMergeMode: provider.isMergeMode,
                          isSelected: isSelected,
                          selectionOrder: order,
                          onTap: provider.isMergeMode
                              ? () => provider.toggleSelection(entry.id)
                              : null,
                          onCopy: () => provider.copyEntry(entry.id),
                          onPin: () => provider.togglePin(entry.id),
                          onDelete: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('删除'),
                                content: const Text('确定要删除这条记录吗？'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
                                  TextButton(
                                    onPressed: () {
                                      provider.removeEntry(entry.id);
                                      Navigator.pop(ctx);
                                    },
                                    child: const Text('删除', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              const MergeBar(),
            ],
          );
        },
      ),
    );
  }
}
