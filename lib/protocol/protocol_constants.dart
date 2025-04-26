const int maxMessageLength = 1500;

class MessageType {
  static const String command = '>'; // Command message
  static const String internalCommand = '<'; // Internal command
  static const String reply = '?'; // Reply message
  static const String error = '!'; // Error or diagnostic message
  static const String terminator = '#'; // End of message
  static const String partialTerminator = '\$'; // End of partial message
  static const String answer = '='; // Separates query from response
  static const String delimiter = ','; // Separates parameters
  static const String paramDelimiter = ':'; // Separates parameter ID from value
  static const String addressDelimiter = '.'; // Separates address components
}

class ParameterId {
  static const String sequenceNumber = 'Q'; // For internal commands only
  static const String version = 'V'; // HelvarNet version
  static const String command = 'C'; // Command number
  static const String acknowledgment = 'A'; // Request for acknowledgment
  static const String address = '@'; // Device address
  static const String group = 'G'; // Group ID
  static const String scene = 'S'; // Scene number
  static const String block = 'B'; // Block number
  static const String fadeTime = 'F'; // Fade time in 0.1 seconds
  static const String level = 'L'; // Light level (0-100%)
  static const String proportion = 'P'; // Proportion value
  static const String constantLight = 'K'; // Constant light flag
  static const String forceStore = 'O'; // Force store flag
}

class ProtocolType {
  static const int dali = 0x01;
  static const int digidim = 0x02;
  static const int imagine = 0x04;
  static const int dmx = 0x08;
}

class SceneStatus {
  static const Map<int, String> descriptions = {
    128: 'Off',
    129: 'Min level',
    130: 'Max level',
    137: 'Last Scene Percentage (0%)',
    // Add all other scene statuses from the table
  };
}

class ErrorCode {
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
  static String getMessage(int code) {
    switch (code) {
      case success:
        return 'Success';
      case invalidGroupIndex:
        return 'Error - Invalid group index parameter';
      case invalidCluster:
        return 'Error - Invalid cluster parameter';
      case invalidRouter:
        return 'Error - Invalid router parameter';
      case invalidSubnet:
        return 'Error - Invalid subnet parameter';
      case invalidDevice:
        return 'Error - Invalid device parameter';
      case invalidSubDevice:
        return 'Error - Invalid sub device parameter';
      case invalidBlock:
        return 'Error - Invalid block parameter';
      case invalidScene:
        return 'Error - Invalid scene parameter';
      case clusterNotExist:
        return 'Error - Cluster does not exist';
      case routerNotExist:
        return 'Error - Router does not exist';
      case deviceNotExist:
        return 'Error - Device does not exist';
      case propertyNotExist:
        return 'Error - Property does not exist';
      case invalidRawMessageSize:
        return 'Error - Invalid RAW message size';
      case invalidMessageType:
        return 'Error - Invalid messages type';
      case invalidMessageCommand:
        return 'Error - Invalid message command';
      case missingAsciiTerminator:
        return 'Error - Missing ASCII terminator';
      case missingAsciiParameter:
        return 'Error - Missing ASCII parameter';
      case incompatibleVersion:
        return 'Error - Incompatible version';
      default:
        return 'Unknown error: $code';
    }
  }
}

class DeviceStateFlag {
  static const int disabled = 0x00000001;
  static const int lampFailure = 0x00000002;
  static const int missing = 0x00000004;
  static const int faulty = 0x00000008;
  static const int refreshing = 0x00000010;
  static const int emergencyResting = 0x00000100;
  static const int emergencyMode = 0x00000400;
  static const int emergencyProlong = 0x00000800;
  static const int functionalTestInProgress = 0x00001000;
  static const int durationTestInProgress = 0x00002000;
  static const int durationTestPending = 0x00010000;
  static const int functionalTestPending = 0x00020000;
  static const int batteryFail = 0x00040000;
  static const int emergencyInhibit = 0x00200000;
  static const int functionalTestRequested = 0x00400000;
  static const int durationTestRequested = 0x00800000;
  static const int unknown = 0x01000000;
  static const int overTemperature = 0x02000000;
  static const int overCurrent = 0x04000000;
  static const int commsError = 0x08000000;
  static const int severeError = 0x10000000;
  static const int badReply = 0x20000000;
  static const int deviceMismatch = 0x80000000;
}

class EmergencyTestState {
  static const int pass = 0;
  static const int lampFailure = 1;
  static const int batteryFailure = 2;
  static const int faulty = 4;
  static const int failure = 8;
  static const int testPending = 16;
  static const int unknown = 32;
}

class CommandNumber {
  static const int recallSceneGroup = 11;
  static const int recallSceneDevice = 12;
  static const int directLevelGroup = 13;
  static const int directLevelDevice = 14;
  static const int directProportionGroup = 15;
  static const int directProportionDevice = 16;
  static const int modifyProportionGroup = 17;
  static const int modifyProportionDevice = 18;
  static const int emergencyFunctionTestGroup = 19;
  static const int emergencyFunctionTestDevice = 20;
  static const int emergencyDurationTestGroup = 21;
  static const int emergencyDurationTestDevice = 22;
  static const int stopEmergencyTestsGroup = 23;
  static const int stopEmergencyTestsDevice = 24;
  static const int storeSceneGroup = 201;
  static const int storeSceneChannel = 202;
  static const int storeAsSceneGroup = 203;
  static const int storeAsSceneChannel = 204;
  static const int resetEmergencyBatteryGroup = 205;
  static const int resetEmergencyBatteryDevice = 206;
  static const int queryClusters = 101;
  static const int queryRouters = 102;
  static const int queryLastSceneInBlock = 103;
  static const int queryDeviceType = 104;
  static const int queryDescriptionGroup = 105;
  static const int queryDescriptionDevice = 106;
  static const int queryDeviceState = 110;
  static const int queryDeviceDisabled = 111;
  static const int queryLampFailure = 112;
  static const int queryDeviceMissing = 113;
  static const int queryDeviceFaulty = 114;
  static const int queryMeasurement = 150;
  static const int queryInputs = 151;
  static const int queryLoadLevel = 152;
  static const int queryPowerConsumption = 160;
  static const int queryGroupPowerConsumption = 161;
  static const int queryEmergencyFunctionTestTime = 170;
  static const int queryEmergencyFunctionTestState = 171;
  static const int queryEmergencyDurationTestTime = 172;
  static const int queryEmergencyDurationTestState = 173;
  static const int queryEmergencyBatteryCharge = 174;
  static const int queryEmergencyBatteryTime = 175;
  static const int queryEmergencyTotalLampTime = 176;
  static const int queryTime = 185;
  static const int queryTimeZone = 188;
  static const int queryDaylightSavingTime = 189;
  static const int querySoftwareVersion = 190;
  static const int queryHelvarNetVersion = 191;
  static const int queryWorkgroupName = 107;
  static const int queryWorkgroupMembership = 108;
  static const int queryGroups = 165;
  static const int queryGroup = 164;
  static const int querySceneNames = 166;
  static const int querySceneInfo = 167;
}

class DigidimKeyType {
  static const Map<int, String> types = {
    0x01: 'SinglePress',
    0x02: 'TimedPress',
    0x03: 'ToggleSolo',
    // Add all other key types from the table
  };
}
