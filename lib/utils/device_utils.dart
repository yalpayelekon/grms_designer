import 'package:grms_designer/models/helvar_models/helvar_device.dart';
import 'package:grms_designer/niagara/models/component.dart';
import 'package:grms_designer/niagara/models/component_type.dart';
import 'package:grms_designer/niagara/models/helvar_device_component.dart';

Component createComponentFromDevice(String id, HelvarDevice device) {
  return HelvarDeviceComponent(
    id: id,
    deviceId: device.deviceId,
    deviceAddress: device.address,
    deviceType: device.helvarType,
    description: device.description.isEmpty
        ? "Device_${device.deviceId}"
        : device.description,
    type: ComponentType(getHelvarComponentType(device.helvarType)),
  );
}

String getHelvarComponentType(String helvarType) {
  switch (helvarType) {
    case 'output':
      return ComponentType.HELVAR_OUTPUT;
    case 'input':
      return ComponentType.HELVAR_INPUT;
    case 'emergency':
      return ComponentType.HELVAR_EMERGENCY;
    default:
      return ComponentType.HELVAR_DEVICE;
  }
}
