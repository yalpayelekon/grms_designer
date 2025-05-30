import 'dart:convert';
import 'dart:io';
import '../models/helvar_models/workgroup.dart';
import '../utils/logger.dart';
import 'app_directory_service.dart';

class FileStorageService {
  static const String _defaultFilename = 'helvarnet_workgroups.json';
  final AppDirectoryService _directoryService = AppDirectoryService();
  Future<void> saveWorkgroups(List<Workgroup> workgroups) async {
    try {
      final filePath =
          await _directoryService.getWorkgroupFilePath(_defaultFilename);
      final file = File(filePath);

      final jsonData =
          workgroups.map((workgroup) => workgroup.toJson()).toList();
      final jsonString = jsonEncode(jsonData);

      await file.writeAsString(jsonString);
      logInfo('Workgroups saved to: $filePath');
    } catch (e) {
      logError('Error saving workgroups: $e');
      rethrow;
    }
  }

  Future<List<Workgroup>> loadWorkgroups() async {
    try {
      final filePath =
          await _directoryService.getWorkgroupFilePath(_defaultFilename);
      final file = File(filePath);

      if (!await file.exists()) {
        logWarning('No saved workgroups file found.');
        return [];
      }

      final jsonString = await file.readAsString();
      final List<dynamic> jsonData = jsonDecode(jsonString);

      return jsonData.map((json) => Workgroup.fromJson(json)).toList();
    } catch (e) {
      logError('Error loading workgroups: $e');
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
      logInfo('Workgroups exported to: $filePath');
      final fileName = filePath.split(Platform.pathSeparator).last;
      await _directoryService.exportFile(
          AppDirectoryService.workgroupsDir, _defaultFilename, fileName);
    } catch (e) {
      logError('Error exporting workgroups: $e');
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
      await _directoryService.createBackup(
          AppDirectoryService.workgroupsDir, _defaultFilename);

      return jsonData.map((json) => Workgroup.fromJson(json)).toList();
    } catch (e) {
      logError('Error importing workgroups: $e');
      rethrow;
    }
  }

  Future<String?> createWorkgroupsBackup() async {
    return _directoryService.createBackup(
        AppDirectoryService.workgroupsDir, _defaultFilename);
  }

  Future<List<FileSystemEntity>> listWorkgroupBackups() async {
    return _directoryService.listFiles(AppDirectoryService.backupsDir);
  }

  Future<bool> restoreWorkgroupsFromBackup(String backupFileName) async {
    try {
      final backupFilePath =
          await _directoryService.getBackupFilePath(backupFileName);
      final backupFile = File(backupFilePath);

      if (!await backupFile.exists()) {
        return false;
      }

      final targetFilePath =
          await _directoryService.getWorkgroupFilePath(_defaultFilename);
      await backupFile.copy(targetFilePath);
      return true;
    } catch (e) {
      logError('Error restoring workgroups from backup: $e');
      return false;
    }
  }
}
