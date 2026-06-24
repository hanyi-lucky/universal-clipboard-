import 'package:flutter/material.dart';
import '../repositories/local_storage.dart';

class SettingsProvider extends ChangeNotifier {
  LocalStorage? _storage;

  bool _autoSync = true;
  int _historyLimit = 100;

  bool get autoSync => _autoSync;
  int get historyLimit => _historyLimit;

  Future<void> initialize(LocalStorage storage) async {
    _storage = storage;
    _autoSync = storage.autoSync;
    _historyLimit = storage.historyLimit;
    notifyListeners();
  }

  Future<void> setAutoSync(bool value) async {
    _autoSync = value;
    await _storage?.setAutoSync(value);
    notifyListeners();
  }

  Future<void> setHistoryLimit(int value) async {
    _historyLimit = value;
    await _storage?.setHistoryLimit(value);
    notifyListeners();
  }
}
