import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/logger.dart';
import '../providers/group_polling_provider.dart';
import '../providers/workgroups_provider.dart';
import '../models/helvar_models/workgroup.dart';
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
      logInfo('Initializing automatic power consumption polling...');

      final workgroups = ref.read(workgroupsProvider);

      if (workgroups.isEmpty) {
        logInfo('No workgroups found, polling initialization skipped');
        return;
      }

      final pollingNotifier = ref.read(pollingStateProvider.notifier);
      pollingNotifier.initializePolling();

      final enabledWorkgroups = workgroups
          .where((wg) => wg.pollEnabled)
          .toList();

      if (enabledWorkgroups.isNotEmpty) {
        logInfo(
          'Started automatic polling for ${enabledWorkgroups.length} workgroups:',
        );
        for (final wg in enabledWorkgroups) {
          logInfo('  - ${wg.description} (${wg.groups.length} groups)');
          for (final group in wg.groups) {
            logDebug(
              '    * Group ${group.groupId}: ${group.powerPollingMinutes} min interval',
            );
          }
        }
      } else {
        logInfo('No workgroups have polling enabled');
      }
    } catch (e) {
      logError('Error initializing polling: $e');
      // Don't rethrow - polling failure shouldn't prevent app startup
    }
  }

  static void setupPollingListener(WidgetRef ref) {
    ref.listen<List<Workgroup>>(workgroupsProvider, (previous, next) {
      if ((previous == null || previous.isEmpty) && next.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          initializePolling(ref);
        });
      }
    });
  }

  static Future<void> handleInitializationFailure(dynamic error) async {
    logError('Application initialization failed: $error');
  }
}
