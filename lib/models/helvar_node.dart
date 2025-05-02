import 'package:flutter/material.dart';
import 'package:flutter_simple_treeview/flutter_simple_treeview.dart';

enum TreeViewNodeType {
  group,
  inputDevice,
  inputDeviceNode,
  outputDevice,
  outputDeviceNode,
}

class TreeViewNode extends TreeNode {
  final String id;
  final String name;
  final TreeViewNodeType nodeType;

  TreeViewNode({
    required this.id,
    required this.name,
    required this.nodeType,
    super.children,
  }) : super(content: Text(name));
}
