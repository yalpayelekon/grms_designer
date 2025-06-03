import 'dart:io';
import 'package:grms_designer/utils/core/logger.dart';

import 'polling_task.dart';

class SystemHealthPollingTask extends PollingTask {
  final Function(Map<String, dynamic> healthData)? onHealthUpdated;

  SystemHealthPollingTask({
    this.onHealthUpdated,
    super.interval = const Duration(minutes: 1),
  }) : super(id: 'system_health', name: 'System Health Monitor');

  @override
  Future<PollingResult> execute() async {
    try {
      final healthData = <String, dynamic>{};

      // Memory usage (simplified - you might want to use a proper system monitoring package)
      final processInfo = await Process.run('powershell', [
        'Get-Process -Name "${Platform.resolvedExecutable.split(Platform.pathSeparator).last.replaceAll('.exe', '')}" | Select-Object WorkingSet64,PagedMemorySize64',
      ]);

      if (processInfo.exitCode == 0) {
        // Parse memory info from PowerShell output
        healthData['memoryUsageMB'] = 'Available on Windows';
      }

      // Network connectivity check
      try {
        final result = await InternetAddress.lookup('google.com');
        healthData['internetConnected'] = result.isNotEmpty;
      } catch (e) {
        healthData['internetConnected'] = false;
      }

      // App-specific metrics
      healthData['timestamp'] = DateTime.now().toIso8601String();
      healthData['uptime'] = DateTime.now()
          .difference(DateTime.now())
          .inMinutes; // This would be actual app start time

      // Notify callback
      onHealthUpdated?.call(healthData);

      return PollingResult.success(healthData);
    } catch (e) {
      return PollingResult.failure('Error collecting system health data: $e');
    }
  }

  @override
  void onStart() {
    logInfo('Started system health monitoring');
  }

  @override
  void onStop() {
    logInfo('Stopped system health monitoring');
  }
}
