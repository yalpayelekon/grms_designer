import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/wiresheet.dart';
import 'app_directory_service.dart';

class WiresheetStorageService {
  final AppDirectoryService _directoryService = AppDirectoryService();
  Future<String> _getWiresheetFilePath(String id) async {
    return _directoryService.getWiresheetFilePath('wiresheet_$id.json');
  }

  Future<void> saveWiresheet(Wiresheet wiresheet) async {
    try {
      final filePath = await _getWiresheetFilePath(wiresheet.id);
      final file = File(filePath);

      final jsonString = jsonEncode(wiresheet.toJson());

      await file.writeAsString(jsonString);
      debugPrint('Wiresheet saved to: $filePath');
    } catch (e) {
      debugPrint('Error saving wiresheet: $e');
      rethrow;
    }
  }

  Future<Wiresheet?> loadWiresheet(String id) async {
    try {
      final filePath = await _getWiresheetFilePath(id);
      final file = File(filePath);

      if (!await file.exists()) {
        debugPrint('No wiresheet file found for ID: $id');
        return null;
      }

      final jsonString = await file.readAsString();
      final json = jsonDecode(jsonString);

      return Wiresheet.fromJson(json);
    } catch (e) {
      debugPrint('Error loading wiresheet: $e');
      return null;
    }
  }

  Future<bool> deleteWiresheet(String id) async {
    try {
      final filePath = await _getWiresheetFilePath(id);
      final file = File(filePath);

      if (await file.exists()) {
        await _directoryService.createBackup(
            AppDirectoryService.wiresheetsDir, 'wiresheet_$id.json');

        await file.delete();
        debugPrint('Wiresheet deleted: $filePath');
        return true;
      }

      debugPrint('Wiresheet file not found for deletion: $filePath');
      return false;
    } catch (e) {
      debugPrint('Error deleting wiresheet: $e');
      return false;
    }
  }

  Future<List<Wiresheet>> listWiresheets() async {
    try {
      final entities =
          await _directoryService.listFiles(AppDirectoryService.wiresheetsDir);
      final List<Wiresheet> wiresheets = [];

      for (var entity in entities) {
        if (entity is File && entity.path.endsWith('.json')) {
          try {
            final jsonString = await entity.readAsString();
            final json = jsonDecode(jsonString);
            wiresheets.add(Wiresheet.fromJson(json));
          } catch (e) {
            debugPrint('Error reading wiresheet file ${entity.path}: $e');
          }
        }
      }
      wiresheets.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));

      return wiresheets;
    } catch (e) {
      debugPrint('Error listing wiresheets: $e');
      return [];
    }
  }

  Future<Wiresheet> createWiresheet(String name) async {
    final id = const Uuid().v4();
    final wiresheet = Wiresheet(
      id: id,
      name: name,
    );

    await saveWiresheet(wiresheet);
    return wiresheet;
  }

  Future<Wiresheet> ensureDefaultWiresheet() async {
    final wiresheets = await listWiresheets();

    if (wiresheets.isEmpty) {
      return createWiresheet('Default Wiresheet');
    } else {
      return wiresheets.first;
    }
  }

  Future<Wiresheet?> renameWiresheet(String id, String newName) async {
    final wiresheet = await loadWiresheet(id);

    if (wiresheet != null) {
      wiresheet.name = newName;
      wiresheet.modifiedAt = DateTime.now();
      await saveWiresheet(wiresheet);
      return wiresheet;
    }

    return null;
  }

  Future<Wiresheet?> duplicateWiresheet(String id, String newName) async {
    final original = await loadWiresheet(id);

    if (original != null) {
      final newId = const Uuid().v4();
      final duplicate = Wiresheet(
        id: newId,
        name: newName,
        canvasItems: [...original.canvasItems],
        canvasSize: original.canvasSize,
        canvasOffset: original.canvasOffset,
      );

      await saveWiresheet(duplicate);
      return duplicate;
    }

    return null;
  }

  Future<bool> exportWiresheet(String id, String filePath) async {
    try {
      final wiresheet = await loadWiresheet(id);
      if (wiresheet == null) return false;

      final file = File(filePath);
      final jsonString = jsonEncode(wiresheet.toJson());
      await file.writeAsString(jsonString);
      final fileName = filePath.split(Platform.pathSeparator).last;
      await file.copy(await _directoryService.getExportFilePath(fileName));

      return true;
    } catch (e) {
      debugPrint('Error exporting wiresheet: $e');
      return false;
    }
  }

  Future<Wiresheet?> importWiresheet(String filePath, {String? newName}) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final jsonString = await file.readAsString();
      final json = jsonDecode(jsonString);
      final newId = const Uuid().v4();
      final wiresheet = Wiresheet.fromJson(json);
      final importedWiresheet = Wiresheet(
        id: newId,
        name: newName ?? '${wiresheet.name} (Imported)',
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
        canvasItems: wiresheet.canvasItems,
        canvasSize: wiresheet.canvasSize,
        canvasOffset: wiresheet.canvasOffset,
      );

      await saveWiresheet(importedWiresheet);
      return importedWiresheet;
    } catch (e) {
      debugPrint('Error importing wiresheet: $e');
      return null;
    }
  }

  Future<String?> createWiresheetBackup(String id) async {
    try {
      return _directoryService.createBackup(
          AppDirectoryService.wiresheetsDir, 'wiresheet_$id.json');
    } catch (e) {
      debugPrint('Error creating wiresheet backup: $e');
      return null;
    }
  }
}
