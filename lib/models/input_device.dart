import 'helvar_device.dart';

class HelvarDriverInputDevice extends HelvarDevice {
  HelvarDriverInputDevice({
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
    super.helvarType = "input",
    super.pointsCreated,
  });

  @override
  void recallScene(String sceneParams) {
    try {
      if (sceneParams.isNotEmpty) {
        List<String> temp = sceneParams.split(',');

        String timestamp = DateTime.now().toString();
        String s = "Success ($timestamp) Recalled Scene: ${temp[1]}";
        out = s;
      } else {
        print("Please pass a valid scene number!");
        out = "Please pass a valid scene number!";
      }
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
      createInputPoints(address, props, addressingScheme);
      pointsCreated = true;
    }
  }

  @override
  void stopped() {}

  void createInputPoints(
      String deviceAddress, String pointProps, String subAddress) {}
}
