import 'package:flutter/material.dart';
import 'package:grms_designer/niagara/controllers/canvas_interaction_controller.dart';
import 'package:grms_designer/niagara/controllers/clipboard_manager.dart';
import 'package:grms_designer/niagara/controllers/flow_editor_state.dart';

Offset getDefaultPosition(
  CanvasInteractionController canvasController,
  FlowEditorState editorState,
) {
  final RenderBox? viewerChildRenderBox =
      editorState.interactiveViewerChildKey.currentContext?.findRenderObject()
          as RenderBox?;

  if (viewerChildRenderBox != null) {
    final viewportSize = viewerChildRenderBox.size;
    final viewportCenter = Offset(
      viewportSize.width / 2,
      viewportSize.height / 2,
    );

    return canvasController.getCanvasPosition(
          viewportCenter,
          viewerChildRenderBox,
        ) ??
        Offset(
          canvasController.canvasSize.width / 2,
          canvasController.canvasSize.height / 2,
        );
  }

  return Offset(
    canvasController.canvasSize.width / 2,
    canvasController.canvasSize.height / 2,
  );
}

List<PopupMenuEntry<String>> canvasMenuOptions(
  ClipboardManager clipboardManager,
) {
  return [
    PopupMenuItem(
      value: 'paste',
      enabled: !clipboardManager.isEmpty,
      child: Row(
        children: [
          Icon(
            Icons.content_paste,
            size: 18,
            color: !clipboardManager.isEmpty ? null : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            'Paste',
            style: TextStyle(
              color: !clipboardManager.isEmpty ? null : Colors.grey,
            ),
          ),
        ],
      ),
    ),
    PopupMenuItem(
      value: 'paste-special',
      enabled: !clipboardManager.isEmpty,
      child: Row(
        children: [
          Icon(
            Icons.copy_all,
            size: 18,
            color: !clipboardManager.isEmpty ? null : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            'Paste Special...',
            style: TextStyle(
              color: !clipboardManager.isEmpty ? null : Colors.grey,
            ),
          ),
        ],
      ),
    ),
    const PopupMenuItem(
      value: 'add-component',
      child: Row(
        children: [
          Icon(Icons.add_box, size: 18),
          SizedBox(width: 8),
          Text('Add New Component...'),
        ],
      ),
    ),
    const PopupMenuItem(
      value: 'select-all',
      child: Row(
        children: [
          Icon(Icons.select_all, size: 18),
          SizedBox(width: 8),
          Text('Select All'),
        ],
      ),
    ),
  ];
}

List<PopupMenuEntry<String>> showContextMenuOptions(
  ClipboardManager clipboardManager,
) {
  return [
    const PopupMenuItem(
      value: 'copy',
      child: Row(
        children: [
          Icon(Icons.copy, size: 18),
          SizedBox(width: 8),
          Text('Copy'),
        ],
      ),
    ),
    const PopupMenuItem(
      value: 'edit',
      child: Row(
        children: [
          Icon(Icons.edit, size: 18),
          SizedBox(width: 8),
          Text('Edit'),
        ],
      ),
    ),
    const PopupMenuItem(
      value: 'delete',
      child: Row(
        children: [
          Icon(Icons.delete, size: 18),
          SizedBox(width: 8),
          Text('Delete'),
        ],
      ),
    ),
  ];
}

AlertDialog showPasteSpecialDialog(
  BuildContext context,
  TextEditingController copiesController,
  ValueNotifier<bool> keepConnections,
  Function handlePasteSpecialComponent,
  Offset pastePosition,
) {
  return AlertDialog(
    title: const Text('Paste Special'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Text('Number of copies:'),
            const SizedBox(width: 10),
            SizedBox(
              width: 50,
              child: TextField(
                controller: copiesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        ValueListenableBuilder<bool>(
          valueListenable: keepConnections,
          builder: (context, value, child) {
            return CheckboxListTile(
              title: const Text('Keep connections between copies'),
              value: value,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (val) {
                keepConnections.value = val ?? true;
              },
            );
          },
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      TextButton(
        onPressed: () {
          Navigator.pop(context);
          int copies = int.tryParse(copiesController.text) ?? 1;
          copies = copies.clamp(1, 20);
          handlePasteSpecialComponent(
            pastePosition,
            copies,
            keepConnections.value,
          );
        },
        child: const Text('Paste'),
      ),
    ],
  );
}
