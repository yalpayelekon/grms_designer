import 'package:flutter/material.dart';
import 'package:flutter_simple_treeview/flutter_simple_treeview.dart';
import 'widget_type.dart';

class CanvasItem extends TreeNode {
  final WidgetType type;
  Offset position;
  Size size;
  Map<String, dynamic> properties;

  CanvasItem({
    required this.type,
    required this.position,
    required this.size,
    Map<String, dynamic>? properties,
  }) : properties = properties ?? {};
}
