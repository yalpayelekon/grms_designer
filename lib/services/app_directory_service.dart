import 'dart:io';
import 'package:path_provider/path_provider.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as path;

import '../utils/core/logger.dart';

class AppDirectoryService {
  static const String _appFolderName = 'GRMS_Designer';
  static const String workgroupsDir = 'workgroups';
  static const String routersDir = 'routers';
  static const String wiresheetsDir = 'wiresheets';
  static const String flowsheetsDir = 'flowsheets';
  static const String imagesDir = 'images';
  static const String backupsDir = 'backups';
  static const String exportsDir = 'exports';
  static const String settingsDir = 'settings';
  static final AppDirectoryService _instance = AppDirectoryService._internal();
  factory AppDirectoryService() => _instance;
  AppDirectoryService._internal();
  String? _baseDirectoryPath;
  Future<void> initialize() async {
    await _getBaseDirectory();
    await createWorkgroupsDirectory();
    await createRoutersDirectory();
    await createWiresheetsDirectory();
    await createImagesDirectory();
    await createBackupsDirectory();
    await createExportsDirectory();
    await createSettingsDirectory();
  }

  Future<String> _getBaseDirectory() async {
    if (_baseDirectoryPath != null) {
      return _baseDirectoryPath!;
    }

    final documentsDir = await getApplicationDocumentsDirectory();
    final baseDir = Directory(path.join(documentsDir.path, _appFolderName));

    if (!await baseDir.exists()) {
      await baseDir.create(recursive: true);
    }

    _baseDirectoryPath = baseDir.path;
    return _baseDirectoryPath!;
  }

  Future<String> _getSubdirectory(String subDirName) async {
    final baseDir = await _getBaseDirectory();
    final subDir = Directory(path.join(baseDir, subDirName));

    if (!await subDir.exists()) {
      await subDir.create(recursive: true);
    }

    return subDir.path;
  }

  Future<String> createWorkgroupsDirectory() async {
    return _getSubdirectory(workgroupsDir);
  }

  Future<String> createRoutersDirectory() async {
    return _getSubdirectory(routersDir);
  }

  Future<String> createWiresheetsDirectory() async {
    return _getSubdirectory(wiresheetsDir);
  }

  Future<String> createImagesDirectory() async {
    return _getSubdirectory(imagesDir);
  }

  Future<String> createBackupsDirectory() async {
    return _getSubdirectory(backupsDir);
  }

  Future<String> createExportsDirectory() async {
    return _getSubdirectory(exportsDir);
  }

  Future<String> createSettingsDirectory() async {
    return _getSubdirectory(settingsDir);
  }

  Future<String> getFilePath(String subDir, String fileName) async {
    final dirPath = await _getSubdirectory(subDir);
    return path.join(dirPath, fileName);
  }

  Future<String> getWorkgroupFilePath(String fileName) async {
    return getFilePath(workgroupsDir, fileName);
  }

  Future<String> getRouterFilePath(String fileName) async {
    return getFilePath(routersDir, fileName);
  }

  Future<String> getWiresheetFilePath(String fileName) async {
    return getFilePath(wiresheetsDir, fileName);
  }

  Future<String> getFlowsheetFilePath(String fileName) async {
    return getFilePath(flowsheetsDir, fileName);
  }

  Future<String> getImageFilePath(String fileName) async {
    return getFilePath(imagesDir, fileName);
  }

  Future<String> getBackupFilePath(String fileName) async {
    return getFilePath(backupsDir, fileName);
  }

  Future<String> getExportFilePath(String fileName) async {
    return getFilePath(exportsDir, fileName);
  }

  Future<String> getSettingsFilePath(String fileName) async {
    return getFilePath(settingsDir, fileName);
  }

  Future<List<FileSystemEntity>> listFiles(String subDir) async {
    final dirPath = await _getSubdirectory(subDir);
    final dir = Directory(dirPath);
    return dir.listSync();
  }

  Future<bool> deleteFile(String subDir, String fileName) async {
    try {
      final filePath = await getFilePath(subDir, fileName);
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
        return true;
      }

      return false;
    } catch (e) {
      logError('Error deleting file: $e');
      return false;
    }
  }

  Future<String?> createBackup(String sourceSubDir, String fileName) async {
    try {
      final sourceFilePath = await getFilePath(sourceSubDir, fileName);
      final sourceFile = File(sourceFilePath);

      if (!await sourceFile.exists()) {
        return null;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupFileName =
          '${path.basenameWithoutExtension(fileName)}_backup_$timestamp${path.extension(fileName)}';
      final backupFilePath = await getBackupFilePath(backupFileName);

      await sourceFile.copy(backupFilePath);
      return backupFilePath;
    } catch (e) {
      logError('Error creating backup: $e');
      return null;
    }
  }

  Future<String?> exportFile(
    String sourceSubDir,
    String fileName,
    String exportName,
  ) async {
    try {
      final sourceFilePath = await getFilePath(sourceSubDir, fileName);
      final sourceFile = File(sourceFilePath);

      if (!await sourceFile.exists()) {
        return null;
      }

      final exportFilePath = await getExportFilePath(exportName);
      await sourceFile.copy(exportFilePath);
      return exportFilePath;
    } catch (e) {
      logError('Error exporting file: $e');
      return null;
    }
  }
}
