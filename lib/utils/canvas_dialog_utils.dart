import 'package:flutter/material.dart';
import 'package:grms_designer/niagara/controllers/canvas_interaction_controller.dart';
import 'package:grms_designer/niagara/controllers/clipboard_manager.dart';
import 'package:grms_designer/niagara/models/component.dart';
import 'package:grms_designer/niagara/models/component_type.dart';
import 'package:grms_designer/niagara/models/ramp_component.dart';
import 'package:grms_designer/niagara/models/rectangle.dart';
import 'package:grms_designer/utils/canvas_utils.dart';
import 'package:grms_designer/utils/device_utils.dart';
import 'package:grms_designer/utils/general_ui.dart';

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
                        'Custom Components',
                        [RectangleComponent.RECTANGLE, RampComponent.RAMP],
                        position,
                        addNewComponent,
                      ),
                      buildComponentCategorySection(
                        context,
                        'Logic Gates',
                        [
                          ComponentType.AND_GATE,
                          ComponentType.OR_GATE,
                          ComponentType.XOR_GATE,
                          ComponentType.NOT_GATE,
                        ],
                        position,
                        addNewComponent,
                      ),
                      buildComponentCategorySection(
                        context,
                        'Math Operations',
                        [
                          ComponentType.ADD,
                          ComponentType.SUBTRACT,
                          ComponentType.MULTIPLY,
                          ComponentType.DIVIDE,
                          ComponentType.MAX,
                          ComponentType.MIN,
                          ComponentType.POWER,
                          ComponentType.ABS,
                        ],
                        position,
                        addNewComponent,
                      ),
                      buildComponentCategorySection(
                        context,
                        'Comparisons',
                        [
                          ComponentType.IS_GREATER_THAN,
                          ComponentType.IS_LESS_THAN,
                          ComponentType.IS_EQUAL,
                        ],
                        position,
                        addNewComponent,
                      ),
                      buildComponentCategorySection(
                        context,
                        'Writable Points',
                        [
                          ComponentType.BOOLEAN_WRITABLE,
                          ComponentType.NUMERIC_WRITABLE,
                          ComponentType.STRING_WRITABLE,
                        ],
                        position,
                        addNewComponent,
                      ),
                      buildComponentCategorySection(
                        context,
                        'Read-Only Points',
                        [
                          ComponentType.BOOLEAN_POINT,
                          ComponentType.NUMERIC_POINT,
                          ComponentType.STRING_POINT,
                        ],
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
  List<ComponentType> types = typeStrings.map((t) => ComponentType(t)).toList();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 12.0, bottom: 6.0),
        child: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      const Divider(),
      Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: types.map((type) {
          return InkWell(
            onTap: () {
              addNewComponent(type, clickPosition: position);
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Column(
                children: [
                  Icon(getIconForComponentType(type)),
                  const SizedBox(height: 4.0),
                  Text(
                    getNameForComponentType(type),
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
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
  Offset pastePosition,
  Function(Offset, int, bool) handlePasteSpecialComponent,
) {
  if (clipboardManager.isEmpty) return;

  TextEditingController copiesController = TextEditingController(text: '1');
  ValueNotifier<bool> keepConnections = ValueNotifier<bool>(true);

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.copy, size: 20),
            SizedBox(width: 8),
            Text('Paste Special'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Number of copies'),
                const SizedBox(width: 12),
                SizedBox(
                  width: 50,
                  child: TextField(
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 0,
                      ),
                      border: OutlineInputBorder(),
                    ),
                    controller: copiesController,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<bool>(
              valueListenable: keepConnections,
              builder: (context, value, child) {
                return Row(
                  children: [
                    Checkbox(
                      value: value,
                      onChanged: (newValue) {
                        keepConnections.value = newValue ?? true;
                      },
                    ),
                    const Text('Keep all links'),
                  ],
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              int copies = int.tryParse(copiesController.text) ?? 1;
              copies = copies.clamp(1, 20);
              handlePasteSpecialComponent(
                pastePosition,
                copies,
                keepConnections.value,
              );
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}

void showCanvasContextMenu(
  BuildContext context,
  Offset globalPosition,
  GlobalKey canvasKey,
  ClipboardManager clipboardManager,
  CanvasInteractionController canvasController,
  Function(Offset) handlePasteComponent,
  Function(Offset) showAddComponentDialog,
  Function(Offset) showPasteSpecialDialog,
  Function() selectAllComponents,
) {
  final canvasBox = canvasKey.currentContext?.findRenderObject() as RenderBox?;
  final canvasPosition = canvasBox != null
      ? canvasController.getCanvasPosition(globalPosition, canvasBox)
      : null;

  if (canvasPosition == null) return;

  final RenderBox overlay =
      Overlay.of(context).context.findRenderObject() as RenderBox;

  showMenu(
    context: context,
    position: RelativeRect.fromRect(
      Rect.fromPoints(globalPosition, globalPosition),
      Offset.zero & overlay.size,
    ),
    items: [...canvasMenuOptions(clipboardManager)],
  ).then((value) {
    if (value == null) return;

    switch (value) {
      case 'add-component':
        showAddComponentDialog(canvasPosition);
        break;
      case 'paste':
        handlePasteComponent(canvasPosition);
        break;
      case 'paste-special':
        showPasteSpecialDialog(canvasPosition);
        break;
      case 'select-all':
        selectAllComponents();
        break;
    }
  });
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
  bool hasMultipleSelection,
) {
  final RenderBox overlay =
      Overlay.of(context).context.findRenderObject() as RenderBox;

  showMenu(
    context: context,
    position: RelativeRect.fromRect(
      Rect.fromPoints(position, position),
      Offset.zero & overlay.size,
    ),
    items: showContextMenuOptions(clipboardManager),
  ).then((value) {
    if (value == null) return;

    switch (value) {
      case 'copy':
        if (hasMultipleSelection) {
          handleCopyMultipleComponents();
        } else {
          handleCopyComponent(component);
        }
        break;
      case 'edit':
        handleEditComponent(context, component);
        break;
      case 'delete':
        handleDeleteComponent(component);
        break;
    }
  });
}
