import '../../utils/core/logger.dart';
import 'device_action.dart';
import 'helvar_device.dart';

class HelvarDriverEmergencyDevice extends HelvarDevice {
  String missing;
  String faulty;

  HelvarDriverEmergencyDevice({
    super.deviceId,
    super.address,
    super.state,
    super.description,
    super.props,
    super.name,
    super.iconPath,
    super.hexId,
    super.addressingScheme,
    super.emergency = true,
    super.blockId,
    super.sceneId,
    super.out,
    super.helvarType = "emergency",
    super.deviceTypeCode,
    super.deviceStateCode,
    super.isButtonDevice,
    super.isMultisensor,
    super.sensorInfo,
    super.additionalInfo,
    this.missing = "",
    this.faulty = "",
  });

  @override
  void recallScene(String sceneParams) {
    throw UnimplementedError("Emergency devices do not support scene recall");
  }

  @override
  void performAction(DeviceAction action, dynamic value) {
    switch (action) {
      case DeviceAction.clearResult:
        clearResult();
        break;
      case DeviceAction.emergencyFunctionTest:
        emergencyFunctionTest();
        break;
      case DeviceAction.emergencyDurationTest:
        emergencyDurationTest();
        break;
      case DeviceAction.stopEmergencyTest:
        stopEmergencyTest();
        break;
      case DeviceAction.resetEmergencyBattery:
        resetEmergencyBatteryTotalLampTime();
        break;
      default:
        logWarning("Action $action not supported for emergency device");
    }
  }

  void emergencyFunctionTest() {
    try {
      String timestamp = DateTime.now().toString();
      String s = "Success ($timestamp) Emergency Test for device $address";
      out = s;
    } catch (e) {
      logError(e.toString());
      out = e.toString();
    }
  }

  void emergencyDurationTest() {
    try {
      String timestamp = DateTime.now().toString();
      String s = "Success ($timestamp) Emergency Test for device $address";
      out = s;
    } catch (e) {
      logError(e.toString());
      out = e.toString();
    }
  }

  void stopEmergencyTest() {
    try {
      String timestamp = DateTime.now().toString();
      String s = "Success ($timestamp) Emergency Test for device $address";
      out = s;
    } catch (e) {
      logError(e.toString());
      out = e.toString();
    }
  }

  void queryEmergencyFunctionTestTime() {
    try {} catch (e) {
      logError(e.toString());
      out = e.toString();
    }
  }

  void queryEmergencyFunctionTestState() {
    try {} catch (e) {
      logError(e.toString());
      out = e.toString();
    }
  }

  void queryEmergencyDurationTestTime() {
    try {} catch (e) {
      logError(e.toString());
      out = e.toString();
    }
  }

  void queryEmergencyDurationTestState() {
    try {} catch (e) {
      logError(e.toString());
      out = e.toString();
    }
  }

  void queryEmergencyBatteryCharge() {
    try {} catch (e) {
      logError(e.toString());
      out = e.toString();
    }
  }

  void queryEmergencyBatteryTime() {
    try {} catch (e) {
      logError(e.toString());
      out = e.toString();
    }
  }

  void queryEmergencyTotalLampTime() {
    try {} catch (e) {
      logError(e.toString());
      out = e.toString();
    }
  }

  void queryEmergencyBatteryEndurance() {
    try {} catch (e) {
      logError(e.toString());
      out = e.toString();
    }
  }

  void queryEmdtActualTestDuration() {
    try {} catch (e) {
      logError(e.toString());
      out = e.toString();
    }
  }

  void resetEmergencyBatteryTotalLampTime() {
    try {
      String timestamp = DateTime.now().toString();
      String s =
          "Success ($timestamp) Reset Emergency Battery and Total Lamp Time for device $address";
      out = s;
    } catch (e) {
      logError(e.toString());
      out = e.toString();
    }
  }

  @override
  void started() {
    createOutputEmergencyPoints(address, "name");
  }

  @override
  void stopped() {}

  void createOutputEmergencyPoints(String deviceAddress, String name) {}

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['missing'] = missing;
    json['faulty'] = faulty;
    return json;
  }
}
