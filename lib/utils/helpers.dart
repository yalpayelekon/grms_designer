import '../models/helvar_models/helvar_device.dart';
import '../models/helvar_models/workgroup.dart';

HelvarDevice? findDevice(
    int deviceId, List<Workgroup> workgroups, String deviceAddress) {
  for (final workgroup in workgroups) {
    for (final router in workgroup.routers) {
      for (final device in router.devices) {
        if (device.deviceId == deviceId && device.address == deviceAddress) {
          return device;
        }
      }
    }
  }

  return null;
}
