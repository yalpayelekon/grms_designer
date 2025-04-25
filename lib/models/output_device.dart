import 'helvar_device.dart';

class HelvarDriverOutputDevice extends HelvarDevice {
  // Output device specific properties
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

        // In real implementation, this would communicate with the Helvar router

        String timestamp = DateTime.now().toString();
        String s = "Success ($timestamp) Recalled Scene: ${temp[1]}";
        print(s);
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

  void directLevel(String levelParams) {
    try {
      List<String> temp = levelParams.split(',');

      // In real implementation, this would communicate with the Helvar router
      // to set a direct level for a device

      String timestamp = DateTime.now().toString();
      String s = "Success ($timestamp) Direct Level Device: ${temp[0]}";
      print(s);
      out = s;

      // In real implementation, might trigger a refresh
    } catch (e) {
      print(e);
      out = e.toString();
    }
  }

  void directProportion(String proportionParams) {
    try {
      List<String> temp = proportionParams.split(',');

      // In real implementation, this would communicate with the Helvar router

      String timestamp = DateTime.now().toString();
      String s = "Success ($timestamp) Direct Proportion Device: ${temp[0]}";
      out = s;
      print(s);
    } catch (e) {
      print(e);
      out = e.toString();
    }
  }

  void modifyProportion(String proportionParams) {
    try {
      List<String> temp = proportionParams.split(',');

      // In real implementation, this would communicate with the Helvar router

      String timestamp = DateTime.now().toString();
      String s = "Success ($timestamp) Direct Proportion Device: ${temp[0]}";
      print(s);
      out = s;
    } catch (e) {
      print(e);
      out = e.toString();
    }
  }

  @override
  void updatePoints() {
    // In real implementation, this would poll all points
    // and schedule periodic updates
  }

  @override
  void started() {
    if (!pointsCreated) {
      createOutputPoints(address, getName());
      pointsCreated = true;
    }

    // Schedule updates in real implementation
  }

  String getName() {
    // This would typically return the device name from the system
    // For now, we'll just return a placeholder
    return "Device_${deviceId}";
  }

  @override
  void stopped() {
    // Cancel scheduled tasks in real implementation
  }

  void createOutputPoints(String deviceAddress, String name) {
    // In real implementation, this would create various control points:
    // DeviceState, LampFailure, Missing, Faulty, OutputLevel, PowerConsumption
  }

  void queryLoadLevel() {
    // In real implementation, this would query the current load level from the device
  }
}
