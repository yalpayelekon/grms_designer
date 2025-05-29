import 'package:flutter/material.dart';
import 'package:grms_designer/niagara/controllers/canvas_interaction_controller.dart';
import 'package:grms_designer/niagara/controllers/flow_editor_state.dart';
import 'package:grms_designer/niagara/home/command.dart';
import 'package:grms_designer/niagara/home/manager.dart';
import 'package:grms_designer/niagara/models/component.dart';
import 'package:grms_designer/niagara/models/component_type.dart';
import 'package:grms_designer/niagara/models/port_type.dart';
import 'package:grms_designer/utils/canvas_utils.dart';
import 'package:grms_designer/utils/device_utils.dart';
import 'package:grms_designer/utils/logger.dart';
import 'package:grms_designer/utils/persistent_helper.dart';
import 'package:grms_designer/models/helvar_models/helvar_device.dart';
import 'package:grms_designer/models/helvar_models/input_device.dart';

void addNewComponent(
  ComponentType type,
  FlowManager flowManager,
  FlowEditorState editorState,
  PersistenceHelper persistenceHelper,
  CanvasInteractionController canvasController,
  Function() updateCanvasSize, {
  Offset? clickPosition,
}) {
  String baseName = getNameForComponentType(type);
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
  HelvarDevice? device = deviceData["device"] as HelvarDevice?;

  if (device == null) {
    logError('Invalid device data');
    return;
  }

  String deviceName = device.description.isEmpty
      ? "Device_${device.deviceId}"
      : device.description;

  int counter = 1;
  String componentId = deviceName;
  while (flowManager.components.any((comp) => comp.id == componentId)) {
    counter++;
    componentId = "${deviceName}_$counter";
  }

  Component newComponent = createComponentFromDevice(componentId, device);

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
    width: 180.0,
  );

  persistenceHelper.saveAddComponent(newComponent);
  persistenceHelper.saveComponentPosition(newComponent.id, newPosition);
  persistenceHelper.saveComponentWidth(newComponent.id, 180.0);

  updateCanvasSize();
}

void addNewButtonPointComponent(
  Map<String, dynamic> buttonPointData,
  FlowManager flowManager,
  FlowEditorState editorState,
  PersistenceHelper persistenceHelper,
  CanvasInteractionController canvasController,
  Function() updateCanvasSize, {
  Offset? clickPosition,
  Map<String, Map<String, dynamic>>? buttonPointMetadata,
}) {
  final ButtonPoint buttonPoint = buttonPointData["buttonPoint"] as ButtonPoint;
  final HelvarDevice parentDevice =
      buttonPointData["parentDevice"] as HelvarDevice;

  String baseName = buttonPoint.name;
  String componentId = baseName;
  int counter = 1;

  while (flowManager.components.any((comp) => comp.id == componentId)) {
    componentId = "${baseName}_$counter";
    counter++;
  }

  Component newComponent = flowManager.createComponentByType(
    componentId,
    ComponentType.BOOLEAN_POINT,
  );

  bool initialValue = _getInitialButtonPointValue(buttonPoint);

  for (var property in newComponent.properties) {
    if (!property.isInput && property.type.type == PortType.BOOLEAN) {
      property.value = initialValue;
      break;
    }
  }

  if (buttonPointMetadata != null) {
    buttonPointMetadata[componentId] = {
      'buttonPoint': buttonPoint,
      'parentDevice': parentDevice,
      'deviceAddress': parentDevice.address,
      'buttonId': buttonPoint.buttonId,
      'function': buttonPoint.function,
    };
  }

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

bool _getInitialButtonPointValue(ButtonPoint buttonPoint) {
  if (buttonPoint.function.contains('Status') ||
      buttonPoint.name.toLowerCase().contains('missing')) {
    return false;
  }
  return false;
}

String generateUniqueComponentName(String baseName, FlowManager flowManager) {
  int counter = 1;
  String newName = '$baseName $counter';

  while (flowManager.components.any((comp) => comp.id == newName)) {
    counter++;
    newName = '$baseName $counter';
  }

  return newName;
}

void executeComponentAddition(
  Component newComponent,
  Offset position,
  FlowManager flowManager,
  FlowEditorState editorState,
  PersistenceHelper persistenceHelper,
  Function() updateCanvasSize, {
  double width = 160.0,
}) {
  Map<String, dynamic> state = {
    'position': position,
    'key': editorState.getComponentKey(newComponent.id),
    'positions': editorState.componentPositions,
    'keys': editorState.componentKeys,
  };

  final command = AddComponentCommand(flowManager, newComponent, state);
  editorState.commandHistory.execute(command);

  editorState.initializeComponentState(
    newComponent,
    position: position,
    width: width,
  );

  persistenceHelper.saveAddComponent(newComponent);
  persistenceHelper.saveComponentPosition(newComponent.id, position);
  persistenceHelper.saveComponentWidth(newComponent.id, width);

  updateCanvasSize();
}
