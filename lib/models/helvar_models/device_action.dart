import '../link.dart';

enum DeviceAction {
  clearResult,
  recallScene,
  directLevel,
  directProportion,
  modifyProportion,
  emergencyFunctionTest,
  emergencyDurationTest,
  stopEmergencyTest,
  resetEmergencyBattery,
}

extension DeviceActionExtension on DeviceAction {
  String get displayName {
    switch (this) {
      case DeviceAction.clearResult:
        return 'Clear Result';
      case DeviceAction.recallScene:
        return 'Recall Scene';
      case DeviceAction.directLevel:
        return 'Direct Level';
      case DeviceAction.directProportion:
        return 'Direct Proportion';
      case DeviceAction.modifyProportion:
        return 'Modify Proportion';
      case DeviceAction.emergencyFunctionTest:
        return 'Emergency Function Test';
      case DeviceAction.emergencyDurationTest:
        return 'Emergency Duration Test';
      case DeviceAction.stopEmergencyTest:
        return 'Stop Emergency Test';
      case DeviceAction.resetEmergencyBattery:
        return 'Reset Emergency Battery';
    }
  }

  PortType get portType {
    switch (this) {
      case DeviceAction.clearResult:
        return PortType.boolean;
      case DeviceAction.recallScene:
        return PortType.number;
      case DeviceAction.directLevel:
        return PortType.number;
      case DeviceAction.directProportion:
        return PortType.number;
      case DeviceAction.modifyProportion:
        return PortType.number;
      case DeviceAction.emergencyFunctionTest:
        return PortType.boolean;
      case DeviceAction.emergencyDurationTest:
        return PortType.boolean;
      case DeviceAction.stopEmergencyTest:
        return PortType.boolean;
      case DeviceAction.resetEmergencyBattery:
        return PortType.boolean;
    }
  }
}
