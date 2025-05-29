import 'package:flutter/material.dart';
import 'package:flutter_simple_treeview/flutter_simple_treeview.dart';
import 'package:grms_designer/niagara/models/component_type.dart';
import 'package:grms_designer/utils/device_utils.dart';
import 'package:grms_designer/utils/general_ui.dart';

TreeNode buildLogicComponentsNode(BuildContext context) {
  return TreeNode(
    content: GestureDetector(
      onDoubleTap: () {
        // Expandable section logic if needed
      },
      child: const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text(
          "Components",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    ),
    children: [
      TreeNode(
        content: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text("Logic", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        children: [
          TreeNode(
            content: _buildDraggableComponentItem(
              const ComponentType(ComponentType.AND_GATE),
            ),
          ),
          TreeNode(
            content: _buildDraggableComponentItem(
              const ComponentType(ComponentType.OR_GATE),
            ),
          ),
          TreeNode(
            content: _buildDraggableComponentItem(
              const ComponentType(ComponentType.IS_GREATER_THAN),
            ),
          ),
        ],
      ),
      TreeNode(
        content: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text("Math", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        children: [
          TreeNode(
            content: _buildDraggableComponentItem(
              const ComponentType(ComponentType.ADD),
            ),
          ),
          TreeNode(
            content: _buildDraggableComponentItem(
              const ComponentType(ComponentType.SUBTRACT),
            ),
          ),
          TreeNode(
            content: _buildDraggableComponentItem(
              const ComponentType(ComponentType.MULTIPLY),
            ),
          ),
          TreeNode(
            content: _buildDraggableComponentItem(
              const ComponentType(ComponentType.DIVIDE),
            ),
          ),
          TreeNode(
            content: _buildDraggableComponentItem(
              const ComponentType(ComponentType.MAX),
            ),
          ),
          TreeNode(
            content: _buildDraggableComponentItem(
              const ComponentType(ComponentType.MIN),
            ),
          ),
          TreeNode(
            content: _buildDraggableComponentItem(
              const ComponentType(ComponentType.POWER),
            ),
          ),
          TreeNode(
            content: _buildDraggableComponentItem(
              const ComponentType(ComponentType.ABS),
            ),
          ),
        ],
      ),
      TreeNode(
        content: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text("UI", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        children: [
          TreeNode(
            content: _buildDraggableComponentItem(
              const ComponentType("Button"),
            ),
          ),
          TreeNode(
            content: _buildDraggableComponentItem(const ComponentType("Text")),
          ),
        ],
      ),
      TreeNode(
        content: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text("Util", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        children: [
          TreeNode(
            content: _buildDraggableComponentItem(const ComponentType("Ramp")),
          ),
          TreeNode(
            content: _buildDraggableComponentItem(
              const ComponentType("Toggle"),
            ),
          ),
        ],
      ),
      TreeNode(
        content: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text("Points", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        children: [
          TreeNode(
            content: _buildDraggableComponentItem(
              const ComponentType(ComponentType.BOOLEAN_POINT),
            ),
          ),
          TreeNode(
            content: _buildDraggableComponentItem(
              const ComponentType(ComponentType.BOOLEAN_WRITABLE),
            ),
          ),
          TreeNode(
            content: _buildDraggableComponentItem(
              const ComponentType(ComponentType.STRING_POINT),
            ),
          ),
          TreeNode(
            content: _buildDraggableComponentItem(
              const ComponentType(ComponentType.STRING_WRITABLE),
            ),
          ),
          TreeNode(
            content: _buildDraggableComponentItem(
              const ComponentType(ComponentType.NUMERIC_POINT),
            ),
          ),
          TreeNode(
            content: _buildDraggableComponentItem(
              const ComponentType(ComponentType.NUMERIC_WRITABLE),
            ),
          ),
        ],
      ),
    ],
  );
}

Widget _buildDraggableComponentItem(ComponentType type) {
  final comp = Column(
    children: [
      Icon(getIconForComponentType(type)),
      const SizedBox(height: 4.0),
      Text(getNameForComponentType(type), style: const TextStyle(fontSize: 12)),
    ],
  );
  return Draggable<ComponentType>(
    data: type,
    feedback: Material(
      elevation: 4.0,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4.0),
          border: Border.all(color: Colors.indigo),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(getIconForComponentType(type), size: 24),
            const SizedBox(height: 4.0),
            Text(
              getNameForComponentType(type),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    ),
    childWhenDragging: Opacity(
      opacity: 0.3,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: comp,
      ),
    ),
    child: Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: comp,
    ),
  );
}
