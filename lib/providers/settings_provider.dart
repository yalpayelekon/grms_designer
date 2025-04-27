// lib/providers/settings_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  final ThemeMode themeMode;
  final int discoveryTimeoutMs;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.discoveryTimeoutMs = 15000,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    int? discoveryTimeoutMs,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      discoveryTimeoutMs: discoveryTimeoutMs ?? this.discoveryTimeoutMs,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeIndex = prefs.getInt('themeMode') ?? ThemeMode.system.index;
    final discoveryTimeout = prefs.getInt('discoveryTimeout') ?? 15000;

    state = state.copyWith(
      themeMode: ThemeMode.values[themeModeIndex],
      discoveryTimeoutMs: discoveryTimeout,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
  }

  Future<void> setDiscoveryTimeout(int timeoutMs) async {
    state = state.copyWith(discoveryTimeoutMs: timeoutMs);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('discoveryTimeout', timeoutMs);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsProvider).themeMode;
});

final discoveryTimeoutProvider = Provider<int>((ref) {
  return ref.watch(settingsProvider).discoveryTimeoutMs;
});
