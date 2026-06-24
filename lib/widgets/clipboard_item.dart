import 'package:flutter/material.dart';
import '../models/clipboard_entry.dart';

class ClipboardItem extends StatelessWidget {
  final ClipboardEntry entry;
  final bool isMergeMode;
  final bool isSelected;
  final int? selectionOrder;
  final VoidCallback? onTap;
  final VoidCallback? onCopy;
  final VoidCallback? onPin;
  final VoidCallback? onDelete;

  const ClipboardItem({
    super.key,
    required this.entry,
    this.isMergeMode = false,
    this.isSelected = false,
    this.selectionOrder,
    this.onTap,
    this.onCopy,
    this.onPin,
    this.onDelete,
  });

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inSeconds < 60) return '${diff.inSeconds}秒前';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    return '${diff.inDays}天前';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isMergeMode)
                    Checkbox(value: isSelected, onChanged: (_) => onTap?.call()),
                  if (selectionOrder != null)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$selectionOrder',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  Icon(Icons.content_copy, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '来自 ${entry.sourceDeviceName} · ${_formatTime(entry.timestamp)}',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (entry.isPinned)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(Icons.push_pin, size: 14, color: Colors.orange),
                    ),
                  if (!isMergeMode) ...[
                    IconButton(
                      icon: Icon(entry.isPinned ? Icons.push_pin : Icons.push_pin_outlined, size: 18),
                      onPressed: onPin, tooltip: '置顶',
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: onCopy, tooltip: '复制',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      onPressed: onDelete, tooltip: '删除',
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  entry.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
