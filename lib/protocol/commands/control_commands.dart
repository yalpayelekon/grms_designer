import '../protocol_constants.dart';

class ControlCommands {
  static String recallSceneGroup(int group, int block, int scene, int fadeTime,
      {bool constantLight = false}) {
    if (group < 1 || group > 16383) {
      throw ArgumentError('Group must be between 1 and 16383');
    }
    if (block < 1 || block > 8) {
      throw ArgumentError('Block must be between 1 and 8');
    }
    if (scene < 1 || scene > 16) {
      throw ArgumentError('Scene must be between 1 and 16');
    }
    if (fadeTime < 0 || fadeTime > 65535) {
      throw ArgumentError(
          'Fade time must be between 0 and 65535 (0.1 seconds)');
    }

    final cl = constantLight ? 1 : 0;
    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}1'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}${CommandNumber.recallSceneGroup}'
        '${MessageType.delimiter}${ParameterId.group}${MessageType.paramDelimiter}$group'
        '${MessageType.delimiter}${ParameterId.constantLight}${MessageType.paramDelimiter}$cl'
        '${MessageType.delimiter}${ParameterId.block}${MessageType.paramDelimiter}$block'
        '${MessageType.delimiter}${ParameterId.scene}${MessageType.paramDelimiter}$scene'
        '${MessageType.delimiter}${ParameterId.fadeTime}${MessageType.paramDelimiter}$fadeTime'
        '${MessageType.terminator}';
  }

  static String recallSceneDevice(
    int cluster,
    int router,
    int subnet,
    int device,
    int block,
    int scene,
    int fadeTime,
  ) {
    _validateAddress(cluster, router, subnet, device);

    if (block < 1 || block > 8) {
      throw ArgumentError('Block must be between 1 and 8');
    }
    if (scene < 1 || scene > 16) {
      throw ArgumentError('Scene must be between 1 and 16');
    }
    if (fadeTime < 0 || fadeTime > 65535) {
      throw ArgumentError(
          'Fade time must be between 0 and 65535 (0.1 seconds)');
    }

    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}1'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}${CommandNumber.recallSceneDevice}'
        '${MessageType.delimiter}${ParameterId.address}$cluster${MessageType.addressDelimiter}$router'
        '${MessageType.addressDelimiter}$subnet${MessageType.addressDelimiter}$device'
        '${MessageType.delimiter}${ParameterId.block}${MessageType.paramDelimiter}$block'
        '${MessageType.delimiter}${ParameterId.scene}${MessageType.paramDelimiter}$scene'
        '${MessageType.delimiter}${ParameterId.fadeTime}${MessageType.paramDelimiter}$fadeTime'
        '${MessageType.terminator}';
  }

  static String directLevelGroup(
    int group,
    int level,
    int fadeTime,
  ) {
    if (group < 1 || group > 16383) {
      throw ArgumentError('Group must be between 1 and 16383');
    }
    if (level < 0 || level > 100) {
      throw ArgumentError('Level must be between 0 and 100');
    }
    if (fadeTime < 0 || fadeTime > 65535) {
      throw ArgumentError(
          'Fade time must be between 0 and 65535 (0.1 seconds)');
    }

    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}1'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}${CommandNumber.directLevelGroup}'
        '${MessageType.delimiter}${ParameterId.group}${MessageType.paramDelimiter}$group'
        '${MessageType.delimiter}${ParameterId.level}${MessageType.paramDelimiter}$level'
        '${MessageType.delimiter}${ParameterId.fadeTime}${MessageType.paramDelimiter}$fadeTime'
        '${MessageType.terminator}';
  }

  static String directLevelDevice(
    int cluster,
    int router,
    int subnet,
    int device,
    int level,
    int fadeTime,
  ) {
    _validateAddress(cluster, router, subnet, device);

    if (level < 0 || level > 100) {
      throw ArgumentError('Level must be between 0 and 100');
    }
    if (fadeTime < 0 || fadeTime > 65535) {
      throw ArgumentError(
          'Fade time must be between 0 and 65535 (0.1 seconds)');
    }

    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}1'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}${CommandNumber.directLevelDevice}'
        '${MessageType.delimiter}${ParameterId.address}$cluster${MessageType.addressDelimiter}$router'
        '${MessageType.addressDelimiter}$subnet${MessageType.addressDelimiter}$device'
        '${MessageType.delimiter}${ParameterId.level}${MessageType.paramDelimiter}$level'
        '${MessageType.delimiter}${ParameterId.fadeTime}${MessageType.paramDelimiter}$fadeTime'
        '${MessageType.terminator}';
  }

  static String directProportionGroup(
    int group,
    int proportion,
    int fadeTime,
  ) {
    if (group < 1 || group > 16383) {
      throw ArgumentError('Group must be between 1 and 16383');
    }
    if (proportion < -100 || proportion > 100) {
      throw ArgumentError('Proportion must be between -100 and 100');
    }
    if (fadeTime < 0 || fadeTime > 65535) {
      throw ArgumentError(
          'Fade time must be between 0 and 65535 (0.1 seconds)');
    }

    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}1'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}${CommandNumber.directProportionGroup}'
        '${MessageType.delimiter}${ParameterId.proportion}${MessageType.paramDelimiter}$proportion'
        '${MessageType.delimiter}${ParameterId.group}${MessageType.paramDelimiter}$group'
        '${MessageType.delimiter}${ParameterId.fadeTime}${MessageType.paramDelimiter}$fadeTime'
        '${MessageType.terminator}';
  }

  static String directProportionDevice(
    int cluster,
    int router,
    int subnet,
    int device,
    int proportion,
    int fadeTime,
  ) {
    _validateAddress(cluster, router, subnet, device);

    if (proportion < -100 || proportion > 100) {
      throw ArgumentError('Proportion must be between -100 and 100');
    }
    if (fadeTime < 0 || fadeTime > 65535) {
      throw ArgumentError(
          'Fade time must be between 0 and 65535 (0.1 seconds)');
    }

    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}1'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}${CommandNumber.directProportionDevice}'
        '${MessageType.delimiter}${ParameterId.address}$cluster${MessageType.addressDelimiter}$router'
        '${MessageType.addressDelimiter}$subnet${MessageType.addressDelimiter}$device'
        '${MessageType.delimiter}${ParameterId.proportion}${MessageType.paramDelimiter}$proportion'
        '${MessageType.delimiter}${ParameterId.fadeTime}${MessageType.paramDelimiter}$fadeTime'
        '${MessageType.terminator}';
  }

  static String modifyProportionGroup(
    int group,
    int proportionChange,
    int fadeTime,
  ) {
    if (group < 1 || group > 16383) {
      throw ArgumentError('Group must be between 1 and 16383');
    }
    if (proportionChange < -100 || proportionChange > 100) {
      throw ArgumentError('Proportion change must be between -100 and 100');
    }
    if (fadeTime < 0 || fadeTime > 65535) {
      throw ArgumentError(
          'Fade time must be between 0 and 65535 (0.1 seconds)');
    }

    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}1'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}${CommandNumber.modifyProportionGroup}'
        '${MessageType.delimiter}${ParameterId.proportion}${MessageType.paramDelimiter}$proportionChange'
        '${MessageType.delimiter}${ParameterId.group}${MessageType.paramDelimiter}$group'
        '${MessageType.delimiter}${ParameterId.fadeTime}${MessageType.paramDelimiter}$fadeTime'
        '${MessageType.terminator}';
  }

  static String modifyProportionDevice(
    int cluster,
    int router,
    int subnet,
    int device,
    int proportionChange,
    int fadeTime,
  ) {
    _validateAddress(cluster, router, subnet, device);

    if (proportionChange < -100 || proportionChange > 100) {
      throw ArgumentError('Proportion change must be between -100 and 100');
    }
    if (fadeTime < 0 || fadeTime > 65535) {
      throw ArgumentError(
          'Fade time must be between 0 and 65535 (0.1 seconds)');
    }

    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}1'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}${CommandNumber.modifyProportionDevice}'
        '${MessageType.delimiter}${ParameterId.address}$cluster${MessageType.addressDelimiter}$router'
        '${MessageType.addressDelimiter}$subnet${MessageType.addressDelimiter}$device'
        '${MessageType.delimiter}${ParameterId.proportion}${MessageType.paramDelimiter}$proportionChange'
        '${MessageType.delimiter}${ParameterId.fadeTime}${MessageType.paramDelimiter}$fadeTime'
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
