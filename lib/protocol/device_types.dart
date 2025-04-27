class DaliDeviceType {
  static const Map<int, String> types = {
    0x00: 'Fluorescent Lamps',
    0x01: 'Self-contained emergency lighting',
    0x02: 'Discharge lamps (excluding fluorescent lamps)',
    0x03: 'Low voltage halogen lamps',
    0x04: 'Incandescent lamps',
    0x05: 'Conversion into D.C. voltage (IEC 60929)',
    0x06: 'LED modules',
    0x07: 'Switching function (i.e., Relay)',
    0x08: 'Colour control',
    0x09: 'Sequencer',
    // Values 0x0A and 0x0B-0xFE are undefined as per documentation
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
    0x000000F1: '474 – 4 Channel Ballast Controller - Relay Unit',
    0x000000F2: '474 – 4 Channel Ballast Controller - Output Unit',
    0x000000F3: '458/SW8 – 8-Channel Relay Module',
    0x000000F4: '458/CTR8 – 8-Channel Ballast Controller',
    0x000000F5: '458/OPT4 – Options Module',
    0x000000F6: '498 – 8-Channel Relay Unit',
    0x000000F7: '458/DIM8 – 8-Channel Dimmer',
    0x000000F8: 'HES92060 – Sine Wave Dimmer',
    0x000000F9: 'Ambience4 Dimmer',
    0x000000FA: 'HES92020 – SCR Dimmer',
    0x000000FB: 'HES98020 – Output Unit',
    0x000000FC: 'HES92220 – Transistor Dimmer',
    0x000000FE: 'HES98180-98291 – Relay Unit',
    0x000000FF: 'Dimmer (old style, type undefined)',
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
