import 'protocol_constants.dart';

class ConfigurationCommands {
  static String storeSceneGroup(int group, int block, int scene, int level,
      {bool forceStore = true}) {
    if (group < 1 || group > 16383) {
      throw ArgumentError('Group must be between 1 and 16383');
    }
    if (block < 1 || block > 8) {
      throw ArgumentError('Block must be between 1 and 8');
    }
    if (scene < 1 || scene > 16) {
      throw ArgumentError('Scene must be between 1 and 16');
    }
    if (level < 0 || level > 100) {
      throw ArgumentError('Level must be between 0 and 100');
    }

    final force = forceStore ? 1 : 0;
    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}1'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}${CommandNumber.storeSceneGroup}'
        '${MessageType.delimiter}${ParameterId.group}${MessageType.paramDelimiter}$group'
        '${MessageType.delimiter}${ParameterId.forceStore}${MessageType.paramDelimiter}$force'
        '${MessageType.delimiter}${ParameterId.block}${MessageType.paramDelimiter}$block'
        '${MessageType.delimiter}${ParameterId.scene}${MessageType.paramDelimiter}$scene'
        '${MessageType.delimiter}${ParameterId.level}${MessageType.paramDelimiter}$level'
        '${MessageType.terminator}';
  }

  static String storeSceneDevice(int cluster, int router, int subnet,
      int device, int block, int scene, int level,
      {bool forceStore = true}) {
    _validateAddress(cluster, router, subnet, device);

    if (block < 1 || block > 8) {
      throw ArgumentError('Block must be between 1 and 8');
    }
    if (scene < 1 || scene > 16) {
      throw ArgumentError('Scene must be between 1 and 16');
    }
    if ((level < 0 || level > 100) && level != 253 && level != 254) {
      throw ArgumentError(
          'Level must be between 0 and 100, or special values 253 (Last Level) or 254 (Ignore)');
    }

    final force = forceStore ? 1 : 0;
    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}1'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}${CommandNumber.storeSceneChannel}'
        '${MessageType.delimiter}${ParameterId.address}$cluster${MessageType.addressDelimiter}$router'
        '${MessageType.addressDelimiter}$subnet${MessageType.addressDelimiter}$device'
        '${MessageType.delimiter}${ParameterId.forceStore}${MessageType.paramDelimiter}$force'
        '${MessageType.delimiter}${ParameterId.block}${MessageType.paramDelimiter}$block'
        '${MessageType.delimiter}${ParameterId.scene}${MessageType.paramDelimiter}$scene'
        '${MessageType.delimiter}${ParameterId.level}${MessageType.paramDelimiter}$level'
        '${MessageType.terminator}';
  }

  static String storeAsSceneGroup(int group, int block, int scene,
      {bool forceStore = true}) {
    if (group < 1 || group > 16383) {
      throw ArgumentError('Group must be between 1 and 16383');
    }
    if (block < 1 || block > 8) {
      throw ArgumentError('Block must be between 1 and 8');
    }
    if (scene < 1 || scene > 16) {
      throw ArgumentError('Scene must be between 1 and 16');
    }

    final force = forceStore ? 1 : 0;
    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}1'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}${CommandNumber.storeAsSceneGroup}'
        '${MessageType.delimiter}${ParameterId.group}${MessageType.paramDelimiter}$group'
        '${MessageType.delimiter}${ParameterId.forceStore}${MessageType.paramDelimiter}$force'
        '${MessageType.delimiter}${ParameterId.block}${MessageType.paramDelimiter}$block'
        '${MessageType.delimiter}${ParameterId.scene}${MessageType.paramDelimiter}$scene'
        '${MessageType.terminator}';
  }

  static String storeAsSceneDevice(
      int cluster, int router, int subnet, int device, int block, int scene,
      {bool forceStore = true}) {
    _validateAddress(cluster, router, subnet, device);

    if (block < 1 || block > 8) {
      throw ArgumentError('Block must be between 1 and 8');
    }
    if (scene < 1 || scene > 16) {
      throw ArgumentError('Scene must be between 1 and 16');
    }

    final force = forceStore ? 1 : 0;
    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}1'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}${CommandNumber.storeAsSceneChannel}'
        '${MessageType.delimiter}${ParameterId.address}$cluster${MessageType.addressDelimiter}$router'
        '${MessageType.addressDelimiter}$subnet${MessageType.addressDelimiter}$device'
        '${MessageType.delimiter}${ParameterId.forceStore}${MessageType.paramDelimiter}$force'
        '${MessageType.delimiter}${ParameterId.block}${MessageType.paramDelimiter}$block'
        '${MessageType.delimiter}${ParameterId.scene}${MessageType.paramDelimiter}$scene'
        '${MessageType.terminator}';
  }

  static String resetEmergencyBatteryGroup(int group) {
    if (group < 1 || group > 16383) {
      throw ArgumentError('Group must be between 1 and 16383');
    }

    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}1'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}${CommandNumber.resetEmergencyBatteryGroup}'
        '${MessageType.delimiter}${ParameterId.group}${MessageType.paramDelimiter}$group'
        '${MessageType.terminator}';
  }

  static String resetEmergencyBatteryDevice(
    int cluster,
    int router,
    int subnet,
    int device,
  ) {
    _validateAddress(cluster, router, subnet, device);

    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}1'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}${CommandNumber.resetEmergencyBatteryDevice}'
        '${MessageType.delimiter}${ParameterId.address}$cluster${MessageType.addressDelimiter}$router'
        '${MessageType.addressDelimiter}$subnet${MessageType.addressDelimiter}$device'
        '${MessageType.terminator}';
  }

  static void _validateAddress(
      int cluster, int router, int subnet, int device) {
    if (cluster < 1 || cluster > 253) {
      throw ArgumentError('Cluster must be between 1 and 253');
    }
    if (router < 1 || router > 254) {
      throw ArgumentError('Router must be between 1 and 254');
    }
    if (subnet < 1 || subnet > 4) {
      throw ArgumentError('Subnet must be between 1 and 4');
    }
    if (device < 1 || device > 255) {
      throw ArgumentError('Device must be between 1 and 255');
    }
  }
}
