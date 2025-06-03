/// Predefined polling configurations for common scenarios
class PollingPresets {
  static const Duration fast = Duration(seconds: 10);
  static const Duration normal = Duration(minutes: 1);
  static const Duration slow = Duration(minutes: 5);
  static const Duration verySlow = Duration(minutes: 15);
  static const Duration powerConsumption = Duration(minutes: 15);
  static const Duration deviceStatus = Duration(minutes: 5);
  static const Duration connectionMonitoring = Duration(seconds: 30);
  static const Duration systemHealth = Duration(minutes: 1);

  static Duration? getPreset(String name) {
    switch (name.toLowerCase()) {
      case 'fast':
        return fast;
      case 'normal':
        return normal;
      case 'slow':
        return slow;
      case 'very_slow':
      case 'veryslow':
        return verySlow;
      case 'power_consumption':
      case 'powerconsumption':
        return powerConsumption;
      case 'device_status':
      case 'devicestatus':
        return deviceStatus;
      case 'connection_monitoring':
      case 'connectionmonitoring':
        return connectionMonitoring;
      case 'system_health':
      case 'systemhealth':
        return systemHealth;
      default:
        return null;
    }
  }

  static Map<String, Duration> getAllPresets() {
    return {
      'fast': fast,
      'normal': normal,
      'slow': slow,
      'very_slow': verySlow,
      'power_consumption': powerConsumption,
      'device_status': deviceStatus,
      'connection_monitoring': connectionMonitoring,
      'system_health': systemHealth,
    };
  }
}
