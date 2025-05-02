bool isButtonDevice(int typeCode) {
  return typeCode == 1265666 || // Button 135
      typeCode == 1271554 || // Button 136
      typeCode == 1274882 || // Button 137
      typeCode == 1200386 || // Button 125
      typeCode == 1206274 || // Button 126
      typeCode == 1184514 || // Button 121
      typeCode == 1262338 || // Button 134
      typeCode == 1442306 || // Button 160
      (typeCode & 0xFF) == 0x02 &&
          (((typeCode >> 8) & 0xFF) == 0x12 || // 12x series button panels
              ((typeCode >> 8) & 0xFF) == 0x93 || // 93x series scene commanders
              ((typeCode >> 8) & 0xFF) == 0x82 // 82x series touchpanels
          );
}

bool isDeviceMultisensor(int typeCode) {
  return typeCode == 3217410 || // 312 Multisensor
      typeCode == 3220738 || // 312 Multisensor variant
      typeCode == 3282690 || // 321 Multisensor
      ((typeCode & 0xFF) == 0x02 &&
          ((typeCode >> 8) & 0xFF) == 0x31); // Generic multisensor pattern
}

String getDeviceTypeDescription(int typeCode) {
  final protocol = typeCode & 0xFF;

  if (protocol == 0x01) {
    return DaliDeviceType.types[typeCode] ??
        'DALI Device (0x${typeCode.toRadixString(16)})';
  } else if (protocol == 0x02) {
    return DigidimDeviceType.types[typeCode] ??
        'Digidim Device (0x${typeCode.toRadixString(16)})';
  } else if (protocol == 0x04) {
    return ImagineDeviceType.types[typeCode] ??
        'Imagine Device (0x${typeCode.toRadixString(16)})';
  } else if (protocol == 0x08) {
    return DmxDeviceType.types[typeCode] ??
        'DMX Device (0x${typeCode.toRadixString(16)})';
  } else if (typeCode == 4818434) {
    return '498 – Relay Unit (8 channel relay) DALI';
  } else if (typeCode == 3217410 ||
      typeCode == 3220738 ||
      typeCode == 3282690) {
    return 'Multisensor';
  } else if (typeCode == 1537) {
    return 'LED Unit';
  } else if (typeCode == 1265666) {
    return 'Button 135';
  } else if (typeCode == 1) {
    return 'Fluorescent Lamps';
  } else if (typeCode == 1793) {
    return 'Switching function (Relay)';
  } else if (typeCode == 1226903554) {
    return 'DDP Device';
  }

  return 'Unknown Device (0x${typeCode.toRadixString(16)})';
}

class DaliDeviceType {
  static const Map<int, String> types = {
    0x0001: 'Fluorescent Lamps',
    0x0101: 'Self-contained emergency lighting',
    0x0201: 'Discharge lamps (excluding fluorescent lamps)',
    0x0301: 'Low voltage halogen lamps',
    0x0401: 'Incandescent lamps',
    0x0501: 'Conversion into D.C. voltage (IEC 60929)',
    0x0601: 'LED modules',
    0x0701: 'Switching function (i.e., Relay)',
    0x0801: 'Colour control',
    0x0901: 'Sequencer',
    // 0x0A01 undefined
    // 0x0B01 - 0xFE01 undefined
  };
}

class DigidimDeviceType {
  static const Map<int, String> types = {
    0x00100802: '100 – Rotary',
    0x00110702: '110 – Single Sider',
    0x00111402: '111 – Double Sider',
    0x00121302: '121 – 2 Button On/Off + IR',
    0x00122002: '122 – 2 Button Modifier + IR',
    0x00124402: '124 – 5 Button + IR',
    0x00125102: '125 – 5 Button + Modifier + IR',
    0x00126802: '126 – 8 Button + IR',
    0x00170102: '170 – IR Receiver',
    0x00312502: '312 – Multisensor',
    0x00410802: '410 – Ballast (1-10V Converter)',
    0x00416002: '416S – 16A Dimmer',
    0x00425202: '425S – 25A Dimmer',
    0x00444302: '444 – Mini Input Unit',
    0x00450402: '450 – 800W Dimmer',
    0x00452802: '452 – 1000W Universal Dimmer',
    0x00455902: '455 – 500W Thruster Dimmer',
    0x00458002: '458/DIMB – 8-Channel Dimmer',
    0x74458102: '459/CTRB – 8-Ch Ballast Controller',
    0x04458302: '459/SWB – 8-Ch Relay Module',
    0x00460302: '460 – DALI-to-SDIM Converter',
    0x00472602: '472 – Din Rail 1-10V/DS/8 Converter',
    0x00474002: '474 – 4-Ch Ballast (Output Unit)',
    0x00474102: '474 – 4-Ch Ballast (Relay Unit)',
    0x00490002: '490 – Blinds Unit',
    0x00494802: '494 – Relay Unit',
    0x00496602: '498 – Relay Unit',
    0x00804502: '804 – Digidim 4',
    0x00824002: '924 – LCD TouchPanel',
    0x00935602: '935 – Scene Commander (6 Buttons)',
    0x00939402: '939 – Scene Commander (10 Buttons)',
    0x00942402: '942 – Analogue Input Unit',
    0x00458602: '459/CPT4 – 4-Ch Options Module',
  };
}

class ImagineDeviceType {
  static const Map<int, String> types = {
    0x00000004: 'No device present',
    0x0000F104: '474 – 4 Channel Ballast Controller - Relay Unit',
    0x0000F204: '474 – 4 Channel Ballast Controller - Output Unit',
    0x0000F304: '458/SW8 – 8-Channel Relay Module',
    0x0000F404: '458/CTR8 – 8-Channel Ballast Controller',
    0x0000F504: '458/OPT4 – Options Module',
    0x0000F604: '498 – 8-Channel Relay Unit',
    0x0000F704: '458/DIM8 – 8-Channel Dimmer',
    0x0000F804: 'HES92060 – Sine Wave Dimmer',
    0x0000F904: 'Ambience4 Dimmer',
    0x0000FA04: 'HES92020 – SCR Dimmer',
    0x0000FB04: 'HES98020 – Output Unit',
    0x0000FC04: 'HES92220 – Transistor Dimmer',
    0x0000FE04: 'HES98180-98291 – Relay Unit',
    0x0000FF04: 'Dimmer (old style, type undefined)',
  };
}

class DmxDeviceType {
  static const Map<int, String> types = {
    0x00000008: 'DMX No device present',
    0x00000108: 'DMX Channel In',
    0x00000208: 'DMX Channel Out',
  };
}

class DigidimKeyType {
  static const Map<int, String> types = {
    0x00000001: 'SinglePress',
    0x00000002: 'TimedPress',
    0x00000003: 'ToggleSolo',
    0x00000004: 'ToggleBlock',
    0x00000005: 'TouchDimBlock',
    0x00000006: 'TouchDimSolo',
    0x00000007: 'Modifier',
    0x00000008: 'EdgeMode',
    0x00000009: 'Slider',
    0x0000000A: 'AnalogueInput',
    0x0000000B: 'Rotary',
    0x0000000C: 'PIR',
    0x0000000D: 'ConstantLight',
    0x0000000E: 'SliderInputUnit',
  };
}
