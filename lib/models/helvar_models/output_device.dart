import '../../utils/logger.dart';
import 'device_action.dart';
import 'helvar_device.dart';

class HelvarDriverOutputDevice extends HelvarDevice {
  String missing;
  String faulty;
  int level;
  int proportion;

  HelvarDriverOutputDevice({
    super.deviceId,
    super.address,
    super.state,
    super.description,
    super.props,
    super.iconPath,
    super.hexId,
    super.addressingScheme,
    super.emergency,
    super.blockId,
    super.sceneId,
    super.fadeTime,
    super.out,
    super.helvarType = "output",
    super.pointsCreated,
    super.deviceTypeCode,
    super.deviceStateCode,
    super.isButtonDevice,
    super.isMultisensor,
    super.sensorInfo,
    super.additionalInfo,
    this.missing = "",
    this.faulty = "",
    this.level = 100,
    this.proportion = 0,
  });

  @override
  void recallScene(String sceneParams) {
    logInfo("Recalling scene with params: $sceneParams");
    try {
      if (sceneParams.isNotEmpty) {
        List<String> temp = sceneParams.split(',');

        String timestamp = DateTime.now().toString();
        String s = "Success ($timestamp) Recalled Scene: ${temp[1]}";
        logInfo(s);
        out = s;
      } else {
        logWarning("Please pass a valid scene number!");
        out = "Please pass a valid scene number!";
      }
    } catch (e) {
      logError(e.toString());
      out = e.toString();
    }
  }

  void directLevel(String levelParams) {
    try {
      List<String> temp = levelParams.split(',');

      String timestamp = DateTime.now().toString();
      String s = "Success ($timestamp) Direct Level Device: ${temp[0]}";
      logInfo(s);
      out = s;
    } catch (e) {
      logError(e.toString());
      out = e.toString();
    }
  }

  void directProportion(String proportionParams) {
    try {
      List<String> temp = proportionParams.split(',');

      String timestamp = DateTime.now().toString();
      String s = "Success ($timestamp) Direct Proportion Device: ${temp[0]}";
      out = s;
      logInfo(s);
    } catch (e) {
      logError(e.toString());
      out = e.toString();
    }
  }

  void modifyProportion(String proportionParams) {
    try {
      List<String> temp = proportionParams.split(',');

      String timestamp = DateTime.now().toString();
      String s = "Success ($timestamp) Direct Proportion Device: ${temp[0]}";
      logInfo(s);
      out = s;
    } catch (e) {
      logError(e.toString());
      out = e.toString();
    }
  }

  @override
  void updatePoints() {}

  @override
  void started() {
    if (!pointsCreated) {
      createOutputPoints(address, getName());
      pointsCreated = true;
    }
  }

  String getName() {
    return description.isNotEmpty ? description : "Device_$deviceId";
  }

  @override
  void stopped() {}
  @override
  void performAction(DeviceAction action, dynamic value) {
    switch (action) {
      case DeviceAction.clearResult:
        clearResult();
        break;
      case DeviceAction.recallScene:
        if (value is int) {
          recallScene("1,$value");
        }
        break;
      case DeviceAction.directLevel:
        if (value is int) {
          directLevel("$value");
        }
        break;
      case DeviceAction.directProportion:
        if (value is int) {
          directProportion("$value");
        }
        break;
      case DeviceAction.modifyProportion:
        if (value is int) {
          modifyProportion("$value");
        }
        break;
      default:
        logWarning("Action $action not supported for output device");
    }
  }

  void createOutputPoints(String deviceAddress, String name) {}

  void queryLoadLevel() {}

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['missing'] = missing;
    json['faulty'] = faulty;
    json['level'] = level;
    json['proportion'] = proportion;
    return json;
  }
}
