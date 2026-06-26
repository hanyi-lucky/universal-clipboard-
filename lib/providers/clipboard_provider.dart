import 'dart:async';
import 'dart:io' show Platform;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/clipboard_entry.dart';
import '../services/sync_service.dart';
import '../services/encryption_service.dart';
import '../services/history_service.dart';
import '../services/clipboard_monitor.dart';
import '../repositories/local_storage.dart';
import '../repositories/cloud_repository.dart';
import '../core/constants.dart';

enum SyncStatus {
  connected('已连接', Colors.green),
  syncing('同步中...', Colors.orange),
  error('同步失败', Colors.red),
  disconnected('未连接', Colors.grey),
  paused('已暂停同步', Colors.blueGrey);

  final String label;
  final Color color;
  const SyncStatus(this.label, this.color);
}

class ClipboardProvider extends ChangeNotifier {
  final HistoryService _historyService = HistoryService(maxEntries: AppConstants.maxHistoryEntries);
  final EncryptionService _encryption = EncryptionService();

  ClipboardMonitor? _monitor;
  SyncService? _syncService;
  CloudRepository? _cloudRepo;
  LocalStorage? _storage;

  SyncStatus _syncStatus = SyncStatus.disconnected;
  String? _errorMessage;
  bool _isMergeMode = false;
  final Set<String> _selectedIds = {};
  String _mergeSeparator = '\n';
  Timer? _uploadDebounce;
  Timer? _syncTimer;

  List<ClipboardEntry> get history => _historyService.entries;
  SyncStatus get syncStatus => _syncStatus;
  String? get errorMessage => _errorMessage;
  bool get isMergeMode => _isMergeMode;
  Set<String> get selectedIds => Set.unmodifiable(_selectedIds);
  String get mergeSeparator => _mergeSeparator;

  List<ClipboardEntry> get selectedEntries {
    final entries = _historyService.entries.where((e) => _selectedIds.contains(e.id)).toList();
    entries.sort((a, b) {
      final orderA = _selectedIds.toList().indexOf(a.id);
      final orderB = _selectedIds.toList().indexOf(b.id);
      return orderA.compareTo(orderB);
    });
    return entries;
  }

  String get mergePreview =>
      selectedEntries.map((e) => e.content).join(_mergeSeparator);

  Future<void> initialize({
    required LocalStorage storage,
    required CloudRepository cloudRepo,
    required String deviceId,
    required String deviceName,
    required Uint8List encryptionKey,
  }) async {
    _storage = storage;
    _cloudRepo = cloudRepo;

    final savedHistory = storage.historyJson;
    if (savedHistory != null) {
      _historyService.fromJson(savedHistory);
    }

    _syncService = SyncService(
      repo: cloudRepo,
      encryption: _encryption,
      deviceId: deviceId,
      deviceName: deviceName,
      devicePlatform: Platform.operatingSystem,
      key: encryptionKey,
    );

    _monitor = ClipboardMonitor(onChanged: _onClipboardChanged);
    await _monitor!.start();

    _startSyncLoop();
    notifyListeners();
  }

  void _onClipboardChanged(String content) {
    _uploadDebounce?.cancel();
    _uploadDebounce = Timer(AppConstants.uploadDebounce, () {
      _uploadContent(content);
    });
  }

  Future<void> _uploadContent(String content) async {
    if (_syncService == null) return;
    _setStatus(SyncStatus.syncing);

    try {
      await _syncService!.uploadContent(content);

      _historyService.addEntry(ClipboardEntry(
        id: const Uuid().v4(),
        content: content,
        sourceDeviceId: 'local',
        sourceDeviceName: '本设备',
        sourcePlatform: Platform.operatingSystem,
        timestamp: DateTime.now(),
        type: ContentType.text,
      ));

      await _saveHistory();
      _setStatus(SyncStatus.connected);
    } catch (e) {
      _errorMessage = e.toString();
      _setStatus(SyncStatus.error);
    }
  }

  void _startSyncLoop() {
    _syncTimer = Timer.periodic(AppConstants.pollInterval, (_) async {
      if (_syncService == null || _cloudRepo == null) return;
      if (_syncStatus == SyncStatus.paused) return;

      try {
        final content = await _syncService!.downloadLatestContent();
        if (content != null && content.isNotEmpty) {
          _monitor?.pause();
          await Clipboard.setData(ClipboardData(text: content));
          await Future.delayed(const Duration(milliseconds: 100));
          _monitor?.resume();

          final current = await _cloudRepo!.getCurrentClipboard();
          if (current != null) {
            _historyService.addEntry(ClipboardEntry(
              id: const Uuid().v4(),
              content: content,
              sourceDeviceId: current['sourceDevice'] as String? ?? 'unknown',
              sourceDeviceName: current['sourceDeviceName'] as String? ?? 'Unknown',
              sourcePlatform: current['sourcePlatform'] as String? ?? 'unknown',
              timestamp: DateTime.fromMillisecondsSinceEpoch(current['timestamp'] as int),
              type: ContentType.text,
            ));
            await _saveHistory();
          }
        }
        _setStatus(SyncStatus.connected);
      } catch (e) {
        _errorMessage = e.toString();
        _setStatus(SyncStatus.error);
      }
    });
  }

  Future<void> refresh() async {
    _setStatus(SyncStatus.syncing);
    if (_syncService != null) {
      try {
        final content = await _syncService!.downloadLatestContent();
        if (content != null && content.isNotEmpty) {
          _monitor?.pause();
          await Clipboard.setData(ClipboardData(text: content));
          await Future.delayed(const Duration(milliseconds: 100));
          _monitor?.resume();
        }
        _setStatus(SyncStatus.connected);
      } catch (e) {
        _errorMessage = e.toString();
        _setStatus(SyncStatus.error);
      }
    }
    notifyListeners();
  }

  Future<void> copyEntry(String id) async {
    final entry = _historyService.entries.firstWhere((e) => e.id == id);
    _monitor?.pause();
    await Clipboard.setData(ClipboardData(text: entry.content));
    await Future.delayed(const Duration(milliseconds: 100));
    _monitor?.resume();
  }

  void togglePin(String id) {
    _historyService.togglePin(id);
    notifyListeners();
  }

  void removeEntry(String id) {
    _historyService.removeEntry(id);
    _selectedIds.remove(id);
    notifyListeners();
  }

  void enterMergeMode() {
    _isMergeMode = true;
    notifyListeners();
  }

  void exitMergeMode() {
    _isMergeMode = false;
    _selectedIds.clear();
    notifyListeners();
  }

  void toggleSelection(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  void selectAll() {
    _selectedIds.addAll(_historyService.entries.map((e) => e.id));
    notifyListeners();
  }

  void setSeparator(String separator) {
    _mergeSeparator = separator;
    notifyListeners();
  }

  Future<void> copyMerged() async {
    final merged = mergePreview;
    _monitor?.pause();
    await Clipboard.setData(ClipboardData(text: merged));
    await Future.delayed(const Duration(milliseconds: 100));
    _monitor?.resume();
    exitMergeMode();
  }

  void _setStatus(SyncStatus status) {
    if (_syncStatus != status) {
      _syncStatus = status;
      notifyListeners();
    }
  }

  Future<void> _saveHistory() async {
    await _storage?.setHistoryJson(_historyService.toJson());
  }

  @override
  void dispose() {
    _uploadDebounce?.cancel();
    _syncTimer?.cancel();
    _monitor?.stop();
    super.dispose();
  }
}
