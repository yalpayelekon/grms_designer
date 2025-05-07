import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/project_settings_provider.dart';
import '../../providers/settings_provider.dart';

class ProjectSettingsScreen extends ConsumerWidget {
  const ProjectSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectSettings = ref.watch(projectSettingsProvider);
    final discoveryTimeout = ref.watch(discoveryTimeoutProvider);

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
                    'Router Connection',
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
                  ListTile(
                    title: const Text('Discovery Timeout'),
                    subtitle: Text('${discoveryTimeout / 1000} seconds'),
                    trailing: const Icon(Icons.timer_outlined),
                    onTap: () => _showDiscoveryTimeoutDialog(
                        context, ref, discoveryTimeout),
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
                  ListTile(
                    title: const Text('Protocol Version'),
                    subtitle: Text('${projectSettings.protocolVersion}'),
                    trailing: const Icon(Icons.sync),
                    onTap: () => _showProtocolVersionDialog(
                        context, ref, projectSettings.protocolVersion),
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
                    'Command Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Command Timeout'),
                    subtitle: Text(
                        '${projectSettings.commandTimeoutMs / 1000} seconds'),
                    trailing: const Icon(Icons.timer),
                    onTap: () => _showCommandTimeoutDialog(
                        context, ref, projectSettings.commandTimeoutMs),
                  ),
                  ListTile(
                    title: const Text('Heartbeat Interval'),
                    subtitle: Text(
                        '${projectSettings.heartbeatIntervalSeconds} seconds'),
                    trailing: const Icon(Icons.favorite),
                    onTap: () => _showHeartbeatIntervalDialog(
                        context, ref, projectSettings.heartbeatIntervalSeconds),
                  ),
                  ListTile(
                    title: const Text('Max Command Retries'),
                    subtitle: Text('${projectSettings.maxCommandRetries}'),
                    trailing: const Icon(Icons.replay),
                    onTap: () => _showMaxRetriesDialog(
                        context, ref, projectSettings.maxCommandRetries),
                  ),
                  ListTile(
                    title: const Text('Max Concurrent Commands'),
                    subtitle: Text(
                        '${projectSettings.maxConcurrentCommandsPerRouter}'),
                    trailing: const Icon(Icons.call_split),
                    onTap: () => _showMaxConcurrentCommandsDialog(context, ref,
                        projectSettings.maxConcurrentCommandsPerRouter),
                  ),
                  ListTile(
                    title: const Text('Command History Size'),
                    subtitle:
                        Text('${projectSettings.commandHistorySize} entries'),
                    trailing: const Icon(Icons.history),
                    onTap: () => _showCommandHistorySizeDialog(
                        context, ref, projectSettings.commandHistorySize),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showProtocolVersionDialog(
      BuildContext context, WidgetRef ref, int currentVersion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Protocol Version'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select HelvarNet protocol version:'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: currentVersion == 1 ? Colors.blue : null,
                    foregroundColor: currentVersion == 1 ? Colors.white : null,
                  ),
                  onPressed: () {
                    ref
                        .read(projectSettingsProvider.notifier)
                        .setProtocolVersion(1);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Version 1'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: currentVersion == 2 ? Colors.blue : null,
                    foregroundColor: currentVersion == 2 ? Colors.white : null,
                  ),
                  onPressed: () {
                    ref
                        .read(projectSettingsProvider.notifier)
                        .setProtocolVersion(2);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Version 2'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Version 2 is recommended for newer systems. Only use Version 1 for legacy compatibility.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showCommandTimeoutDialog(
      BuildContext context, WidgetRef ref, int currentTimeout) {
    double timeoutInSec = currentTimeout / 1000;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Command Timeout'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${timeoutInSec.toStringAsFixed(1)} seconds'),
                  Slider(
                    min: 1.0,
                    max: 30.0,
                    divisions: 29,
                    value: timeoutInSec,
                    onChanged: (value) {
                      setState(() {
                        timeoutInSec = value;
                      });
                    },
                  ),
                  const Text(
                    'Longer timeouts give more time for commands to complete but may make the application less responsive if a command fails.',
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
                        .setCommandTimeout(timeoutMs);
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

  void _showDiscoveryTimeoutDialog(
      BuildContext context, WidgetRef ref, int currentTimeout) {
    double timeoutInSec = currentTimeout / 1000;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Discovery Timeout'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${timeoutInSec.toStringAsFixed(1)} seconds'),
                  Slider(
                    min: 1.0,
                    max: 30.0,
                    divisions: 29,
                    value: timeoutInSec,
                    onChanged: (value) {
                      setState(() {
                        timeoutInSec = value;
                      });
                    },
                  ),
                  const Text(
                    'Longer timeouts may find more devices but will take longer to complete.',
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
                        .read(settingsProvider.notifier)
                        .setDiscoveryTimeout(timeoutMs);
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

  void _showHeartbeatIntervalDialog(
      BuildContext context, WidgetRef ref, int heartbeatIntervalSeconds) {
    double intervalInSec = heartbeatIntervalSeconds.toDouble();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Heartbeat Interval'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${intervalInSec.toStringAsFixed(0)} seconds'),
                  Slider(
                    min: 5.0,
                    max: 300.0,
                    divisions: 59,
                    value: intervalInSec,
                    onChanged: (value) {
                      setState(() {
                        intervalInSec = value;
                      });
                    },
                  ),
                  const Text(
                    'The heartbeat interval determines how often the application checks if router connections are still alive.',
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
                    final interval = intervalInSec.round();
                    ref
                        .read(projectSettingsProvider.notifier)
                        .setHeartbeatInterval(interval);
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

  void _showMaxRetriesDialog(
      BuildContext context, WidgetRef ref, int maxCommandRetries) {
    final retriesController =
        TextEditingController(text: maxCommandRetries.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Max Command Retries'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: retriesController,
                decoration: const InputDecoration(
                  labelText: 'Retries',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              const Text(
                'Maximum number of times to retry a failed command before giving up.',
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
                final String text = retriesController.text.trim();
                final int? retries = int.tryParse(text);
                if (retries != null && retries >= 0) {
                  ref
                      .read(projectSettingsProvider.notifier)
                      .setMaxCommandRetries(retries);
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

  void _showMaxConcurrentCommandsDialog(
      BuildContext context, WidgetRef ref, int maxConcurrentCommandsPerRouter) {
    final commandsController =
        TextEditingController(text: maxConcurrentCommandsPerRouter.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Max Concurrent Commands'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: commandsController,
                decoration: const InputDecoration(
                  labelText: 'Commands',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              const Text(
                'Maximum number of commands that can be executed simultaneously on a single router.',
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
                final String text = commandsController.text.trim();
                final int? commands = int.tryParse(text);
                if (commands != null && commands > 0) {
                  ref
                      .read(projectSettingsProvider.notifier)
                      .setMaxConcurrentCommands(commands);
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

  void _showCommandHistorySizeDialog(
      BuildContext context, WidgetRef ref, int commandHistorySize) {
    final historySizeController =
        TextEditingController(text: commandHistorySize.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Command History Size'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: historySizeController,
                decoration: const InputDecoration(
                  labelText: 'History Size',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              const Text(
                'Number of commands to keep in the history. Older commands will be removed when this limit is reached.',
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
                final String text = historySizeController.text.trim();
                final int? size = int.tryParse(text);
                if (size != null && size > 0) {
                  ref
                      .read(projectSettingsProvider.notifier)
                      .setCommandHistorySize(size);
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
