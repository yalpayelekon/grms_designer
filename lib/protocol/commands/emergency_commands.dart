import '../protocol_constants.dart';

class EmergencyCommands {
  static String emergencyFunctionTestGroup(int group) {
    if (group < 1 || group > 16383) {
      throw ArgumentError('Group must be between 1 and 16383');
    }

    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}1'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}${CommandNumber.emergencyFunctionTestGroup}'
        '${MessageType.delimiter}${ParameterId.group}${MessageType.paramDelimiter}$group'
        '${MessageType.terminator}';
  }

  static String emergencyFunctionTestDevice(
    int cluster,
    int router,
    int subnet,
    int device,
  ) {
    _validateAddress(cluster, router, subnet, device);

    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}1'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}${CommandNumber.emergencyFunctionTestDevice}'
        '${MessageType.delimiter}${ParameterId.address}$cluster${MessageType.addressDelimiter}$router'
        '${MessageType.addressDelimiter}$subnet${MessageType.addressDelimiter}$device'
        '${MessageType.terminator}';
  }

  static String emergencyDurationTestGroup(int group) {
    if (group < 1 || group > 16383) {
      throw ArgumentError('Group must be between 1 and 16383');
    }

    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}1'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}${CommandNumber.emergencyDurationTestGroup}'
        '${MessageType.delimiter}${ParameterId.group}${MessageType.paramDelimiter}$group'
        '${MessageType.terminator}';
  }

  static String emergencyDurationTestDevice(
    int cluster,
    int router,
    int subnet,
    int device,
  ) {
    _validateAddress(cluster, router, subnet, device);

    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}1'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}${CommandNumber.emergencyDurationTestDevice}'
        '${MessageType.delimiter}${ParameterId.address}$cluster${MessageType.addressDelimiter}$router'
        '${MessageType.addressDelimiter}$subnet${MessageType.addressDelimiter}$device'
        '${MessageType.terminator}';
  }

  static String stopEmergencyTestsGroup(int group) {
    if (group < 1 || group > 16383) {
      throw ArgumentError('Group must be between 1 and 16383');
    }

    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}1'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}${CommandNumber.stopEmergencyTestsGroup}'
        '${MessageType.delimiter}${ParameterId.group}${MessageType.paramDelimiter}$group'
        '${MessageType.terminator}';
  }

  static String stopEmergencyTestsDevice(
    int cluster,
    int router,
    int subnet,
    int device,
  ) {
    _validateAddress(cluster, router, subnet, device);

    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}1'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}${CommandNumber.stopEmergencyTestsDevice}'
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
