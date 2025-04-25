abstract class HelvarDevice {
  int deviceId;
  String address;
  String state;
  String description;
  String props;
  String iconPath;
  String hexId;
  String addressingScheme;
  bool emergency;
  String blockId;
  String sceneId;
  int fadeTime;
  String out;
  String helvarType;
  bool pointsCreated;
  HelvarDevice({
    this.deviceId = 1,
    this.address = "@",
    this.state = "",
    this.description = "",
    this.props = "",
    this.iconPath = "",
    this.hexId = "",
    this.addressingScheme = "",
    this.emergency = false,
    this.blockId = "1",
    this.sceneId = "",
    this.fadeTime = 700,
    this.out = "",
    this.helvarType = "output",
    this.pointsCreated = false,
  });
  void updatePoints();
  void started();
  void stopped();
  void recallScene(String sceneParams);
  void clearResult() {
    out = "";
  }

  String getIconPath() => iconPath;
  void setIconPath(String path) {
    iconPath = path;
  }
}
