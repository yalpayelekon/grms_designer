import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grms_designer/providers/centralized_polling_provider.dart';
import '../utils/core/logger.dart';
import '../providers/workgroups_provider.dart';
import 'app_directory_service.dart';

class AppInitializationService {
  static Future<void> initialize() async {
    try {
      await _initializeDirectories();
    } catch (e) {
      logError('Error during application initialization: $e');
      rethrow;
    }
  }

  static Future<void> _initializeDirectories() async {
    final directoryService = AppDirectoryService();
    await directoryService.initialize();
    logInfo('Application directories initialized successfully');
  }

  static Future<void> initializePolling(WidgetRef ref) async {
    try {
      logInfo('Initializing centralized power consumption polling...');

      final workgroups = ref.read(workgroupsProvider);

      if (workgroups.isEmpty) {
        logInfo('No workgroups found, polling initialization skipped');
        return;
      }

      final pollingManager = ref.read(pollingManagerProvider.notifier);

      final enabledWorkgroups = workgroups
          .where((wg) => wg.pollEnabled)
          .toList();

      if (enabledWorkgroups.isNotEmpty) {
        logInfo(
          'Starting centralized polling for ${enabledWorkgroups.length} workgroups:',
        );

        for (final wg in enabledWorkgroups) {
          try {
            await pollingManager.startWorkgroupPolling(wg.id);
            logInfo('  - ${wg.description} (${wg.groups.length} groups)');

            for (final group in wg.groups) {
              logDebug(
                '    * Group ${group.groupId}: ${group.powerPollingMinutes} min interval',
              );
            }
          } catch (e) {
            logError(
              'Failed to start polling for workgroup ${wg.description}: $e',
            );
          }
        }
      } else {
        logInfo('No workgroups have polling enabled');
      }
    } catch (e) {
      logError('Error initializing centralized polling: $e');
    }
  }

  static void setupPollingListener(WidgetRef ref) {
    try {
      logInfo('Initializing centralized polling system');
      final pollingManager = ref.read(pollingManagerProvider.notifier);
      _initializeCentralizedPolling(ref, pollingManager);
    } catch (e, stackTrace) {
      logError(
        'Error in centralized polling setup: $e',
        stackTrace: stackTrace,
      );
    }
  }

  static void _initializeCentralizedPolling(
    WidgetRef ref,
    PollingManager pollingManager,
  ) {
    final workgroups = ref.read(workgroupsProvider);

    for (final workgroup in workgroups) {
      if (workgroup.pollEnabled) {
        try {
          pollingManager.startWorkgroupPolling(workgroup.id);
          logInfo(
            'Started centralized polling for workgroup: ${workgroup.description}',
          );
        } catch (e) {
          logError('Failed to start polling for workgroup ${workgroup.id}: $e');
        }
      }
    }
  }

  static Future<void> handleInitializationFailure(dynamic error) async {
    logError('Application initialization failed: $error');
  }
}
