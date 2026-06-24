import 'dart:convert';
import '../models/clipboard_entry.dart';

class HistoryService {
  final int maxEntries;
  final List<ClipboardEntry> _entries = [];

  List<ClipboardEntry> get entries => List.unmodifiable(_entries);

  HistoryService({required this.maxEntries});

  void addEntry(ClipboardEntry entry) {
    final existingIndex = _entries.indexWhere(
      (e) => e.content.trim() == entry.content.trim(),
    );

    if (existingIndex >= 0) {
      final existing = _entries[existingIndex];
      _entries[existingIndex] = existing.copyWith(
        timestamp: entry.timestamp,
        sourceDeviceId: entry.sourceDeviceId,
        sourceDeviceName: entry.sourceDeviceName,
      );
      if (existingIndex != 0) {
        final moved = _entries.removeAt(existingIndex);
        _entries.insert(0, moved);
      }
    } else {
      _entries.insert(0, entry);
      _trim();
    }
  }

  void removeEntry(String id) {
    _entries.removeWhere((e) => e.id == id);
  }

  void togglePin(String id) {
    final index = _entries.indexWhere((e) => e.id == id);
    if (index >= 0) {
      _entries[index] = _entries[index].copyWith(isPinned: !_entries[index].isPinned);
    }
  }

  void _trim() {
    while (_entries.where((e) => !e.isPinned).length > maxEntries) {
      int lastIdx = -1;
      for (int i = _entries.length - 1; i >= 0; i--) {
        if (!_entries[i].isPinned) {
          lastIdx = i;
          break;
        }
      }
      if (lastIdx >= 0) {
        _entries.removeAt(lastIdx);
      } else {
        break;
      }
    }
  }

  String toJson() {
    return json.encode(_entries.map((e) => e.toMap()).toList());
  }

  void fromJson(String jsonString) {
    final list = jsonDecode(jsonString) as List;
    _entries.clear();
    for (final map in list) {
      _entries.add(ClipboardEntry.fromMap(map as Map<String, dynamic>));
    }
  }

  void clear() {
    _entries.clear();
  }
}
