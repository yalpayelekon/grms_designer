import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/helvar_models/helvar_router.dart';
import '../models/helvar_models/helvar_device.dart';
import '../utils/core/logger.dart';

class RouterStorageService {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<String> _getRouterFilePath(
    String workgroupId,
    String routerAddress,
  ) async {
    final path = await _localPath;
    return '$path/workgroup_${workgroupId}_router_$routerAddress.json';
  }

  Future<void> saveRouterDevices(
    String workgroupId,
    String routerAddress,
    List<HelvarDevice> devices,
  ) async {
    try {
      final filePath = await _getRouterFilePath(workgroupId, routerAddress);
      final file = File(filePath);

      final jsonData = devices.map((device) => device.toJson()).toList();
      final jsonString = jsonEncode(jsonData);

      await file.writeAsString(jsonString);
      logInfo('Router devices saved to: $filePath');
    } catch (e) {
      logError('Error saving router devices: $e');
      rethrow;
    }
  }

  Future<List<HelvarDevice>> loadRouterDevices(
    String workgroupId,
    String routerAddress,
  ) async {
    try {
      final filePath = await _getRouterFilePath(workgroupId, routerAddress);
      final file = File(filePath);

      if (!await file.exists()) {
        logWarning('No saved router devices file found.');
        return [];
      }

      final jsonString = await file.readAsString();
      final List<dynamic> jsonData = jsonDecode(jsonString);

      return jsonData.map((json) => HelvarDevice.fromJson(json)).toList();
    } catch (e) {
      logError('Error loading router devices: $e');
      return [];
    }
  }

  Future<void> exportRouterDevices(
    List<HelvarDevice> devices,
    String filePath,
  ) async {
    try {
      final file = File(filePath);

      final jsonData = devices.map((device) => device.toJson()).toList();
      final jsonString = jsonEncode(jsonData);

      await file.writeAsString(jsonString);
      logInfo('Router devices exported to: $filePath');
    } catch (e) {
      logError('Error exporting router devices: $e');
      rethrow;
    }
  }

  Future<List<HelvarDevice>> importRouterDevices(String filePath) async {
    try {
      final file = File(filePath);

      if (!await file.exists()) {
        throw FileSystemException('File not found', filePath);
      }

      final jsonString = await file.readAsString();
      final List<dynamic> jsonData = jsonDecode(jsonString);

      return jsonData.map((json) => HelvarDevice.fromJson(json)).toList();
    } catch (e) {
      logError('Error importing router devices: $e');
      rethrow;
    }
  }

  Future<void> updateRouterDevices(
    String workgroupId,
    HelvarRouter router,
  ) async {
    try {
      await saveRouterDevices(workgroupId, router.address, router.devices);
    } catch (e) {
      logError('Error updating router devices: $e');
      rethrow;
    }
  }
}
