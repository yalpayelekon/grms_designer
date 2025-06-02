import 'package:flutter/material.dart';
import 'package:grms_designer/models/helvar_models/helvar_device.dart';
import 'package:grms_designer/models/helvar_models/output_point.dart';
import 'package:grms_designer/niagara/models/component.dart';
import 'package:grms_designer/niagara/models/component_type.dart';
import 'package:grms_designer/niagara/models/helvar_device_component.dart';

import 'package:grms_designer/niagara/models/ramp_component.dart';
import 'package:grms_designer/niagara/models/rectangle.dart';
import 'package:grms_designer/utils/core/logger.dart';
import '../../models/helvar_models/input_device.dart';

List<ButtonPoint> generateStandardButtonPoints(String deviceName) {
  final points = <ButtonPoint>[];
  points.add(
    ButtonPoint(name: '${deviceName}_Missing', function: 'Status', buttonId: 0),
  );
  for (int i = 1; i <= 7; i++) {
    points.add(
      ButtonPoint(
        name: '${deviceName}_Button$i',
        function: 'Button',
        buttonId: i,
      ),
    );
  }
  for (int i = 1; i <= 7; i++) {
    points.add(
      ButtonPoint(
        name: '${deviceName}_IR$i',
        function: 'IR Receiver',
        buttonId: i + 100,
      ),
    );
  }
  return points;
}

String handleRecallScene(String sceneParams, {bool logInfoOutput = false}) {
  if (sceneParams.isNotEmpty) {
    List<String> temp = sceneParams.split(',');
    String timestamp = DateTime.now().toString();
    String s =
        "Success ($timestamp) Recalled Scene: ${temp.length > 1 ? temp[1] : temp[0]}";
    if (logInfoOutput) {
      logInfo(s);
    }
    return s;
  } else {
    logWarning("Please pass a valid scene number!");
    return "Please pass a valid scene number!";
  }
}

List<ComponentType> getCompatibleTypes(ComponentType currentType) {
  // Custom types
  if (currentType.type == RectangleComponent.RECTANGLE) {
    return [const ComponentType(RectangleComponent.RECTANGLE)];
  }
  if (currentType.type == RampComponent.RAMP) {
    return [const ComponentType(RampComponent.RAMP)];
  }

  // Standard types
  List<String> compatibleTypeStrings = [];

  if (currentType.type == ComponentType.AND_GATE ||
      currentType.type == ComponentType.OR_GATE ||
      currentType.type == ComponentType.XOR_GATE) {
    compatibleTypeStrings = [
      ComponentType.AND_GATE,
      ComponentType.OR_GATE,
      ComponentType.XOR_GATE,
    ];
  } else if (currentType.type == ComponentType.NOT_GATE) {
    compatibleTypeStrings = [ComponentType.NOT_GATE];
  } else if (currentType.type == ComponentType.ADD ||
      currentType.type == ComponentType.SUBTRACT ||
      currentType.type == ComponentType.MULTIPLY ||
      currentType.type == ComponentType.DIVIDE ||
      currentType.type == ComponentType.MAX ||
      currentType.type == ComponentType.MIN ||
      currentType.type == ComponentType.POWER) {
    compatibleTypeStrings = [
      ComponentType.ADD,
      ComponentType.SUBTRACT,
      ComponentType.MULTIPLY,
      ComponentType.DIVIDE,
      ComponentType.MAX,
      ComponentType.MIN,
      ComponentType.POWER,
    ];
  } else if (currentType.type == ComponentType.IS_GREATER_THAN ||
      currentType.type == ComponentType.IS_LESS_THAN) {
    compatibleTypeStrings = [
      ComponentType.IS_GREATER_THAN,
      ComponentType.IS_LESS_THAN,
    ];
  } else if (currentType.type == ComponentType.ABS) {
    compatibleTypeStrings = [ComponentType.ABS];
  } else if (currentType.type == ComponentType.IS_EQUAL) {
    compatibleTypeStrings = [ComponentType.IS_EQUAL];
  } else if (currentType.type == ComponentType.BOOLEAN_WRITABLE ||
      currentType.type == ComponentType.BOOLEAN_POINT) {
    compatibleTypeStrings = [
      ComponentType.BOOLEAN_WRITABLE,
      ComponentType.BOOLEAN_POINT,
    ];
  } else if (currentType.type == ComponentType.NUMERIC_WRITABLE ||
      currentType.type == ComponentType.NUMERIC_POINT) {
    compatibleTypeStrings = [
      ComponentType.NUMERIC_WRITABLE,
      ComponentType.NUMERIC_POINT,
    ];
  } else if (currentType.type == ComponentType.STRING_WRITABLE ||
      currentType.type == ComponentType.STRING_POINT) {
    compatibleTypeStrings = [
      ComponentType.STRING_WRITABLE,
      ComponentType.STRING_POINT,
    ];
  }

  return compatibleTypeStrings
      .map((typeString) => ComponentType(typeString))
      .toList();
}

Component createComponentFromDevice(String id, HelvarDevice device) {
  return HelvarDeviceComponent(
    id: id,
    deviceId: device.deviceId,
    deviceAddress: device.address,
    deviceType: device.helvarType,
    description: device.description.isEmpty
        ? "Device_${device.deviceId}"
        : device.description,
    type: ComponentType(getHelvarComponentType(device.helvarType)),
  );
}

String getHelvarComponentType(String helvarType) {
  switch (helvarType) {
    case 'output':
      return ComponentType.HELVAR_OUTPUT;
    case 'input':
      return ComponentType.HELVAR_INPUT;
    case 'emergency':
      return ComponentType.HELVAR_EMERGENCY;
    default:
      return ComponentType.HELVAR_DEVICE;
  }
}

Color getOutputPointColor(OutputPoint point) {
  switch (point.pointId) {
    case 1: // Device State
      return Colors.blue;
    case 2: // Lamp Failure
      return Colors.red;
    case 3: // Missing
      return Colors.orange;
    case 4: // Faulty
      return Colors.red;
    case 5: // Output Level
      return Colors.green;
    case 6: // Power Consumption
      return Colors.purple;
    default:
      return Colors.grey;
  }
}
