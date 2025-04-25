// protocol/protocol_constants.dart
//
// Constants used by the Helvar protocol

/// Default port for Helvar router TCP connections
const int kHelvarDefaultPort = 50000;

/// Default port for Helvar router UDP discovery
const int kHelvarDiscoveryPort = 50001;

/// Device state flags for query responses
class DeviceStateFlags {
  static const int disabled = 0x00000001;
  static const int lampFailure = 0x00000002;
  static const int missing = 0x00000004;
  static const int faulty = 0x00000008;
  static const int refreshing = 0x00000010;
  static const int emergencyResting = 0x00000100;
  static const int inEmergency = 0x00000400;
  static const int inProlong = 0x00000800;
  static const int functionTestInProgress = 0x00001000;
  static const int durationTestInProgress = 0x00002000;
  static const int durationTestPending = 0x00010000;
  static const int functionTestPending = 0x00020000;
  static const int batteryFail = 0x00040000;
  static const int inhibit = 0x00200000;
  static const int functionTestRequested = 0x00400000;
  static const int durationTestRequested = 0x00800000;
  static const int emergencyUnknown = 0x01000000;
  static const int overTemperature = 0x02000000;
  static const int overCurrent = 0x04000000;
  static const int commsError = 0x08000000;
  static const int severeError = 0x10000000;
  static const int badReply = 0x20000000;
  static const int deviceMismatch = 0x80000000;
}

/// Emergency test status values
class EmergencyTestStatus {
  static const int pass = 0;
  static const int lampFailure = 1;
  static const int batteryFailure = 2;
  static const int faulty = 4;
  static const int failure = 8;
  static const int testPending = 16;
  static const int unknown = 32;
}

/// Special level values for scenes
class SceneLevelSpecial {
  static const int lastLevel = 253;
  static const int ignore = 254;
}

/// Status codes for last scene in block/group queries
class SceneStatus {
  static const int off = 128;
  static const int minLevel = 129;
  static const int maxLevel = 130;
  static const int percentageStart = 137; // 0%
  static const int percentageEnd = 237; // 100%
}

/// Error codes returned in diagnostic messages
class ErrorCodes {
  static const int success = 0;
  static const int invalidGroupIndex = 1;
  static const int invalidCluster = 2;
  static const int invalidRouter = 3;
  static const int invalidSubnet = 4;
  static const int invalidDevice = 5;
  static const int invalidSubDevice = 6;
  static const int invalidBlock = 7;
  static const int invalidScene = 8;
  static const int clusterNotExist = 9;
  static const int routerNotExist = 10;
  static const int deviceNotExist = 11;
  static const int propertyNotExist = 12;
  static const int invalidRawMessageSize = 13;
  static const int invalidMessageType = 14;
  static const int invalidMessageCommand = 15;
  static const int missingAsciiTerminator = 16;
  static const int missingAsciiParameter = 17;
  static const int incompatibleVersion = 18;

  // Lookup function to get error message from code
  static String getMessage(int code) {
    final messages = {
      0: 'Success',
      1: 'Error - Invalid group index parameter',
      2: 'Error - Invalid cluster parameter',
      3: 'Error - Invalid router parameter',
      4: 'Error - Invalid subnet parameter',
      5: 'Error - Invalid device parameter',
      6: 'Error - Invalid sub device parameter',
      7: 'Error - Invalid block parameter',
      8: 'Error - Invalid scene parameter',
      9: 'Error - Cluster does not exist',
      10: 'Error - Router does not exist',
      11: 'Error - Device does not exist',
      12: 'Error - Property does not exist',
      13: 'Error - Invalid RAW message size',
      14: 'Error - Invalid messages type',
      15: 'Error - Invalid message command',
      16: 'Error - Missing ASCII terminator',
      17: 'Error - Missing ASCII parameter',
      18: 'Error - Incompatible version',
    };

    return messages[code] ?? 'Unknown error: $code';
  }
}

/// Device protocol types
class DeviceProtocol {
  static const int dali = 0x01;
  static const int digidim = 0x02;
  static const int sdim = 0x04;
  static const int dmx = 0x08;
}

/// Command numbers for the various protocol commands
class CommandNumbers {
  // Control commands
  static const int recallSceneGroup = 11;
  static const int recallSceneDevice = 12;
  static const int directLevelGroup = 13;
  static const int directLevelDevice = 14;
  static const int directProportionGroup = 15;
  static const int directProportionDevice = 16;
  static const int modifyProportionGroup = 17;
  static const int modifyProportionDevice = 18;

  // Emergency test commands
  static const int emergencyFunctionTestGroup = 19;
  static const int emergencyFunctionTestDevice = 20;
  static const int emergencyDurationTestGroup = 21;
  static const int emergencyDurationTestDevice = 22;
  static const int stopEmergencyTestsGroup = 23;
  static const int stopEmergencyTestsDevice = 24;

  // Configuration commands
  static const int storeSceneGroup = 201;
  static const int storeSceneDevice = 202;
  static const int storeAsSceneGroup = 203;
  static const int storeAsSceneDevice = 204;
  static const int resetEmergencyBatteryGroup = 205;
  static const int resetEmergencyBatteryDevice = 206;

  // General query commands
  static const int queryClusters = 101;
  static const int queryRouters = 102;
  static const int queryLastSceneInBlock = 103;
  static const int queryDeviceType = 104;
  static const int queryDescriptionGroup = 105;
  static const int queryDescriptionDevice = 106;
  static const int queryWorkgroupName = 107;
  static const int queryWorkgroupMembership = 108;
  static const int queryLastSceneInGroup = 109;

  // Device state query commands
  static const int queryDeviceState = 110;
  static const int queryDeviceIsDisabled = 111;
  static const int queryLampFailure = 112;
  static const int queryDeviceIsMissing = 113;
  static const int queryDeviceIsFaulty = 114;
  static const int queryEmergencyBatteryFailure = 129;

  // Measurement/input/level query commands
  static const int queryMeasurement = 150;
  static const int queryInputs = 151;
  static const int queryLoadLevel = 152;

  // Power consumption query commands
  static const int queryPowerConsumption = 160;
  static const int queryGroupPowerConsumption = 161;

  // Emergency test query commands
  static const int queryEmergencyFunctionTestTime = 170;
  static const int queryEmergencyFunctionTestState = 171;
  static const int queryEmergencyDurationTestTime = 172;
  static const int queryEmergencyDurationTestState = 173;
  static const int queryEmergencyBatteryCharge = 174;
  static const int queryEmergencyBatteryTime = 175;
  static const int queryEmergencyTotalLampTime = 176;

  // System query commands
  static const int queryTime = 185;
  static const int queryTimeZone = 188;
  static const int queryDaylightSavingTime = 189;
  static const int querySoftwareVersion = 190;
  static const int queryHelvarNetVersion = 191;
}
