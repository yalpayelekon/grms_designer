import 'package:flutter/material.dart';
import 'package:flutter_simple_treeview/flutter_simple_treeview.dart';
import 'package:uuid/uuid.dart';
import 'helvar_models/helvar_device.dart';
import 'link.dart';
import 'widget_type.dart';

class CanvasItem extends TreeNode {
  final WidgetType type;
  Offset position;
  Size size;
  Map<String, dynamic> properties;
  String? id;
  String? label;
  List<Port> ports;
  ComponentCategory category;
  CanvasItem({
    required this.type,
    required this.position,
    required this.size,
    this.id,
    List<Port>? ports,
    this.category = ComponentCategory.ui,
    this.label,
    Map<String, dynamic>? properties,
  })  : properties = properties ?? {},
        ports = ports ?? [],
        super(content: Text(label ?? "Item"));

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
      category: ComponentCategory.values.firstWhere(
        (e) => e.toString() == 'ComponentCategory.${json['category']}',
        orElse: () => ComponentCategory.ui,
      ),
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

    switch (type) {
      case 'AND':
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

      case 'OR':
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
        ports.add(Port(
          id: 'condition',
          type: PortType.boolean,
          name: 'Condition',
          isInput: true,
        ));
        ports.add(Port(
          id: 'true',
          type: PortType.any,
          name: 'True',
          isInput: false,
        ));
        ports.add(Port(
          id: 'false',
          type: PortType.any,
          name: 'False',
          isInput: false,
        ));
        break;

      case 'ADD':
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
          name: 'Sum',
          isInput: false,
        ));
        break;

      case 'SUBTRACT':
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
          name: 'Difference',
          isInput: false,
        ));
        break;
    }

    return CanvasItem(
      type: WidgetType.text,
      position: position,
      size: size,
      id: id,
      label: type,
      ports: ports,
      category: ComponentCategory.logic,
      properties: {'logic_type': type},
    );
  }

  static CanvasItem createDeviceItem(HelvarDevice device, Offset position) {
    final id = const Uuid().v4();

    const size = Size(150, 100);

    final ports = <Port>[];

    ports.add(Port(
      id: 'status',
      type: PortType.boolean,
      name: 'Status',
      isInput: false,
    ));

    if (device.helvarType == 'output') {
      ports.add(Port(
        id: 'level',
        type: PortType.number,
        name: 'Level',
        isInput: true,
      ));

      ports.add(Port(
        id: 'currentLevel',
        type: PortType.number,
        name: 'Current Level',
        isInput: false,
      ));
    } else if (device.helvarType == 'input') {
      ports.add(Port(
        id: 'trigger',
        type: PortType.boolean,
        name: 'Trigger',
        isInput: false,
      ));

      if (device.isButtonDevice) {
        // For each button, add a button state port
        for (int i = 1; i <= 7; i++) {
          ports.add(Port(
            id: 'button$i',
            type: PortType.boolean,
            name: 'Button $i',
            isInput: false,
          ));
        }
      }

      // If it's a multisensor
      if (device.isMultisensor) {
        ports.add(Port(
          id: 'presence',
          type: PortType.boolean,
          name: 'Presence',
          isInput: false,
        ));

        ports.add(Port(
          id: 'light_level',
          type: PortType.number,
          name: 'Light Level',
          isInput: false,
        ));
      }
    } else if (device.helvarType == 'emergency') {
      ports.add(Port(
        id: 'test',
        type: PortType.boolean,
        name: 'Test',
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
      type: WidgetType.text,
      position: position,
      size: size,
      id: id,
      label: device.description.isEmpty
          ? 'Device ${device.deviceId}'
          : device.description,
      ports: ports,
      category: ComponentCategory.treeview,
      properties: {
        'device_id': device.deviceId,
        'device_address': device.address,
        'device_type': device.helvarType,
      },
    );
  }

  CanvasItem copyWith({
    WidgetType? type,
    Offset? position,
    Size? size,
    String? id,
    String? label,
    Map<String, dynamic>? properties,
  }) {
    return CanvasItem(
      type: type ?? this.type,
      position: position ?? this.position,
      size: size ?? this.size,
      id: id ?? this.id,
      label: label ?? this.label,
      properties: properties ?? Map.from(this.properties),
    );
  }
}

enum ComponentCategory {
  ui,
  treeview,
  logic,
}
