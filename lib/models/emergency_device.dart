import 'helvar_models/helvar_device.dart';

class HelvarDriverEmergencyDevice extends HelvarDevice {
  String missing;
  String faulty;

  HelvarDriverEmergencyDevice({
    super.deviceId,
    super.address,
    super.state,
    super.description,
    super.props,
    super.iconPath,
    super.hexId,
    super.addressingScheme,
    super.emergency = true,
    super.blockId,
    super.sceneId,
    super.fadeTime,
    super.out,
    super.helvarType = "emergency",
    super.pointsCreated,
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

  void emergencyFunctionTest() {
    try {
      String timestamp = DateTime.now().toString();
      String s = "Success ($timestamp) Emergency Test for device $address";
      out = s;
    } catch (e) {
      print(e);
      out = e.toString();
    }
  }

  void emergencyDurationTest() {
    try {
      String timestamp = DateTime.now().toString();
      String s = "Success ($timestamp) Emergency Test for device $address";
      out = s;
    } catch (e) {
      print(e);
      out = e.toString();
    }
  }

  void stopEmergencyTest() {
    try {
      String timestamp = DateTime.now().toString();
      String s = "Success ($timestamp) Emergency Test for device $address";
      out = s;
    } catch (e) {
      print(e);
      out = e.toString();
    }
  }

  void queryEmergencyFunctionTestTime() {
    try {} catch (e) {
      print(e);
      out = e.toString();
    }
  }

  void queryEmergencyFunctionTestState() {
    try {} catch (e) {
      print(e);
      out = e.toString();
    }
  }

  void queryEmergencyDurationTestTime() {
    try {} catch (e) {
      print(e);
      out = e.toString();
    }
  }

  void queryEmergencyDurationTestState() {
    try {} catch (e) {
      print(e);
      out = e.toString();
    }
  }

  void queryEmergencyBatteryCharge() {
    try {} catch (e) {
      print(e);
      out = e.toString();
    }
  }

  void queryEmergencyBatteryTime() {
    try {} catch (e) {
      print(e);
      out = e.toString();
    }
  }

  void queryEmergencyTotalLampTime() {
    try {} catch (e) {
      print(e);
      out = e.toString();
    }
  }

  void queryEmergencyBatteryEndurance() {
    try {} catch (e) {
      print(e);
      out = e.toString();
    }
  }

  void queryEmdtActualTestDuration() {
    try {} catch (e) {
      print(e);
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
      print(e);
      out = e.toString();
    }
  }

  @override
  void updatePoints() {}

  @override
  void started() {
    if (!pointsCreated) {
      createOutputEmergencyPoints(address, "name");
      pointsCreated = true;
    }
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
