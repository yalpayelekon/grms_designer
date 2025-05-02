import 'package:flutter/material.dart';
import 'helvar_node.dart';
import 'widget_type.dart';

class CanvasItem extends TreeViewNode {
  final WidgetType type;
  Offset position;
  Size size;
  Map<String, dynamic> properties;
  String? label;

  CanvasItem({
    required this.type,
    required this.position,
    required this.size,
    this.label,
    super.children,
    Map<String, dynamic>? properties,
  })  : properties = properties ?? {},
        super(
          id: UniqueKey().toString(),
          name: label ?? "Item",
          nodeType: TreeViewNodeType.outputDeviceNode,
        );

  factory CanvasItem.fromJson(Map<String, dynamic> json) {
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
      label: json['label'] as String?,
      properties: json['properties'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
      label: label ?? this.label,
      properties: properties ?? Map.from(this.properties),
    );
  }
}
