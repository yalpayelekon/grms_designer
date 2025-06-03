import 'package:grms_designer/providers/centralized_polling_provider.dart';
import 'package:grms_designer/services/polling/polling_task.dart';
import 'package:grms_designer/utils/core/logger.dart';

import '../../providers/group_polling_provider.dart';
import '../../providers/centralized_polling_provider.dart';
import '../../providers/workgroups_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PollingMigrationHelper {
  static Future<void> migrateToNewPollingSystem(WidgetRef ref) async {
    try {
      logInfo('Starting migration to centralized polling system');

      final oldPollingState = ref.read(pollingStateProvider.notifier);
      final workgroups = ref.read(workgroupsProvider);

      for (final workgroup in workgroups) {
        if (oldPollingState.isPolling(workgroup.id)) {
          oldPollingState.stopPolling(workgroup.id);
        }
      }

      final newPollingManager = ref.read(pollingManagerProvider.notifier);

      for (final workgroup in workgroups) {
        if (workgroup.pollEnabled) {
          await newPollingManager.startWorkgroupPolling(workgroup.id);
        }
      }

      logInfo('Successfully migrated to centralized polling system');
    } catch (e, stackTrace) {
      logError('Error during polling migration: $e', stackTrace: stackTrace);
      rethrow;
    }
  }

  static bool needsMigration(WidgetRef ref) {
    try {
      final oldPollingState = ref.read(pollingStateProvider);
      final hasOldActiveTasks = oldPollingState.values.any(
        (isActive) => isActive,
      );

      final newPollingTasks = ref.read(pollingTasksProvider);
      final hasNewActiveTasks = newPollingTasks.values.any(
        (taskInfo) => taskInfo.state == PollingTaskState.running,
      );

      return hasOldActiveTasks && !hasNewActiveTasks;
    } catch (e) {
      logWarning('Could not determine migration status: $e');
      return true;
    }
  }
}
