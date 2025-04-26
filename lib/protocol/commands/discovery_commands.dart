import '../protocol_constants.dart';

class DiscoveryCommands {
  static String queryWorkgroupName() {
    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}2'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}${CommandNumber.queryWorkgroupName}'
        '${MessageType.terminator}';
  }

  static String queryWorkgroupMembership() {
    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}2'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}${CommandNumber.queryWorkgroupMembership}'
        '${MessageType.terminator}';
  }

  static String queryGroups() {
    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}2'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}${CommandNumber.queryGroups}'
        '${MessageType.terminator}';
  }

  static String queryGroup(int group) {
    if (group < 1 || group > 16383) {
      throw ArgumentError('Group must be between 1 and 16383');
    }

    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}2'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}${CommandNumber.queryGroup}'
        '${MessageType.delimiter}${ParameterId.group}${MessageType.paramDelimiter}$group'
        '${MessageType.terminator}';
  }

  static String querySceneNames() {
    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}2'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}${CommandNumber.querySceneNames}'
        '${MessageType.terminator}';
  }

  static String querySceneInfo(
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

    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}2'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}${CommandNumber.querySceneInfo}'
        '${MessageType.delimiter}${ParameterId.address}$cluster${MessageType.addressDelimiter}$router'
        '${MessageType.addressDelimiter}$subnet${MessageType.addressDelimiter}$device'
        '${MessageType.terminator}';
  }
}
