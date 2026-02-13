import 'package:flutter/material.dart';

/// Service for managing application settings
class SettingsService extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  String _defaultStoragePath = '';
  bool _autoStartServer = true;
  int _serverPort = 8080;
  bool _enableMdns = true;
  String _deviceName = 'Sheet Music Reader';

  // Getters
  ThemeMode get themeMode => _themeMode;
  String get defaultStoragePath => _defaultStoragePath;
  bool get autoStartServer => _autoStartServer;
  int get serverPort => _serverPort;
  bool get enableMdns => _enableMdns;
  String get deviceName => _deviceName;

  // Setters with persistence
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    // TODO: Persist to SharedPreferences
  }

  Future<void> setDefaultStoragePath(String path) async {
    _defaultStoragePath = path;
    notifyListeners();
    // TODO: Persist to SharedPreferences
  }

  Future<void> setAutoStartServer(bool value) async {
    _autoStartServer = value;
    notifyListeners();
    // TODO: Persist to SharedPreferences
  }

  Future<void> setServerPort(int port) async {
    _serverPort = port;
    notifyListeners();
    // TODO: Persist to SharedPreferences
  }

  Future<void> setEnableMdns(bool value) async {
    _enableMdns = value;
    notifyListeners();
    // TODO: Persist to SharedPreferences
  }

  Future<void> setDeviceName(String name) async {
    _deviceName = name;
    notifyListeners();
    // TODO: Persist to SharedPreferences
  }

  /// Load settings from storage
  Future<void> loadSettings() async {
    // TODO: Load from SharedPreferences
    notifyListeners();
  }
}
