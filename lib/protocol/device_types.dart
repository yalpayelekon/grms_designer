class DaliDeviceType {
  static const Map<int, String> types = {
    0x00: 'Fluorescent Lamps',
    0x01: 'Self-contained emergency lighting',
    0x02: 'Discharge lamps (excluding fluorescent lamps)',
    // Add all other DALI device types from the table
  };
}

class DigidimDeviceType {
  static const Map<int, String> types = {
    0x00100802: '100 – Rotary',
    0x00110702: '110 – Single Sider',
    // Add all other Digidim device types from the table
  };
}

class ImagineDeviceType {
  static const Map<int, String> types = {
    0x000000F1: '474 – 4 Channel Ballast Controller - Relay Unit',
    0x000000F2: '474 – 4 Channel Ballast Controller - Output Unit',
    // Add all other Imagine device types from the table
  };
}

class DmxDeviceType {
  static const Map<int, String> types = {
    0x00000001: 'DMX Channel In',
    0x00000002: 'DMX Channel Out',
    // Add all other DMX device types from the table
  };
}
