import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_simple_treeview/flutter_simple_treeview.dart';
import 'package:grms_designer/providers/flowsheet_provider.dart';
import 'package:grms_designer/screens/dialogs/flowsheet_actions.dart';
import 'package:grms_designer/widgets/app_tree_view.dart';

TreeNode buildProjectNode(
  AppTreeView widget,
  BuildContext context,
  WidgetRef ref,
) {
  return TreeNode(
    content: GestureDetector(
      onDoubleTap: () {
        widget.setActiveNode('project');
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          "Project",
          style: TextStyle(
            fontWeight: widget.showingProject
                ? FontWeight.bold
                : FontWeight.normal,
            color: widget.showingProject ? Colors.blue : null,
          ),
        ),
      ),
    ),
    children: [
      TreeNode(
        content: GestureDetector(
          onDoubleTap: () {
            widget.setActiveNode('settings');
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Settings",
              style: TextStyle(
                fontWeight: widget.openSettings
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: widget.openSettings ? Colors.blue : null,
              ),
            ),
          ),
        ),
      ),
      TreeNode(
        content: GestureDetector(
          onDoubleTap: () {
            widget.setActiveNode('files');
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Files",
              style: TextStyle(
                fontWeight:
                    widget.currentFileDirectory != null && !widget.showingImages
                    ? FontWeight.bold
                    : FontWeight.normal,
                color:
                    widget.currentFileDirectory != null && !widget.showingImages
                    ? Colors.blue
                    : null,
              ),
            ),
          ),
        ),
        children: [
          TreeNode(
            content: GestureDetector(
              onDoubleTap: () {
                widget.setActiveNode('images');
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Images",
                  style: TextStyle(
                    fontWeight: widget.showingImages
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: widget.showingImages ? Colors.blue : null,
                  ),
                ),
              ),
            ),
          ),
          TreeNode(
            content: GestureDetector(
              onDoubleTap: () {
                widget.setActiveNode('graphics');
              },
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  "Graphics",
                  style: TextStyle(fontWeight: FontWeight.normal),
                ),
              ),
            ),
            children: [
              TreeNode(
                content: GestureDetector(
                  onDoubleTap: () {
                    widget.setActiveNode('graphicsDetail');
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      "Graphics 1",
                      style: TextStyle(fontWeight: FontWeight.normal),
                    ),
                  ),
                ),
              ),
            ],
          ),
          TreeNode(
            content: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onDoubleTap: () {
                    widget.setActiveNode('wiresheets');
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "Flowsheets",
                      style: TextStyle(
                        fontWeight: widget.openWiresheet
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: widget.openWiresheet ? Colors.blue : null,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  tooltip: 'Create New Flowsheet',
                  onPressed: () => createNewFlowsheet(context, ref),
                ),
              ],
            ),
            children: [
              ...widget.wiresheets.map(
                (wiresheet) => TreeNode(
                  content: GestureDetector(
                    onDoubleTap: () {
                      final activeFlowsheetId = ref
                          .read(flowsheetsProvider.notifier)
                          .activeFlowsheetId;

                      if (activeFlowsheetId != null &&
                          activeFlowsheetId != wiresheet.id) {
                        ref
                            .read(flowsheetsProvider.notifier)
                            .saveActiveFlowsheet();
                      }

                      widget.setActiveNode(
                        'wiresheet',
                        wiresheetId: wiresheet.id,
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            wiresheet.name,
                            style: TextStyle(
                              fontWeight:
                                  widget.selectedWiresheetId == wiresheet.id
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: widget.selectedWiresheetId == wiresheet.id
                                  ? Colors.blue
                                  : null,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 18),
                          tooltip: 'Delete Flowsheet',
                          onPressed: () async {
                            final result = await confirmDeleteFlowsheet(
                              context,
                              wiresheet.id,
                              wiresheet.name,
                              ref,
                            );

                            if (result && context.mounted) {
                              if (widget.selectedWiresheetId == wiresheet.id) {
                                widget.setActiveNode('wiresheets');
                              }

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Flowsheet deleted'),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
