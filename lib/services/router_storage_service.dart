import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/helvar_router.dart';
import '../models/helvar_device.dart';

class RouterStorageService {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<String> _getRouterFilePath(
      String workgroupId, String routerAddress) async {
    final path = await _localPath;
    return '$path/workgroup_${workgroupId}_router_$routerAddress.json';
  }

  Future<void> saveRouterDevices(String workgroupId, String routerAddress,
      List<HelvarDevice> devices) async {
    try {
      final filePath = await _getRouterFilePath(workgroupId, routerAddress);
      final file = File(filePath);

      final jsonData = devices.map((device) => device.toJson()).toList();
      final jsonString = jsonEncode(jsonData);

      await file.writeAsString(jsonString);
      debugPrint('Router devices saved to: $filePath');
    } catch (e) {
      debugPrint('Error saving router devices: $e');
      rethrow;
    }
  }

  Future<List<HelvarDevice>> loadRouterDevices(
      String workgroupId, String routerAddress) async {
    try {
      final filePath = await _getRouterFilePath(workgroupId, routerAddress);
      final file = File(filePath);

      if (!await file.exists()) {
        debugPrint('No saved router devices file found.');
        return [];
      }

      final jsonString = await file.readAsString();
      final List<dynamic> jsonData = jsonDecode(jsonString);

      return jsonData.map((json) => HelvarDevice.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading router devices: $e');
      return [];
    }
  }

  /// Export router devices to a specific file path
  Future<void> exportRouterDevices(
      List<HelvarDevice> devices, String filePath) async {
    try {
      final file = File(filePath);

      final jsonData = devices.map((device) => device.toJson()).toList();
      final jsonString = jsonEncode(jsonData);

      await file.writeAsString(jsonString);
      debugPrint('Router devices exported to: $filePath');
    } catch (e) {
      debugPrint('Error exporting router devices: $e');
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
      debugPrint('Error importing router devices: $e');
      rethrow;
    }
  }

  /// Update devices for a router within a workgroup
  Future<void> updateRouterDevices(
      String workgroupId, HelvarRouter router) async {
    try {
      await saveRouterDevices(workgroupId, router.address, router.devices);
    } catch (e) {
      debugPrint('Error updating router devices: $e');
      rethrow;
    }
  }
}
