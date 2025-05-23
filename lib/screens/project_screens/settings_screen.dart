import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Appearance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Theme'),
                    subtitle: Text(_getThemeModeName(themeMode)),
                    trailing: const Icon(Icons.brightness_4),
                    onTap: () => _showThemeModeDialog(context, ref, themeMode),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  void _showThemeModeDialog(
      BuildContext context, WidgetRef ref, ThemeMode currentMode) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choose Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildThemeOption(context, ref, ThemeMode.system, currentMode),
              _buildThemeOption(context, ref, ThemeMode.light, currentMode),
              _buildThemeOption(context, ref, ThemeMode.dark, currentMode),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(BuildContext context, WidgetRef ref, ThemeMode mode,
      ThemeMode currentMode) {
    return RadioListTile<ThemeMode>(
      title: Text(_getThemeModeName(mode)),
      value: mode,
      groupValue: currentMode,
      onChanged: (ThemeMode? value) {
        if (value != null) {
          ref.read(settingsProvider.notifier).setThemeMode(value);
          Navigator.of(context).pop();
        }
      },
    );
  }
}
