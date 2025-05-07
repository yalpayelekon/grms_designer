import '../../utils/logger.dart';
import 'helvar_device.dart';

class HelvarRouter {
  final String type;
  String address;
  final String ipAddress;
  String description;
  List<String>? deviceAddresses;
  bool isNormal;
  bool isMissing;
  bool isFaulty;

  int version;
  int clusterId;
  int clusterMemberId;
  int? deviceTypeCode;
  String? deviceState;
  int? deviceStateCode;
  Map<int, List<HelvarDevice>> devicesBySubnet = {};
  String? deviceType;
  List<HelvarDevice> devices;

  HelvarRouter({
    this.type = 'HelvarRouter',
    this.address = "",
    required this.ipAddress,
    this.version = 2,
    this.description = '',
    this.isNormal = true,
    this.isMissing = false,
    this.isFaulty = false,
    this.clusterId = 1,
    this.clusterMemberId = 1,
    this.deviceTypeCode,
    this.deviceState,
    this.deviceType,
    this.deviceStateCode,
    List<HelvarDevice>? devices,
  }) : devices = devices ?? [] {
    if (ipAddress.contains('.')) {
      final ipParts = ipAddress.split('.');
      if (ipParts.length == 4) {
        try {
          clusterId = int.parse(ipParts[2]);
          clusterMemberId = int.parse(ipParts[3]);
          address = '@${ipParts[2]}.${ipParts[3]}';
        } catch (e) {
          logError(e.toString());
        }
      }
    }

    if (devices != null && devices.isNotEmpty) {
      organizeDevicesBySubnet();
    }
  }

  void organizeDevicesBySubnet() {
    devicesBySubnet.clear();
    for (final device in devices) {
      final parts = device.address.split('.');
      if (parts.length >= 3) {
        final subnet = int.parse(parts[2]);
        if (!devicesBySubnet.containsKey(subnet)) {
          devicesBySubnet[subnet] = [];
        }
        devicesBySubnet[subnet]!.add(device);
      }
    }
  }

  void addDevice(HelvarDevice device) {
    devices.add(device);

    final subnet = device.subnet;
    if (!devicesBySubnet.containsKey(subnet)) {
      devicesBySubnet[subnet] = [];
    }
    devicesBySubnet[subnet]!.add(device);
  }

  void removeDevice(HelvarDevice device) {
    devices.remove(device);

    final subnet = device.subnet;
    if (devicesBySubnet.containsKey(subnet)) {
      devicesBySubnet[subnet]!.remove(device);
      if (devicesBySubnet[subnet]!.isEmpty) {
        devicesBySubnet.remove(subnet);
      }
    }
  }

  List<HelvarDevice> getDevicesByType(String deviceType) {
    return devices.where((device) => device.helvarType == deviceType).toList();
  }

  List<HelvarDevice> getDevicesBySubnet(int subnet) {
    return devicesBySubnet[subnet] ?? [];
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HelvarRouter &&
          runtimeType == other.runtimeType &&
          description == other.description &&
          address == other.address;

  @override
  int get hashCode => description.hashCode ^ address.hashCode;

  factory HelvarRouter.fromJson(Map<String, dynamic> json) {
    return HelvarRouter(
      type: json['type'] as String? ?? 'HelvarRouter',
      address: json['address'] as String,
      ipAddress: json['ipAddress'] as String? ?? '',
      description: json['description'] as String? ?? '',
      isNormal: json['isNormal'] as bool? ?? true,
      isMissing: json['isMissing'] as bool? ?? false,
      isFaulty: json['isFaulty'] as bool? ?? false,
      clusterId: json['clusterId'] as int? ?? 1,
      clusterMemberId: json['clusterMemberId'] as int? ?? 1,
      deviceTypeCode: json['deviceTypeCode'] as int?,
      deviceState: json['deviceState'] as String?,
      deviceStateCode: json['deviceStateCode'] as int?,
      devices: (json['devices'] as List?)
              ?.map((deviceJson) => HelvarDevice.fromJson(deviceJson))
              .whereType<HelvarDevice>()
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    final subnetsJson = <String, List<Map<String, dynamic>>>{};
    devicesBySubnet.forEach((subnet, subnetDevices) {
      subnetsJson['subnet$subnet'] =
          subnetDevices.map((device) => device.toJson()).toList();
    });

    return {
      'type': type,
      'address': address,
      'ipAddress': ipAddress,
      'description': description,
      'isNormal': isNormal,
      'isMissing': isMissing,
      'isFaulty': isFaulty,
      'clusterId': clusterId,
      'clusterMemberId': clusterMemberId,
      'deviceTypeCode': deviceTypeCode,
      'deviceState': deviceState,
      'deviceStateCode': deviceStateCode,
      'devicesBySubnet': subnetsJson,
      'devices': devices.map((device) => device.toJson()).toList(),
    };
  }

  void updateState({bool? isNormal, bool? isMissing, bool? isFaulty}) {
    if (isNormal != null) this.isNormal = isNormal;
    if (isMissing != null) this.isMissing = isMissing;
    if (isFaulty != null) this.isFaulty = isFaulty;
  }
}
