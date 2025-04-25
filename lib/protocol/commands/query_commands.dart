import '../protocol_constants.dart';

class QueryCommands {
  static String queryClusters() {
    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}1'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}${CommandNumber.queryClusters}'
        '${MessageType.terminator}';
  }

  static String queryRouters(int cluster) {
    if (cluster < 1 || cluster > 253) {
      throw ArgumentError('Cluster must be between 1 and 253');
    }

    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}1'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}${CommandNumber.queryRouters}'
        '${MessageType.delimiter}${ParameterId.address}$cluster'
        '${MessageType.terminator}';
  }

  static String queryLastSceneInBlock(int group, int block) {
    if (group < 1 || group > 16383) {
      throw ArgumentError('Group must be between 1 and 16383');
    }
    if (block < 1 || block > 8) {
      throw ArgumentError('Block must be between 1 and 8');
    }

    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}1'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}${CommandNumber.queryLastSceneInBlock}'
        '${MessageType.delimiter}${ParameterId.group}${MessageType.paramDelimiter}$group'
        '${MessageType.delimiter}${ParameterId.block}${MessageType.paramDelimiter}$block'
        '${MessageType.terminator}';
  }

  static String queryDeviceType(
      int cluster, int router, int subnet, int device) {
    _validateAddress(cluster, router, subnet, device);

    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}1'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}${CommandNumber.queryDeviceType}'
        '${MessageType.delimiter}${ParameterId.address}$cluster${MessageType.addressDelimiter}$router'
        '${MessageType.addressDelimiter}$subnet${MessageType.addressDelimiter}$device'
        '${MessageType.terminator}';
  }

  static String queryDescriptionGroup(int group) {
    if (group < 1 || group > 16383) {
      throw ArgumentError('Group must be between 1 and 16383');
    }

    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}1'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}${CommandNumber.queryDescriptionGroup}'
        '${MessageType.delimiter}${ParameterId.group}${MessageType.paramDelimiter}$group'
        '${MessageType.terminator}';
  }

  static String queryDescriptionDevice(
      int cluster, int router, int subnet, int device) {
    _validateAddress(cluster, router, subnet, device);

    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}1'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}${CommandNumber.queryDescriptionDevice}'
        '${MessageType.delimiter}${ParameterId.address}$cluster${MessageType.addressDelimiter}$router'
        '${MessageType.addressDelimiter}$subnet${MessageType.addressDelimiter}$device'
        '${MessageType.terminator}';
  }

  static String queryDeviceState(
      int cluster, int router, int subnet, int device) {
    _validateAddress(cluster, router, subnet, device);

    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}1'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}${CommandNumber.queryDeviceState}'
        '${MessageType.delimiter}${ParameterId.address}$cluster${MessageType.addressDelimiter}$router'
        '${MessageType.addressDelimiter}$subnet${MessageType.addressDelimiter}$device'
        '${MessageType.terminator}';
  }

  static String queryDeviceIsDisabled(
      int cluster, int router, int subnet, int device) {
    _validateAddress(cluster, router, subnet, device);

    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}1'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}${CommandNumber.queryDeviceDisabled}'
        '${MessageType.delimiter}${ParameterId.address}$cluster${MessageType.addressDelimiter}$router'
        '${MessageType.addressDelimiter}$subnet${MessageType.addressDelimiter}$device'
        '${MessageType.terminator}';
  }

  static String queryLampFailure(
      int cluster, int router, int subnet, int device) {
    _validateAddress(cluster, router, subnet, device);

    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}1'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}${CommandNumber.queryLampFailure}'
        '${MessageType.delimiter}${ParameterId.address}$cluster${MessageType.addressDelimiter}$router'
        '${MessageType.addressDelimiter}$subnet${MessageType.addressDelimiter}$device'
        '${MessageType.terminator}';
  }

  static String queryDeviceIsMissing(
      int cluster, int router, int subnet, int device) {
    _validateAddress(cluster, router, subnet, device);

    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}1'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}${CommandNumber.queryDeviceMissing}'
        '${MessageType.delimiter}${ParameterId.address}$cluster${MessageType.addressDelimiter}$router'
        '${MessageType.addressDelimiter}$subnet${MessageType.addressDelimiter}$device'
        '${MessageType.terminator}';
  }

  static String queryDeviceIsFaulty(
      int cluster, int router, int subnet, int device) {
    _validateAddress(cluster, router, subnet, device);

    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}1'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}${CommandNumber.queryDeviceFaulty}'
        '${MessageType.delimiter}${ParameterId.address}$cluster${MessageType.addressDelimiter}$router'
        '${MessageType.addressDelimiter}$subnet${MessageType.addressDelimiter}$device'
        '${MessageType.terminator}';
  }

  static String queryLoadLevel(
      int cluster, int router, int subnet, int device) {
    _validateAddress(cluster, router, subnet, device);

    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}1'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}${CommandNumber.queryLoadLevel}'
        '${MessageType.delimiter}${ParameterId.address}$cluster${MessageType.addressDelimiter}$router'
        '${MessageType.addressDelimiter}$subnet${MessageType.addressDelimiter}$device'
        '${MessageType.terminator}';
  }

  static String queryPowerConsumption(
      int cluster, int router, int subnet, int device) {
    _validateAddress(cluster, router, subnet, device);

    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}1'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}${CommandNumber.queryPowerConsumption}'
        '${MessageType.delimiter}${ParameterId.address}$cluster${MessageType.addressDelimiter}$router'
        '${MessageType.addressDelimiter}$subnet${MessageType.addressDelimiter}$device'
        '${MessageType.terminator}';
  }

  static String queryGroupPowerConsumption(int group) {
    if (group < 1 || group > 16383) {
      throw ArgumentError('Group must be between 1 and 16383');
    }

    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}1'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}${CommandNumber.queryGroupPowerConsumption}'
        '${MessageType.delimiter}${ParameterId.group}${MessageType.paramDelimiter}$group'
        '${MessageType.terminator}';
  }

  static String queryEmergencyFunctionTestTime(
      int cluster, int router, int subnet, int device) {
    _validateAddress(cluster, router, subnet, device);

    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}1'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}${CommandNumber.queryEmergencyFunctionTestTime}'
        '${MessageType.delimiter}${ParameterId.address}$cluster${MessageType.addressDelimiter}$router'
        '${MessageType.addressDelimiter}$subnet${MessageType.addressDelimiter}$device'
        '${MessageType.terminator}';
  }

  static String queryEmergencyFunctionTestState(
      int cluster, int router, int subnet, int device) {
    _validateAddress(cluster, router, subnet, device);

    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}1'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}${CommandNumber.queryEmergencyFunctionTestState}'
        '${MessageType.delimiter}${ParameterId.address}$cluster${MessageType.addressDelimiter}$router'
        '${MessageType.addressDelimiter}$subnet${MessageType.addressDelimiter}$device'
        '${MessageType.terminator}';
  }

  static String queryEmergencyDurationTestTime(
      int cluster, int router, int subnet, int device) {
    _validateAddress(cluster, router, subnet, device);

    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}1'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}${CommandNumber.queryEmergencyDurationTestTime}'
        '${MessageType.delimiter}${ParameterId.address}$cluster${MessageType.addressDelimiter}$router'
        '${MessageType.addressDelimiter}$subnet${MessageType.addressDelimiter}$device'
        '${MessageType.terminator}';
  }

  static String queryEmergencyDurationTestState(
      int cluster, int router, int subnet, int device) {
    _validateAddress(cluster, router, subnet, device);

    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}1'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}${CommandNumber.queryEmergencyDurationTestState}'
        '${MessageType.delimiter}${ParameterId.address}$cluster${MessageType.addressDelimiter}$router'
        '${MessageType.addressDelimiter}$subnet${MessageType.addressDelimiter}$device'
        '${MessageType.terminator}';
  }

  static String queryEmergencyBatteryCharge(
      int cluster, int router, int subnet, int device) {
    _validateAddress(cluster, router, subnet, device);

    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}1'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}${CommandNumber.queryEmergencyBatteryCharge}'
        '${MessageType.delimiter}${ParameterId.address}$cluster${MessageType.addressDelimiter}$router'
        '${MessageType.addressDelimiter}$subnet${MessageType.addressDelimiter}$device'
        '${MessageType.terminator}';
  }

  static String queryEmergencyBatteryTime(
      int cluster, int router, int subnet, int device) {
    _validateAddress(cluster, router, subnet, device);

    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}1'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}${CommandNumber.queryEmergencyBatteryTime}'
        '${MessageType.delimiter}${ParameterId.address}$cluster${MessageType.addressDelimiter}$router'
        '${MessageType.addressDelimiter}$subnet${MessageType.addressDelimiter}$device'
        '${MessageType.terminator}';
  }

  static String queryEmergencyTotalLampTime(
      int cluster, int router, int subnet, int device) {
    _validateAddress(cluster, router, subnet, device);

    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}1'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}${CommandNumber.queryEmergencyTotalLampTime}'
        '${MessageType.delimiter}${ParameterId.address}$cluster${MessageType.addressDelimiter}$router'
        '${MessageType.addressDelimiter}$subnet${MessageType.addressDelimiter}$device'
        '${MessageType.terminator}';
  }

  static String queryTime() {
    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}1'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}${CommandNumber.queryTime}'
        '${MessageType.terminator}';
  }

  static String querySoftwareVersion() {
    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}1'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}${CommandNumber.querySoftwareVersion}'
        '${MessageType.terminator}';
  }

  static String queryHelvarNetVersion() {
    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}1'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}${CommandNumber.queryHelvarNetVersion}'
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
