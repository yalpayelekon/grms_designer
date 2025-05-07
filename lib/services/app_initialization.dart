import 'dart:async';
import '../utils/logger.dart';
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

  static Future<void> handleInitializationFailure(dynamic error) async {
    logError('Application initialization failed: $error');
  }
}
