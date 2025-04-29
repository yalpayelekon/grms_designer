import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../models/workgroup.dart';

class FileStorageService {
  static const String _defaultFilename = 'helvarnet_workgroups.json';

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<String> get _defaultFilePath async {
    final path = await _localPath;
    return '$path/$_defaultFilename';
  }

  Future<void> saveWorkgroups(List<Workgroup> workgroups) async {
    try {
      final filePath = await _defaultFilePath;
      final file = File(filePath);

      final jsonData =
          workgroups.map((workgroup) => workgroup.toJson()).toList();
      final jsonString = jsonEncode(jsonData);

      await file.writeAsString(jsonString);
      debugPrint('Workgroups saved to: $filePath');
    } catch (e) {
      debugPrint('Error saving workgroups: $e');
      rethrow;
    }
  }

  Future<List<Workgroup>> loadWorkgroups() async {
    try {
      final filePath = await _defaultFilePath;
      final file = File(filePath);

      if (!await file.exists()) {
        debugPrint('No saved workgroups file found.');
        return [];
      }

      final jsonString = await file.readAsString();
      final List<dynamic> jsonData = jsonDecode(jsonString);

      return jsonData.map((json) => Workgroup.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading workgroups: $e');
      return [];
    }
  }

  Future<void> exportWorkgroups(
      List<Workgroup> workgroups, String filePath) async {
    try {
      final file = File(filePath);

      final jsonData =
          workgroups.map((workgroup) => workgroup.toJson()).toList();
      final jsonString = jsonEncode(jsonData);

      await file.writeAsString(jsonString);
      debugPrint('Workgroups exported to: $filePath');
    } catch (e) {
      debugPrint('Error exporting workgroups: $e');
      rethrow;
    }
  }

  Future<List<Workgroup>> importWorkgroups(String filePath) async {
    try {
      final file = File(filePath);

      if (!await file.exists()) {
        throw FileSystemException('File not found', filePath);
      }

      final jsonString = await file.readAsString();
      final List<dynamic> jsonData = jsonDecode(jsonString);

      return jsonData.map((json) => Workgroup.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error importing workgroups: $e');
      rethrow;
    }
  }
}
