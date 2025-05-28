import 'package:flutter/material.dart';
import 'package:grms_designer/niagara/controllers/canvas_interaction_controller.dart';
import 'package:grms_designer/niagara/controllers/flow_editor_state.dart';
import 'package:grms_designer/niagara/home/manager.dart';
import 'package:grms_designer/niagara/models/component_type.dart';
import 'package:grms_designer/utils/persistent_helper.dart';

void addNewComponent(
  ComponentType type,
  FlowManager flowManager,
  FlowEditorState editorState,
  PersistenceHelper persistenceHelper,
  CanvasInteractionController canvasController,
  Function() updateCanvasSize, {
  Offset? clickPosition,
}) {
  // move implementation here
}

void addNewDeviceComponent(
  Map<String, dynamic> deviceData,
  FlowManager flowManager,
  FlowEditorState editorState,
  PersistenceHelper persistenceHelper,
  CanvasInteractionController canvasController,
  Function() updateCanvasSize, {
  Offset? clickPosition,
}) {
  // move implementation here
}

void addNewButtonPointComponent(
  Map<String, dynamic> buttonPointData,
  FlowManager flowManager,
  FlowEditorState editorState,
  PersistenceHelper persistenceHelper,
  CanvasInteractionController canvasController,
  Function() updateCanvasSize, {
  Offset? clickPosition,
}) {
  // move implementation here
}
