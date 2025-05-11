import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'helvar_models/device_action.dart';
import 'helvar_models/helvar_device.dart';
import 'link.dart';
import 'widget_type.dart';

class CanvasItem {
  final WidgetType type;
  Offset position;
  Size size;
  Map<String, dynamic> properties;
  String? id;
  String? label;
  List<Port> ports;
  ComponentCategory? category;
  int rowCount;
  CanvasItem({
    required this.type,
    required this.position,
    required this.size,
    this.id,
    this.category,
    List<Port>? ports,
    this.label,
    Map<String, dynamic>? properties,
    this.rowCount = 5,
  })  : properties = properties ?? {},
        ports = ports ?? [],
        super();

  void addPort(Port port) {
    ports.add(port);
  }

  Port? getPort(String portId) {
    try {
      return ports.firstWhere((p) => p.id == portId);
    } catch (e) {
      return null;
    }
  }

  factory CanvasItem.fromJson(Map<String, dynamic> json) {
    final portsList = (json['ports'] as List?)
            ?.map((item) => Port.fromJson(item as Map<String, dynamic>))
            .toList() ??
        [];

    return CanvasItem(
      type: WidgetType.values.firstWhere(
        (e) => e.toString() == 'WidgetType.${json['type']}',
        orElse: () => WidgetType.text,
      ),
      position: Offset(
        (json['position']['dx'] as num).toDouble(),
        (json['position']['dy'] as num).toDouble(),
      ),
      size: Size(
        (json['size']['width'] as num).toDouble(),
        (json['size']['height'] as num).toDouble(),
      ),
      id: json['id'] as String?,
      label: json['label'] as String?,
      properties: json['properties'] as Map<String, dynamic>? ?? {},
      ports: portsList,
    );
  }

  Map<String, dynamic> toJson() {
    final json = {
      'type': type.toString().split('.').last,
      'position': {
        'dx': position.dx,
        'dy': position.dy,
      },
      'size': {
        'width': size.width,
        'height': size.height,
      },
      'id': id,
      'label': label,
      'properties': properties,
    };
    json['ports'] = ports.map((port) => port.toJson()).toList();
    json['category'] = category.toString().split('.').last;
    return json;
  }

  static CanvasItem createLogicItem(String type, Offset position) {
    final id = const Uuid().v4();
    const size = Size(120, 80);
    final ports = <Port>[];
    int rowCount = 3;

    switch (type) {
      case 'AND':
      case 'OR':
        rowCount = 3;
        ports.add(Port(
          id: 'in1',
          type: PortType.boolean,
          name: 'Input 1',
          isInput: true,
        ));
        ports.add(Port(
          id: 'in2',
          type: PortType.boolean,
          name: 'Input 2',
          isInput: true,
        ));
        ports.add(Port(
          id: 'out',
          type: PortType.boolean,
          name: 'Output',
          isInput: false,
        ));
        break;

      case 'IF':
        rowCount = 3;
        ports.add(Port(
          id: 'in1',
          type: PortType.boolean,
          name: 'Condition',
          isInput: true,
        ));
        ports.add(Port(
          id: 'out',
          type: PortType.any,
          name: 'Result',
          isInput: false,
        ));

        break;

      case 'GreaterThan':
        rowCount = 3;
        ports.add(Port(
          id: 'in1',
          type: PortType.number,
          name: 'Value',
          isInput: true,
        ));
        ports.add(Port(
          id: 'in2',
          type: PortType.number,
          name: 'Threshold',
          isInput: true,
        ));
        ports.add(Port(
          id: 'out',
          type: PortType.boolean,
          name: 'Result',
          isInput: false,
        ));
        break;
    }

    return CanvasItem(
      type: WidgetType.treenode,
      position: position,
      size: size,
      id: id,
      label: type,
      ports: ports,
      category: ComponentCategory.logic,
      properties: {'logic_type': type},
      rowCount: rowCount,
    );
  }

  static CanvasItem createMathItem(String type, Offset position) {
    final id = const Uuid().v4();
    const size = Size(120, 80);
    final ports = <Port>[];
    int rowCount = 3;

    switch (type) {
      case 'ADD':
      case 'SUBTRACT':
      case 'MULTIPLY':
      case 'DIVIDE':
      case 'MODULO':
      case 'POWER':
        rowCount = 3;
        ports.add(Port(
          id: 'in1',
          type: PortType.number,
          name: 'Value 1',
          isInput: true,
        ));
        ports.add(Port(
          id: 'in2',
          type: PortType.number,
          name: 'Value 2',
          isInput: true,
        ));
        ports.add(Port(
          id: 'out',
          type: PortType.number,
          name: 'Output',
          isInput: false,
        ));
        break;
    }

    return CanvasItem(
      type: WidgetType.treenode,
      position: position,
      size: size,
      id: id,
      label: type,
      ports: ports,
      category: ComponentCategory.math,
      properties: {'operation': type},
      rowCount: rowCount,
    );
  }

  static CanvasItem createPointItem(String type, Offset position) {
    final id = const Uuid().v4();
    const size = Size(120, 80);
    final ports = <Port>[];
    int rowCount = 1;

    switch (type) {
      case 'NumericPoint':
        ports.add(Port(
          id: 'out',
          type: PortType.number,
          name: 'Value',
          isInput: false,
        ));
        break;

      case 'NumericWritable':
        rowCount = 3;
        ports.add(Port(
          id: 'in1',
          type: PortType.number,
          name: 'Value 1',
          isInput: true,
        ));
        ports.add(Port(
          id: 'in2',
          type: PortType.number,
          name: 'Value 2',
          isInput: true,
        ));
        ports.add(Port(
          id: 'out',
          type: PortType.number,
          name: 'NumericWritable',
          isInput: false,
        ));
        break;

      case 'StringPoint':
        ports.add(Port(
          id: 'out',
          type: PortType.string,
          name: 'StringPoint',
          isInput: false,
        ));
        break;

      case 'StringWritable':
        ports.add(Port(
          id: 'in1',
          type: PortType.string,
          name: 'Value 1',
          isInput: true,
        ));
        ports.add(Port(
          id: 'in2',
          type: PortType.string,
          name: 'Value 2',
          isInput: true,
        ));
        ports.add(Port(
          id: 'out',
          type: PortType.string,
          name: 'StringWritable',
          isInput: false,
        ));
        break;
      case 'BooleanPoint':
        ports.add(Port(
          id: 'out',
          type: PortType.boolean,
          name: 'BooleanPoint',
          isInput: false,
        ));
        break;
      case 'BooleanWritable':
        ports.add(Port(
          id: 'in1',
          type: PortType.boolean,
          name: 'Value 1',
          isInput: true,
        ));
        ports.add(Port(
          id: 'in2',
          type: PortType.boolean,
          name: 'Value 2',
          isInput: true,
        ));
        ports.add(Port(
          id: 'out',
          type: PortType.boolean,
          name: 'BooleanWritable',
          isInput: false,
        ));
        break;
    }

    return CanvasItem(
      type: WidgetType.treenode,
      position: position,
      size: size,
      id: id,
      label: type,
      ports: ports,
      category: ComponentCategory.point,
      properties: {'point': type},
      rowCount: rowCount,
    );
  }

  static CanvasItem createDeviceItem(HelvarDevice device, Offset position) {
    final id = const Uuid().v4();
    const size = Size(150, 100);
    final ports = <Port>[];
    int rowCount = 7;

    ports.add(Port(
      id: 'status',
      type: PortType.string,
      name: 'Status',
      isInput: false,
    ));

    ports.add(Port(
      id: DeviceAction.clearResult.name,
      type: DeviceAction.clearResult.portType,
      name: DeviceAction.clearResult.displayName,
      isInput: true,
    ));

    if (device.helvarType == 'output') {
      // Add output device specific ports that match the context menu actions
      ports.add(Port(
        id: DeviceAction.recallScene.name,
        type: DeviceAction.recallScene.portType,
        name: DeviceAction.recallScene.displayName,
        isInput: true,
      ));

      ports.add(Port(
        id: DeviceAction.directLevel.name,
        type: DeviceAction.directLevel.portType,
        name: DeviceAction.directLevel.displayName,
        isInput: true,
      ));

      ports.add(Port(
        id: DeviceAction.directProportion.name,
        type: DeviceAction.directProportion.portType,
        name: DeviceAction.directProportion.displayName,
        isInput: true,
      ));

      ports.add(Port(
        id: DeviceAction.modifyProportion.name,
        type: DeviceAction.modifyProportion.portType,
        name: DeviceAction.modifyProportion.displayName,
        isInput: true,
      ));
    } else if (device.helvarType == 'input') {
      if (device.isButtonDevice) {
        for (int i = 1; i <= 5; i++) {
          ports.add(Port(
            id: 'button$i',
            type: PortType.boolean,
            name: 'Button $i',
            isInput: false,
          ));
        }
      }

      if (device.isMultisensor) {
        ports.add(Port(
          id: 'presence',
          type: PortType.boolean,
          name: 'Presence',
          isInput: false,
        ));
      }
    } else if (device.helvarType == 'emergency') {
      ports.add(Port(
        id: DeviceAction.emergencyFunctionTest.name,
        type: DeviceAction.emergencyFunctionTest.portType,
        name: DeviceAction.emergencyFunctionTest.displayName,
        isInput: true,
      ));

      ports.add(Port(
        id: DeviceAction.emergencyDurationTest.name,
        type: DeviceAction.emergencyDurationTest.portType,
        name: DeviceAction.emergencyDurationTest.displayName,
        isInput: true,
      ));

      ports.add(Port(
        id: DeviceAction.stopEmergencyTest.name,
        type: DeviceAction.stopEmergencyTest.portType,
        name: DeviceAction.stopEmergencyTest.displayName,
        isInput: true,
      ));

      ports.add(Port(
        id: DeviceAction.resetEmergencyBattery.name,
        type: DeviceAction.resetEmergencyBattery.portType,
        name: DeviceAction.resetEmergencyBattery.displayName,
        isInput: true,
      ));

      ports.add(Port(
        id: 'emergency_state',
        type: PortType.boolean,
        name: 'Emergency State',
        isInput: false,
      ));

      ports.add(Port(
        id: 'battery_level',
        type: PortType.number,
        name: 'Battery Level',
        isInput: false,
      ));
    }

    return CanvasItem(
      type: WidgetType.treenode,
      position: position,
      size: size,
      id: id,
      label: device.description.isEmpty
          ? 'Device ${device.deviceId}'
          : device.description,
      ports: ports,
      properties: {
        'device_id': device.deviceId,
        'device_address': device.address,
        'device_type': device.helvarType,
      },
      rowCount: rowCount,
    );
  }

  static CanvasItem createUIItem(String type, Offset position) {
    final id = const Uuid().v4();
    const size = Size(120, 80);
    final ports = <Port>[];
    int rowCount = 2;

    switch (type) {
      case 'Button':
        ports.add(Port(
          id: 'click',
          type: PortType.boolean,
          name: 'Click',
          isInput: false,
        ));
        ports.add(Port(
          id: 'label',
          type: PortType.string,
          name: 'Label',
          isInput: true,
        ));
        break;

      case 'Text':
        ports.add(Port(
          id: 'text',
          type: PortType.string,
          name: 'Text',
          isInput: true,
        ));
        break;
    }

    return CanvasItem(
      type: WidgetType.treenode,
      position: position,
      size: size,
      id: id,
      label: type,
      ports: ports,
      category: ComponentCategory.ui,
      properties: {'ui_type': type},
      rowCount: rowCount,
    );
  }

  static CanvasItem createUtilItem(String type, Offset position) {
    final id = const Uuid().v4();
    const size = Size(120, 80);
    final ports = <Port>[];
    int rowCount = 2;

    switch (type) {
      case 'Ramp':
        ports.add(Port(
          id: 'out',
          type: PortType.number,
          name: 'Value',
          isInput: false,
        ));
        ports.add(Port(
          id: 'min',
          type: PortType.number,
          name: 'Min',
          isInput: true,
        ));
        ports.add(Port(
          id: 'max',
          type: PortType.number,
          name: 'Max',
          isInput: true,
        ));
        ports.add(Port(
          id: 'period',
          type: PortType.number,
          name: 'Period (s)',
          isInput: true,
        ));
        rowCount = 4;
        break;

      case 'Toggle':
        ports.add(Port(
          id: 'out',
          type: PortType.boolean,
          name: 'Value',
          isInput: false,
        ));
        ports.add(Port(
          id: 'toggle',
          type: PortType.boolean,
          name: 'Toggle',
          isInput: true,
        ));
        break;
    }

    return CanvasItem(
      type: WidgetType.treenode,
      position: position,
      size: size,
      id: id,
      label: type,
      ports: ports,
      category: ComponentCategory.util,
      properties: {
        'util_type': type,
        // Default values
        'min': 0,
        'max': 100,
        'period': 10.0, // 10 seconds for Ramp
      },
      rowCount: rowCount,
    );
  }

  CanvasItem copyWith({
    WidgetType? type,
    Offset? position,
    Size? size,
    String? id,
    String? label,
    Map<String, dynamic>? properties,
    int? rowCount,
  }) {
    return CanvasItem(
      type: type ?? this.type,
      position: position ?? this.position,
      size: size ?? this.size,
      id: id ?? this.id,
      label: label ?? this.label,
      rowCount: rowCount ?? this.rowCount,
      properties: properties ?? Map.from(this.properties),
      ports: ports,
      category: category,
    );
  }
}

enum ComponentCategory {
  logic,
  math,
  point,
  ui,
  util,
}
