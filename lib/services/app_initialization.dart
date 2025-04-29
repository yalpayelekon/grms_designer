import 'dart:async';
import 'package:flutter/foundation.dart';
import 'app_directory_service.dart';

class AppInitializationService {
  static Future<void> initialize() async {
    try {
      await _initializeDirectories();
    } catch (e) {
      debugPrint('Error during application initialization: $e');
      rethrow;
    }
  }

  static Future<void> _initializeDirectories() async {
    final directoryService = AppDirectoryService();
    await directoryService.initialize();
    debugPrint('Application directories initialized successfully');
  }

  static Future<void> handleInitializationFailure(dynamic error) async {
    debugPrint('Application initialization failed: $error');
  }
}
