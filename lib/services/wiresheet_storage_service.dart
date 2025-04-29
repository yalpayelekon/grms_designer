import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/wiresheet.dart';

class WiresheetStorageService {
  static const String _wiresheetsDirectory = 'wiresheets';

  /// Get the application documents directory path
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  /// Get the full path to the wiresheets directory
  Future<String> get _wiresheetsPath async {
    final path = await _localPath;
    final dir = Directory('$path/$_wiresheetsDirectory');

    // Create directory if it doesn't exist
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    return dir.path;
  }

  /// Get the full path to a specific wiresheet file
  Future<String> _getWiresheetFilePath(String id) async {
    final dirPath = await _wiresheetsPath;
    return '$dirPath/wiresheet_$id.json';
  }

  /// Save a wiresheet to a file
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

  /// Load a wiresheet from a file
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

  /// Delete a wiresheet file
  Future<bool> deleteWiresheet(String id) async {
    try {
      final filePath = await _getWiresheetFilePath(id);
      final file = File(filePath);

      if (await file.exists()) {
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

  /// List all wiresheets
  Future<List<Wiresheet>> listWiresheets() async {
    try {
      final dirPath = await _wiresheetsPath;
      final dir = Directory(dirPath);

      if (!await dir.exists()) {
        return [];
      }

      final List<Wiresheet> wiresheets = [];

      final List<FileSystemEntity> entities = await dir.list().toList();
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

      // Sort by modified date (newest first)
      wiresheets.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));

      return wiresheets;
    } catch (e) {
      debugPrint('Error listing wiresheets: $e');
      return [];
    }
  }

  /// Create a new wiresheet
  Future<Wiresheet> createWiresheet(String name) async {
    final id = const Uuid().v4();
    final wiresheet = Wiresheet(
      id: id,
      name: name,
    );

    await saveWiresheet(wiresheet);
    return wiresheet;
  }

  /// Check if default wiresheet exists, create if not
  Future<Wiresheet> ensureDefaultWiresheet() async {
    final wiresheets = await listWiresheets();

    if (wiresheets.isEmpty) {
      // Create default wiresheet
      return createWiresheet('Default Wiresheet');
    } else {
      // Return the first wiresheet
      return wiresheets.first;
    }
  }

  /// Rename a wiresheet
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

  /// Duplicate a wiresheet
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
}
