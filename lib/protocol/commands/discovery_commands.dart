import '../protocol_constants.dart';

class DiscoveryCommands {
  static String queryWorkgroupName() {
    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}2'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}107'
        '${MessageType.terminator}';
  }

  static String queryWorkgroupMembership() {
    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}2'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}108'
        '${MessageType.terminator}';
  }

  static String queryGroups() {
    return '${MessageType.command}${ParameterId.version}${MessageType.paramDelimiter}2'
        '${MessageType.delimiter}${ParameterId.command}${MessageType.paramDelimiter}165'
        '${MessageType.terminator}';
  }
}
