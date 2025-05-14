// lib/niagara/models/helvar_device_component.dart
import '../models/component.dart';
import '../models/component_type.dart';
import '../models/port.dart';
import '../models/port_type.dart';

class HelvarDeviceComponent extends Component {
  final int deviceId;
  final String deviceAddress;
  final String deviceType; // 'output', 'input', 'emergency'
  final String description;

  HelvarDeviceComponent({
    required super.id,
    required this.deviceId,
    required this.deviceAddress,
    required this.deviceType,
    required this.description,
    ComponentType? type,
  }) : super(
          type: type ?? const ComponentType(ComponentType.HELVAR_DEVICE),
        ) {
    _setupPorts();
  }

  void _setupPorts() {
    properties.add(Property.withDefaultValue(
      name: "Status",
      index: 0,
      isInput: false,
      type: const PortType(PortType.STRING),
    ));

    switch (deviceType) {
      case 'output':
        _setupOutputDevicePorts();
        break;
      case 'input':
        _setupInputDevicePorts();
        break;
      case 'emergency':
        _setupEmergencyDevicePorts();
        break;
    }
  }

  void _setupOutputDevicePorts() {
    actions.add(ActionSlot(
      name: "Clear Result",
      index: 1,
      parameterType: const PortType(PortType.BOOLEAN),
    ));

    actions.add(ActionSlot(
      name: "Recall Scene",
      index: 2,
      parameterType: const PortType(PortType.NUMERIC),
    ));

    actions.add(ActionSlot(
      name: "Direct Level",
      index: 3,
      parameterType: const PortType(PortType.NUMERIC),
    ));

    actions.add(ActionSlot(
      name: "Direct Proportion",
      index: 4,
      parameterType: const PortType(PortType.NUMERIC),
    ));

    actions.add(ActionSlot(
      name: "Modify Proportion",
      index: 5,
      parameterType: const PortType(PortType.NUMERIC),
    ));
  }

  void _setupInputDevicePorts() {
    actions.add(ActionSlot(
      name: "Clear Result",
      index: 1,
      parameterType: const PortType(PortType.BOOLEAN),
    ));

    for (int i = 1; i <= 5; i++) {
      topics.add(Topic(
        name: "Button $i",
        index: i + 5, // Starting index after actions
        eventType: const PortType(PortType.BOOLEAN),
      ));
    }

    topics.add(Topic(
      name: "Presence",
      index: 11,
      eventType: const PortType(PortType.BOOLEAN),
    ));
  }

  void _setupEmergencyDevicePorts() {
    actions.add(ActionSlot(
      name: "Clear Result",
      index: 1,
      parameterType: const PortType(PortType.BOOLEAN),
    ));

    actions.add(ActionSlot(
      name: "Emergency Function Test",
      index: 2,
      parameterType: const PortType(PortType.BOOLEAN),
    ));

    actions.add(ActionSlot(
      name: "Emergency Duration Test",
      index: 3,
      parameterType: const PortType(PortType.BOOLEAN),
    ));

    actions.add(ActionSlot(
      name: "Stop Emergency Test",
      index: 4,
      parameterType: const PortType(PortType.BOOLEAN),
    ));

    actions.add(ActionSlot(
      name: "Reset Emergency Battery",
      index: 5,
      parameterType: const PortType(PortType.BOOLEAN),
    ));

    topics.add(Topic(
      name: "Emergency State",
      index: 6,
      eventType: const PortType(PortType.BOOLEAN),
    ));

    topics.add(Topic(
      name: "Battery Level",
      index: 7,
      eventType: const PortType(PortType.NUMERIC),
    ));
  }

  @override
  void calculate() {
    // In a real implementation, this would interact with the actual device
    // For now, just a placeholder
  }
}
