import 'helvar_device.dart';

class HelvarRouter {
  final String name;
  final String type;
  final String address;
  final String ipAddress;
  final String description;

  // Router state properties
  bool isNormal;
  bool isMissing;
  bool isFaulty;

  // List of devices connected to this router
  List<HelvarDevice> devices;

  HelvarRouter({
    required this.name,
    this.type = 'HelvarRouter',
    required this.address,
    this.ipAddress = '',
    this.description = '',
    this.isNormal = true,
    this.isMissing = false,
    this.isFaulty = false,
    List<HelvarDevice>? devices,
  }) : devices = devices ?? [];

  // Method to add a device to the router
  void addDevice(HelvarDevice device) {
    devices.add(device);
  }

  // Method to remove a device from the router
  void removeDevice(HelvarDevice device) {
    devices.remove(device);
  }

  // Get devices filtered by a specific type
  List<HelvarDevice> getDevicesByType(String deviceType) {
    return devices.where((device) => device.helvarType == deviceType).toList();
  }

  // Equality comparison
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HelvarRouter &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          address == other.address;

  @override
  int get hashCode => name.hashCode ^ address.hashCode;

  // Conversion from JSON
  factory HelvarRouter.fromJson(Map<String, dynamic> json) {
    return HelvarRouter(
      name: json['name'] as String,
      type: json['type'] as String? ?? 'HelvarRouter',
      address: json['address'] as String,
      ipAddress: json['ipAddress'] as String? ?? '',
      description: json['description'] as String? ?? '',
      isNormal: json['isNormal'] as bool? ?? true,
      isMissing: json['isMissing'] as bool? ?? false,
      isFaulty: json['isFaulty'] as bool? ?? false,
      devices: (json['devices'] as List?)
          ?.map((deviceJson) => HelvarDevice.fromJson(deviceJson))
          .toList(),
    );
  }

  // Conversion to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'address': address,
      'ipAddress': ipAddress,
      'description': description,
      'isNormal': isNormal,
      'isMissing': isMissing,
      'isFaulty': isFaulty,
      'devices': devices.map((device) => device.toJson()).toList(),
    };
  }

  // Update router state based on discovery results
  void updateState({
    bool? isNormal,
    bool? isMissing,
    bool? isFaulty,
  }) {
    if (isNormal != null) this.isNormal = isNormal;
    if (isMissing != null) this.isMissing = isMissing;
    if (isFaulty != null) this.isFaulty = isFaulty;
  }
}
