import 'package:flutter/material.dart';
import '../models/component_type.dart';
import '../models/port_type.dart';
import '../models/ramp_component.dart';
import '../models/rectangle.dart';

String formatDateTime(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inMinutes < 1) {
    return 'Just now';
  } else if (difference.inHours < 1) {
    return '${difference.inMinutes}m ago';
  } else if (difference.inDays < 1) {
    return '${difference.inHours}h ago';
  } else {
    return '${difference.inDays}d ago';
  }
}

Widget buildTypeIndicator(PortType type) {
  IconData icon;
  Color color;

  switch (type.type) {
    case PortType.BOOLEAN:
      icon = Icons.toggle_on_outlined;
      color = Colors.indigo;
      break;
    case PortType.NUMERIC:
      icon = Icons.numbers;
      color = Colors.green;
      break;
    case PortType.STRING:
      icon = Icons.text_fields;
      color = Colors.orange;
      break;
    case PortType.ANY:
      icon = Icons.all_inclusive;
      color = Colors.purple;
      break;
    default:
      icon = Icons.help_outline;
      color = Colors.grey;
  }

  return Icon(
    icon,
    color: color,
    size: 12,
  );
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
