import '../../utils/logger.dart';
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
    print("doRecallScene()");
    try {
      if (sceneParams.isNotEmpty) {
        List<String> temp = sceneParams.split(',');

        String timestamp = DateTime.now().toString();
        String s = "Success ($timestamp) Recalled Scene: ${temp[1]}";
        print(s);
        out = s;
      } else {
        print("Please pass a valid scene number!");
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
      print(s);
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
      print(s);
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
      print(s);
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
