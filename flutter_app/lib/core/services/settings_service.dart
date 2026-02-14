import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SyncConnectionMode {
  localDesktop,
  selfHostedBackend,
}

/// Service for managing application settings
class SettingsService extends ChangeNotifier {
  // SharedPreferences keys
  static const _keyThemeMode = 'theme_mode';
  static const _keyStoragePath = 'storage_path';
  static const _keyAutoStartServer = 'auto_start_server';
  static const _keyServerPort = 'server_port';
  static const _keyEnableMdns = 'enable_mdns';
  static const _keyDeviceName = 'device_name';
  static const _keySyncConnectionMode = 'sync_connection_mode';
  static const _keySyncBackendUrl = 'sync_backend_url';
  static const _keySyncBackendToken = 'sync_backend_token';

  ThemeMode _themeMode = ThemeMode.system;
  String _defaultStoragePath = '';
  bool _autoStartServer = true;
  int _serverPort = 8080;
  bool _enableMdns = true;
  String _deviceName = 'Sheet Music Reader';
  SyncConnectionMode _syncConnectionMode = SyncConnectionMode.localDesktop;
  String _syncBackendUrl = '';
  String _syncBackendToken = '';

  // Getters
  ThemeMode get themeMode => _themeMode;
  String get defaultStoragePath => _defaultStoragePath;
  bool get autoStartServer => _autoStartServer;
  int get serverPort => _serverPort;
  bool get enableMdns => _enableMdns;
  String get deviceName => _deviceName;
  SyncConnectionMode get syncConnectionMode => _syncConnectionMode;
  String get syncBackendUrl => _syncBackendUrl;
  String get syncBackendToken => _syncBackendToken;

  // Setters with persistence
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeMode, mode.index);
  }

  Future<void> setDefaultStoragePath(String path) async {
    _defaultStoragePath = path;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyStoragePath, path);
  }

  Future<void> setAutoStartServer(bool value) async {
    _autoStartServer = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoStartServer, value);
  }

  Future<void> setServerPort(int port) async {
    _serverPort = port;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyServerPort, port);
  }

  Future<void> setEnableMdns(bool value) async {
    _enableMdns = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnableMdns, value);
  }

  Future<void> setDeviceName(String name) async {
    _deviceName = name;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDeviceName, name);
  }

  Future<void> setSyncConnectionMode(SyncConnectionMode mode) async {
    _syncConnectionMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySyncConnectionMode, mode.index);
  }

  Future<void> setSyncBackendUrl(String url) async {
    _syncBackendUrl = url;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySyncBackendUrl, url);
  }

  Future<void> setSyncBackendToken(String token) async {
    _syncBackendToken = token;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySyncBackendToken, token);
  }

  /// Load settings from storage
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final themeModeIndex = prefs.getInt(_keyThemeMode);
    if (themeModeIndex != null && themeModeIndex < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[themeModeIndex];
    }

    final storagePath = prefs.getString(_keyStoragePath);
    if (storagePath != null) {
      _defaultStoragePath = storagePath;
    }

    final autoStart = prefs.getBool(_keyAutoStartServer);
    if (autoStart != null) {
      _autoStartServer = autoStart;
    }

    final port = prefs.getInt(_keyServerPort);
    if (port != null) {
      _serverPort = port;
    }

    final mdns = prefs.getBool(_keyEnableMdns);
    if (mdns != null) {
      _enableMdns = mdns;
    }

    final name = prefs.getString(_keyDeviceName);
    if (name != null) {
      _deviceName = name;
    }

    final modeIndex = prefs.getInt(_keySyncConnectionMode);
    if (modeIndex != null && modeIndex < SyncConnectionMode.values.length) {
      _syncConnectionMode = SyncConnectionMode.values[modeIndex];
    }

    final backendUrl = prefs.getString(_keySyncBackendUrl);
    if (backendUrl != null) {
      _syncBackendUrl = backendUrl;
    }

    final backendToken = prefs.getString(_keySyncBackendToken);
    if (backendToken != null) {
      _syncBackendToken = backendToken;
    }

    notifyListeners();
  }
}
