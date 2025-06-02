import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/app_directory_service.dart';
import '../utils/core/logger.dart';

class AppSettings {
  final ThemeMode themeMode;
  final int discoveryTimeoutMs;
  final bool autoSaveEnabled;
  final int autoSaveIntervalMinutes;
  final String defaultExportDirectory;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.discoveryTimeoutMs = 10000,
    this.autoSaveEnabled = true,
    this.autoSaveIntervalMinutes = 5,
    this.defaultExportDirectory = '',
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    int? discoveryTimeoutMs,
    bool? autoSaveEnabled,
    int? autoSaveIntervalMinutes,
    String? defaultExportDirectory,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      discoveryTimeoutMs: discoveryTimeoutMs ?? this.discoveryTimeoutMs,
      autoSaveEnabled: autoSaveEnabled ?? this.autoSaveEnabled,
      autoSaveIntervalMinutes:
          autoSaveIntervalMinutes ?? this.autoSaveIntervalMinutes,
      defaultExportDirectory:
          defaultExportDirectory ?? this.defaultExportDirectory,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.index,
      'discoveryTimeoutMs': discoveryTimeoutMs,
      'autoSaveEnabled': autoSaveEnabled,
      'autoSaveIntervalMinutes': autoSaveIntervalMinutes,
      'defaultExportDirectory': defaultExportDirectory,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode:
          ThemeMode.values[json['themeMode'] as int? ?? ThemeMode.system.index],
      discoveryTimeoutMs: json['discoveryTimeoutMs'] as int? ?? 10000,
      autoSaveEnabled: json['autoSaveEnabled'] as bool? ?? true,
      autoSaveIntervalMinutes: json['autoSaveIntervalMinutes'] as int? ?? 5,
      defaultExportDirectory: json['defaultExportDirectory'] as String? ?? '',
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  final AppDirectoryService _directoryService = AppDirectoryService();
  static const String _settingsFileName = 'app_settings.json';

  SettingsNotifier() : super(const AppSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final filePath = await _directoryService.getSettingsFilePath(
        _settingsFileName,
      );
      final file = File(filePath);

      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final json = jsonDecode(jsonString);

        state = AppSettings.fromJson(json);
      }
    } catch (e) {
      logError('Error loading settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final filePath = await _directoryService.getSettingsFilePath(
        _settingsFileName,
      );
      final file = File(filePath);

      final jsonString = jsonEncode(state.toJson());
      await file.writeAsString(jsonString);

      logInfo('Settings saved to: $filePath');
    } catch (e) {
      logError('Error saving settings: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _saveSettings();
  }

  Future<void> setDiscoveryTimeout(int timeoutMs) async {
    state = state.copyWith(discoveryTimeoutMs: timeoutMs);
    await _saveSettings();
  }

  Future<void> setAutoSaveEnabled(bool enabled) async {
    state = state.copyWith(autoSaveEnabled: enabled);
    await _saveSettings();
  }

  Future<void> setAutoSaveInterval(int minutes) async {
    state = state.copyWith(autoSaveIntervalMinutes: minutes);
    await _saveSettings();
  }

  Future<void> setDefaultExportDirectory(String directory) async {
    state = state.copyWith(defaultExportDirectory: directory);
    await _saveSettings();
  }

  Future<String?> createSettingsBackup() async {
    try {
      return _directoryService.createBackup(
        AppDirectoryService.settingsDir,
        _settingsFileName,
      );
    } catch (e) {
      logError('Error creating settings backup: $e');
      return null;
    }
  }

  Future<bool> restoreSettingsFromBackup(String backupFileName) async {
    try {
      final backupFilePath = await _directoryService.getBackupFilePath(
        backupFileName,
      );
      final backupFile = File(backupFilePath);

      if (!await backupFile.exists()) {
        return false;
      }

      final jsonString = await backupFile.readAsString();
      final json = jsonDecode(jsonString);

      state = AppSettings.fromJson(json);
      await _saveSettings();

      return true;
    } catch (e) {
      logError('Error restoring settings from backup: $e');
      return false;
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((
  ref,
) {
  return SettingsNotifier();
});

final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsProvider).themeMode;
});

final discoveryTimeoutProvider = Provider<int>((ref) {
  return ref.watch(settingsProvider).discoveryTimeoutMs;
});

final autoSaveEnabledProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).autoSaveEnabled;
});

final autoSaveIntervalProvider = Provider<int>((ref) {
  return ref.watch(settingsProvider).autoSaveIntervalMinutes;
});
