import 'package:flutter/material.dart';
import '../repositories/local_storage.dart';

class SettingsProvider extends ChangeNotifier {
  LocalStorage? _storage;

  bool _autoSync = true;
  int _historyLimit = 100;
  ThemeMode _themeMode = ThemeMode.system;

  bool get autoSync => _autoSync;
  int get historyLimit => _historyLimit;
  ThemeMode get themeMode => _themeMode;

  Future<void> initialize(LocalStorage storage) async {
    _storage = storage;
    _autoSync = storage.autoSync;
    _historyLimit = storage.historyLimit;
    _themeMode = storage.themeMode;
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

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _storage?.setThemeMode(mode);
    notifyListeners();
  }
}
