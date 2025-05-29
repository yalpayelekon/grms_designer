import 'package:flutter/material.dart';
import 'package:grms_designer/niagara/controllers/canvas_interaction_controller.dart';
import 'package:grms_designer/niagara/controllers/clipboard_manager.dart';
import 'package:grms_designer/niagara/models/component.dart';
import 'package:grms_designer/niagara/models/component_type.dart';

void showAddComponentDialogAtPosition(
  BuildContext context,
  Offset position,
  Function(ComponentType, {Offset? clickPosition}) addNewComponent,
) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        child: SizedBox(
          width: 400,
          height: 600,
          child: Column(
            children: [
              AppBar(
                title: const Text('Add Component'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      buildComponentCategorySection(
                        context,
                        'Devices',
                        ['DALI_DEVICE', 'RCM_DEVICE'],
                        position,
                        addNewComponent,
                      ),
                      buildComponentCategorySection(
                        context,
                        'Inputs',
                        ['BUTTON_POINT', 'VARIABLE'],
                        position,
                        addNewComponent,
                      ),
                      buildComponentCategorySection(
                        context,
                        'Logics',
                        ['OR', 'AND', 'NOT', 'DELAY', 'LATCH'],
                        position,
                        addNewComponent,
                      ),
                      buildComponentCategorySection(
                        context,
                        'Controls',
                        ['SLIDER', 'BUTTON'],
                        position,
                        addNewComponent,
                      ),
                      buildComponentCategorySection(
                        context,
                        'Outputs',
                        ['OUTPUT'],
                        position,
                        addNewComponent,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget buildComponentCategorySection(
  BuildContext context,
  String title,
  List<String> typeStrings,
  Offset position,
  Function(ComponentType, {Offset? clickPosition}) addNewComponent,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      Wrap(
        children: typeStrings.map((typeString) {
          return InkWell(
            onTap: () {
              ComponentType type = ComponentType.fromString(typeString);
              addNewComponent(type, clickPosition: position);
              Navigator.of(context).pop();
            },
            child: SizedBox(
              width: 100,
              height: 100,
              child: Card(child: Center(child: Text(typeString))),
            ),
          );
        }).toList(),
      ),
    ],
  );
}

void showPasteSpecialDialog(
  BuildContext context,
  ClipboardManager clipboardManager,
  Function(Offset, int, bool) handlePasteSpecialComponent,
) {
  // move implementation here
}

void showCanvasContextMenu(
  BuildContext context,
  Offset globalPosition,
  ClipboardManager clipboardManager,
  CanvasInteractionController canvasController,
  Function(Offset) handlePasteComponent,
  Function(Offset) showPasteSpecialDialog,
) {
  // move implementation here
}

void showComponentContextMenu(
  BuildContext context,
  Offset position,
  Component component,
  ClipboardManager clipboardManager,
  Function(Component) handleCopyComponent,
  Function(BuildContext, Component) handleEditComponent,
  Function(Component) handleDeleteComponent,
  Function() handleCopyMultipleComponents,
) {
  // move implementation here
}
