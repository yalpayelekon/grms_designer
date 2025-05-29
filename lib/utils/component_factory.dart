import 'package:flutter/material.dart';
import 'package:grms_designer/niagara/controllers/canvas_interaction_controller.dart';
import 'package:grms_designer/niagara/controllers/flow_editor_state.dart';
import 'package:grms_designer/niagara/home/command.dart';
import 'package:grms_designer/niagara/home/manager.dart';
import 'package:grms_designer/niagara/models/component.dart';
import 'package:grms_designer/niagara/models/component_type.dart';
import 'package:grms_designer/utils/canvas_utils.dart';
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
  String baseName = type.toString();
  int counter = 1;
  String newName = '$baseName $counter';

  while (flowManager.components.any((comp) => comp.id == newName)) {
    counter++;
    newName = '$baseName $counter';
  }

  Component newComponent = flowManager.createComponentByType(
    newName,
    type.type,
  );

  Offset newPosition =
      clickPosition ?? getDefaultPosition(canvasController, editorState);

  Map<String, dynamic> state = {
    'position': newPosition,
    'key': editorState.getComponentKey(newComponent.id),
    'positions': editorState.componentPositions,
    'keys': editorState.componentKeys,
  };

  final command = AddComponentCommand(flowManager, newComponent, state);
  editorState.commandHistory.execute(command);

  editorState.initializeComponentState(
    newComponent,
    position: newPosition,
    width: 160.0,
  );

  persistenceHelper.saveAddComponent(newComponent);
  persistenceHelper.saveComponentPosition(newComponent.id, newPosition);
  persistenceHelper.saveComponentWidth(newComponent.id, 160.0);

  updateCanvasSize();
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
