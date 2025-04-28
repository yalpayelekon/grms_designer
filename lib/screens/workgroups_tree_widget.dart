import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_simple_treeview/flutter_simple_treeview.dart';
import '../models/workgroup.dart';
import 'package:grms_designer/screens/workgroup_detail_screen.dart';
import 'widget_type.dart';

import 'home_screen.dart';
import '../providers/workgroups_provider.dart';

class WorkgroupsTreeWidget extends ConsumerWidget {
  const WorkgroupsTreeWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workgroups = ref.watch(workgroupsProvider);

    return _buildWorkgroupsNode(context, workgroups);
  }

  // It should be used by the parent TreeView, not directly returned from build
  TreeNode buildTreeNode(BuildContext context, List<Workgroup> workgroups) {
    return TreeNode(
      content: ElevatedButton.icon(
        icon: const Icon(Icons.group_work),
        label: const Text('Workgroups'),
        onPressed: () {
          // Find the closest HomeScreenState and set openWorkGroup to true
          final HomeScreenState? homeState =
              context.findAncestorStateOfType<HomeScreenState>();
          if (homeState != null) {
            homeState.setState(() {
              homeState.openWorkGroup = true;
            });
          }
        },
      ),
      children: [
        // Create a TreeNode for each workgroup
        ...workgroups.map(
          (workgroup) => TreeNode(
            content: ElevatedButton.icon(
              icon: const Icon(Icons.lan),
              label: Text(workgroup.description),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        WorkgroupDetailScreen(workgroup: workgroup),
                  ),
                );
              },
            ),
            children: [
              // Include router information for each workgroup
              ...workgroup.routers.map(
                (router) => TreeNode(
                  content: ListTile(
                    dense: true,
                    title: Text(router.name),
                    subtitle: Text(router.ipAddress),
                    leading: const Icon(Icons.router, size: 18),
                  ),
                ),
              ),
              // Include the Text widget as a child node
              TreeNode(
                content:
                    _buildDraggable('Text', Icons.text_fields, WidgetType.text),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // This method is called from build() and must return a Widget
  Widget _buildWorkgroupsNode(
      BuildContext context, List<Workgroup> workgroups) {
    // For debugging or reference only
    // In actual use, the parent TreeView will use buildTreeNode()
    return Container(
      child: const Text(
          "This widget should not be visible directly - it should be used inside a TreeView"),
    );
  }

  Widget _buildDraggable(String label, IconData icon, WidgetType type) {
    return Draggable<WidgetData>(
      data: WidgetData(type: type),
      feedback: Material(
        elevation: 4.0,
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [Icon(icon), const SizedBox(width: 8.0), Text(label)],
          ),
        ),
      ),
      childWhenDragging: Row(
        children: [
          Icon(icon, color: Colors.grey[600]),
          const SizedBox(width: 8.0),
          Text(label, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
      child: Row(
        children: [Icon(icon), const SizedBox(width: 8.0), Text(label)],
      ),
    );
  }
}
