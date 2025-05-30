import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:uuid/uuid.dart';
import '../models/flowsheet.dart';
import '../niagara/models/component.dart';
import '../niagara/models/connection.dart';
import '../utils/helpers.dart';
import '../utils/logger.dart';
import 'app_directory_service.dart';

class FlowsheetStorageService {
  final AppDirectoryService _directoryService = AppDirectoryService();

  static const String flowsheetsDir = 'flowsheets';

  Future<void> initialize() async {
    await _directoryService.initialize();
    await _createFlowsheetsDirectory();
  }

  Future<String> _createFlowsheetsDirectory() async {
    return _directoryService.getFlowsheetFilePath(flowsheetsDir);
  }

  Future<String> _getFlowsheetFilePath(String id) async {
    return _directoryService.getFilePath(flowsheetsDir, 'flowsheet_$id.json');
  }

  Future<void> saveFlowsheet(Flowsheet flowsheet) async {
    try {
      final filePath = await _getFlowsheetFilePath(flowsheet.id);
      final file = File(filePath);

      final jsonString = jsonEncode(flowsheet.toJson());

      await file.writeAsString(jsonString);
      //logInfo('Flowsheet saved to: $filePath');
    } catch (e) {
      logError('Error saving flowsheet: $e');
      rethrow;
    }
  }

  Future<Flowsheet?> loadFlowsheet(String id) async {
    try {
      final filePath = await _getFlowsheetFilePath(id);
      final file = File(filePath);

      if (!await file.exists()) {
        logWarning('No flowsheet file found for ID: $id');
        return null;
      }

      final jsonString = await file.readAsString();
      final json = jsonDecode(jsonString);

      return Flowsheet.fromJson(json);
    } catch (e) {
      logError('Error loading flowsheet: $e');
      return null;
    }
  }

  Future<bool> deleteFlowsheet(String id) async {
    try {
      final filePath = await _getFlowsheetFilePath(id);
      final file = File(filePath);

      if (await file.exists()) {
        await _directoryService.createBackup(
            flowsheetsDir, 'flowsheet_$id.json');

        await file.delete();
        logInfo('Flowsheet deleted: $filePath');
        return true;
      }

      logWarning('Flowsheet file not found for deletion: $filePath');
      return false;
    } catch (e) {
      logError('Error deleting flowsheet: $e');
      return false;
    }
  }

  Future<List<Flowsheet>> listFlowsheets() async {
    try {
      await _createFlowsheetsDirectory();

      final entities = await _directoryService.listFiles(flowsheetsDir);
      final List<Flowsheet> flowsheets = [];

      for (var entity in entities) {
        if (entity is File && entity.path.endsWith('.json')) {
          try {
            final jsonString = await entity.readAsString();
            final json = jsonDecode(jsonString);
            flowsheets.add(Flowsheet.fromJson(json));
          } catch (e) {
            logError('Error reading flowsheet file ${entity.path}: $e');
          }
        }
      }

      flowsheets.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));

      return flowsheets;
    } catch (e) {
      logError('Error listing flowsheets: $e');
      return [];
    }
  }

  Future<Flowsheet> createFlowsheet(String name) async {
    final id = const Uuid().v4();
    final flowsheet = Flowsheet(
      id: id,
      name: name,
    );

    await saveFlowsheet(flowsheet);
    return flowsheet;
  }

  Future<Flowsheet> ensureDefaultFlowsheet() async {
    final flowsheets = await listFlowsheets();

    if (flowsheets.isEmpty) {
      return createFlowsheet('Default Flowsheet');
    } else {
      return flowsheets.first;
    }
  }

  Future<Flowsheet?> renameFlowsheet(String id, String newName) async {
    final flowsheet = await loadFlowsheet(id);

    if (flowsheet != null) {
      flowsheet.name = newName;
      flowsheet.modifiedAt = DateTime.now();
      await saveFlowsheet(flowsheet);
      return flowsheet;
    }

    return null;
  }

  Future<Flowsheet?> duplicateFlowsheet(String id, String newName) async {
    final original = await loadFlowsheet(id);

    if (original != null) {
      final newId = const Uuid().v4();

      final Map<String, String> oldToNewIdMap = {};
      final List<Component> newComponents = [];

      for (var originalComponent in original.components) {
        final String oldId = originalComponent.id;
        final String newComponentId = "${originalComponent.id}_copy";
        oldToNewIdMap[oldId] = newComponentId;

        Component newComponent =
            deepCopyComponent(originalComponent, newComponentId);
        newComponents.add(newComponent);
      }

      final List<Connection> newConnections = [];
      for (var originalConnection in original.connections) {
        if (oldToNewIdMap.containsKey(originalConnection.fromComponentId) &&
            oldToNewIdMap.containsKey(originalConnection.toComponentId)) {
          newConnections.add(Connection(
            fromComponentId: oldToNewIdMap[originalConnection.fromComponentId]!,
            fromPortIndex: originalConnection.fromPortIndex,
            toComponentId: oldToNewIdMap[originalConnection.toComponentId]!,
            toPortIndex: originalConnection.toPortIndex,
          ));
        }
      }

      final Map<String, Offset> newComponentPositions = {};
      final Map<String, double> newComponentWidths = {};

      original.componentPositions.forEach((oldId, position) {
        if (oldToNewIdMap.containsKey(oldId)) {
          newComponentPositions[oldToNewIdMap[oldId]!] = position;
        }
      });

      original.componentWidths.forEach((oldId, width) {
        if (oldToNewIdMap.containsKey(oldId)) {
          newComponentWidths[oldToNewIdMap[oldId]!] = width;
        }
      });

      final duplicate = Flowsheet(
        id: newId,
        name: newName,
        components: newComponents,
        connections: newConnections,
        canvasSize: original.canvasSize,
        canvasOffset: original.canvasOffset,
      );

      newComponentPositions.forEach((id, position) {
        duplicate.updateComponentPosition(id, position);
      });

      newComponentWidths.forEach((id, width) {
        duplicate.updateComponentWidth(id, width);
      });

      await saveFlowsheet(duplicate);
      return duplicate;
    }

    return null;
  }

  Future<bool> exportFlowsheet(String id, String filePath) async {
    try {
      final flowsheet = await loadFlowsheet(id);
      if (flowsheet == null) return false;

      final file = File(filePath);
      final jsonString = jsonEncode(flowsheet.toJson());
      await file.writeAsString(jsonString);

      final fileName = filePath.split(Platform.pathSeparator).last;
      await file.copy(await _directoryService.getFilePath(
          AppDirectoryService.exportsDir, fileName));

      return true;
    } catch (e) {
      logError('Error exporting flowsheet: $e');
      return false;
    }
  }

  Future<Flowsheet?> importFlowsheet(String filePath, {String? newName}) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final jsonString = await file.readAsString();
      final json = jsonDecode(jsonString);
      final newId = const Uuid().v4();

      final flowsheet = Flowsheet.fromJson(json);
      final importedFlowsheet = Flowsheet(
        id: newId,
        name: newName ?? '${flowsheet.name} (Imported)',
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
        components: flowsheet.components,
        connections: flowsheet.connections,
        canvasSize: flowsheet.canvasSize,
        canvasOffset: flowsheet.canvasOffset,
      );

      await saveFlowsheet(importedFlowsheet);
      return importedFlowsheet;
    } catch (e) {
      logError('Error importing flowsheet: $e');
      return null;
    }
  }

  Future<String?> createFlowsheetBackup(String id) async {
    try {
      return _directoryService.createBackup(
          flowsheetsDir, 'flowsheet_$id.json');
    } catch (e) {
      logError('Error creating flowsheet backup: $e');
      return null;
    }
  }
}
