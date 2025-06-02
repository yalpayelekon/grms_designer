import 'package:grms_designer/models/helvar_models/helvar_device.dart';
import 'package:grms_designer/niagara/models/component.dart';
import 'package:grms_designer/niagara/models/component_type.dart';
import 'package:grms_designer/niagara/models/helvar_device_component.dart';

import 'package:flutter/material.dart';
import 'package:grms_designer/niagara/models/port_type.dart';
import 'package:grms_designer/niagara/models/ramp_component.dart';
import 'package:grms_designer/niagara/models/rectangle.dart';
import 'package:grms_designer/utils/logger.dart';
import '../models/helvar_models/input_device.dart';

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

String getNameForComponentType(ComponentType type) {
  // Custom components
  if (type.type == RectangleComponent.RECTANGLE) {
    return 'Rectangle';
  }
  if (type.type == RampComponent.RAMP) {
    return 'Ramp';
  }

  // Standard components
  switch (type.type) {
    case ComponentType.AND_GATE:
      return 'AND Gate';
    case ComponentType.OR_GATE:
      return 'OR Gate';
    case ComponentType.XOR_GATE:
      return 'XOR Gate';
    case ComponentType.NOT_GATE:
      return 'NOT Gate';

    case ComponentType.ADD:
      return 'Add';
    case ComponentType.SUBTRACT:
      return 'Subtract';
    case ComponentType.MULTIPLY:
      return 'Multiply';
    case ComponentType.DIVIDE:
      return 'Divide';
    case ComponentType.MAX:
      return 'Maximum';
    case ComponentType.MIN:
      return 'Minimum';
    case ComponentType.POWER:
      return 'Power';
    case ComponentType.ABS:
      return 'Absolute Value';

    case ComponentType.IS_GREATER_THAN:
      return 'Greater Than';
    case ComponentType.IS_LESS_THAN:
      return 'Less Than';
    case ComponentType.IS_EQUAL:
      return 'Equals';

    case ComponentType.BOOLEAN_WRITABLE:
      return 'Boolean Writable';
    case ComponentType.NUMERIC_WRITABLE:
      return 'Numeric Writable';
    case ComponentType.STRING_WRITABLE:
      return 'String Writable';

    case ComponentType.BOOLEAN_POINT:
      return 'Boolean Point';
    case ComponentType.NUMERIC_POINT:
      return 'Numeric Point';
    case ComponentType.STRING_POINT:
      return 'String Point';

    default:
      return 'Unknown Component';
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
