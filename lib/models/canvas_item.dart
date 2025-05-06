import 'package:flutter/material.dart';
import 'package:flutter_simple_treeview/flutter_simple_treeview.dart';
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

  // Factory methods for creating different types of items
  static CanvasItem createLogicItem(String type, Offset position) {
    // Create a specific logic item based on type with appropriate ports
  }

  static CanvasItem createDeviceItem(HelvarDevice device, Offset position) {
    // Create a device item with appropriate ports based on device type
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
