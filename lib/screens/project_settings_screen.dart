import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/project_settings_provider.dart';

class ProjectSettingsScreen extends ConsumerWidget {
  const ProjectSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectSettings = ref.watch(projectSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Settings'),
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
                    'Project',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Project Name'),
                    subtitle: Text(projectSettings.projectName),
                    trailing: const Icon(Icons.edit),
                    onTap: () => _showProjectNameDialog(
                        context, ref, projectSettings.projectName),
                  ),
                ],
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Connection',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Socket Timeout'),
                    subtitle: Text(
                        '${projectSettings.socketTimeoutMs / 1000} seconds'),
                    trailing: const Icon(Icons.timer),
                    onTap: () => _showSocketTimeoutDialog(
                        context, ref, projectSettings.socketTimeoutMs),
                  ),
                ],
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Auto Save',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Auto Save Enabled'),
                    value: projectSettings.autoSave,
                    onChanged: (value) {
                      ref
                          .read(projectSettingsProvider.notifier)
                          .setAutoSave(value);
                    },
                  ),
                  ListTile(
                    title: const Text('Auto Save Interval'),
                    subtitle: Text(
                        '${projectSettings.autoSaveIntervalMinutes} minutes'),
                    trailing: const Icon(Icons.timelapse),
                    enabled: projectSettings.autoSave,
                    onTap: projectSettings.autoSave
                        ? () => _showAutoSaveIntervalDialog(context, ref,
                            projectSettings.autoSaveIntervalMinutes)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showProjectNameDialog(
      BuildContext context, WidgetRef ref, String currentName) {
    final nameController = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Project Name'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final newName = nameController.text.trim();
                if (newName.isNotEmpty) {
                  ref
                      .read(projectSettingsProvider.notifier)
                      .setProjectName(newName);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showSocketTimeoutDialog(
      BuildContext context, WidgetRef ref, int currentTimeout) {
    double timeoutInSec = currentTimeout / 1000;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Socket Timeout'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${timeoutInSec.toStringAsFixed(1)} seconds'),
                  Slider(
                    min: 1.0,
                    max: 60.0,
                    divisions: 59,
                    value: timeoutInSec,
                    onChanged: (value) {
                      setState(() {
                        timeoutInSec = value;
                      });
                    },
                  ),
                  const Text(
                    'Longer timeouts may be needed for slower networks.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final timeoutMs = (timeoutInSec * 1000).round();
                    ref
                        .read(projectSettingsProvider.notifier)
                        .setSocketTimeout(timeoutMs);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAutoSaveIntervalDialog(
      BuildContext context, WidgetRef ref, int currentInterval) {
    final intervalController =
        TextEditingController(text: currentInterval.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Auto Save Interval'),
          content: TextField(
            controller: intervalController,
            decoration: const InputDecoration(
              labelText: 'Minutes',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final String text = intervalController.text.trim();
                final int? minutes = int.tryParse(text);
                if (minutes != null && minutes > 0) {
                  ref
                      .read(projectSettingsProvider.notifier)
                      .setAutoSaveInterval(minutes);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
