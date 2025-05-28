// utils/dialog_utils.dart

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
  // move implementation here
}

Widget buildComponentCategorySection(
  String title,
  List<String> typeStrings,
  Offset position,
  Function(ComponentType, {Offset? clickPosition}) addNewComponent,
) {
  // move implementation here
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
