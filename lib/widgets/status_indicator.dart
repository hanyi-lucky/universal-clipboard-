import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/clipboard_provider.dart';

class StatusIndicator extends StatelessWidget {
  const StatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ClipboardProvider>(
      builder: (context, provider, _) {
        final status = provider.syncStatus;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: status.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.circle, size: 8, color: status.color),
              const SizedBox(width: 8),
              Text(status.label, style: TextStyle(color: status.color, fontSize: 13)),
              if (status == SyncStatus.error && provider.errorMessage != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => provider.refresh(),
                  child: const Text('重试', style: TextStyle(fontSize: 13)),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
