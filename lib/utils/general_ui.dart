import 'package:flutter/material.dart';
import '../comm/models/command_models.dart';
import '../models/link.dart';
import '../niagara/models/component.dart';
import '../niagara/models/component_type.dart';
import '../niagara/models/ramp_component.dart';
import '../niagara/models/rectangle.dart';

const double rowHeight = 22.0;

String getComponentSymbol(Component component) {
  if (component.type.type == RectangleComponent.RECTANGLE) {
    return 'R';
  }
  if (component.type.type == RampComponent.RAMP) {
    return '⏱️';
  }

  switch (component.type.type) {
    case ComponentType.AND_GATE:
      return 'AND';
    case ComponentType.OR_GATE:
      return 'OR';
    case ComponentType.XOR_GATE:
      return 'XOR';
    case ComponentType.NOT_GATE:
      return 'NOT';
    case ComponentType.ADD:
      return '+';
    case ComponentType.SUBTRACT:
      return '-';
    case ComponentType.MULTIPLY:
      return '×';
    case ComponentType.DIVIDE:
      return '÷';
    case ComponentType.MAX:
      return 'MAX';
    case ComponentType.MIN:
      return 'MIN';
    case ComponentType.POWER:
      return 'POW';
    case ComponentType.ABS:
      return '|x|';
    case ComponentType.IS_GREATER_THAN:
      return '>';
    case ComponentType.IS_LESS_THAN:
      return '<';
    case ComponentType.IS_EQUAL:
      return '=';
    case ComponentType.BOOLEAN_WRITABLE:
      return 'BW';
    case ComponentType.NUMERIC_WRITABLE:
      return 'NW';
    case ComponentType.STRING_WRITABLE:
      return 'SW';
    case ComponentType.BOOLEAN_POINT:
      return 'BP';
    case ComponentType.NUMERIC_POINT:
      return 'NP';
    case ComponentType.STRING_POINT:
      return 'SP';
    default:
      return '?';
  }
}

Color getComponentColor(Component component) {
  // Custom components
  if (component.type.type == RectangleComponent.RECTANGLE) {
    return Colors.lime[100]!;
  }
  if (component.type.type == RampComponent.RAMP) {
    return Colors.amber[100]!;
  }

  // Standard components
  if (component.type.isLogicGate) {
    return Colors.lightBlue[100]!;
  } else if (component.type.isMathOperation) {
    return Colors.lightGreen[100]!;
  } else if (component.type.type == ComponentType.BOOLEAN_WRITABLE ||
      component.type.type == ComponentType.BOOLEAN_POINT) {
    return Colors.indigo[100]!;
  } else if (component.type.type == ComponentType.NUMERIC_WRITABLE ||
      component.type.type == ComponentType.NUMERIC_POINT) {
    return Colors.teal[100]!;
  } else if (component.type.type == ComponentType.STRING_WRITABLE ||
      component.type.type == ComponentType.STRING_POINT) {
    return Colors.orange[100]!;
  } else {
    return Colors.grey[100]!;
  }
}

// utils.dart (continued)
Color getComponentTextColor(Component component) {
  // Custom components
  if (component.type.type == RectangleComponent.RECTANGLE) {
    return Colors.green[800]!;
  }
  if (component.type.type == RampComponent.RAMP) {
    return Colors.amber[800]!;
  }

  // Standard components
  if (component.type.isLogicGate) {
    return Colors.blue[800]!;
  } else if (component.type.isMathOperation) {
    return Colors.green[800]!;
  } else if (component.type.type == ComponentType.BOOLEAN_WRITABLE ||
      component.type.type == ComponentType.BOOLEAN_POINT) {
    return Colors.indigo[800]!;
  } else if (component.type.type == ComponentType.NUMERIC_WRITABLE ||
      component.type.type == ComponentType.NUMERIC_POINT) {
    return Colors.teal[800]!;
  } else if (component.type.type == ComponentType.STRING_WRITABLE ||
      component.type.type == ComponentType.STRING_POINT) {
    return Colors.orange[800]!;
  } else {
    return Colors.grey[800]!;
  }
}

IconData getIconForComponentType(ComponentType type) {
  // Custom components
  if (type.type == RectangleComponent.RECTANGLE) {
    return Icons.crop_square;
  }
  if (type.type == RampComponent.RAMP) {
    return Icons.show_chart;
  }

  // Standard components
  switch (type.type) {
    case ComponentType.AND_GATE:
      return Icons.call_merge;
    case ComponentType.OR_GATE:
      return Icons.call_split;
    case ComponentType.XOR_GATE:
      return Icons.shuffle;
    case ComponentType.NOT_GATE:
      return Icons.block;

    case ComponentType.ADD:
      return Icons.add;
    case ComponentType.SUBTRACT:
      return Icons.remove;
    case ComponentType.MULTIPLY:
      return Icons.close;
    case ComponentType.DIVIDE:
      return Icons.expand;
    case ComponentType.MAX:
      return Icons.arrow_upward;
    case ComponentType.MIN:
      return Icons.arrow_downward;
    case ComponentType.POWER:
      return Icons.upload;
    case ComponentType.ABS:
      return Icons.straighten;

    case ComponentType.IS_GREATER_THAN:
      return Icons.navigate_next;
    case ComponentType.IS_LESS_THAN:
      return Icons.navigate_before;
    case ComponentType.IS_EQUAL:
      return Icons.drag_handle;

    case ComponentType.BOOLEAN_WRITABLE:
      return Icons.toggle_on;
    case ComponentType.NUMERIC_WRITABLE:
      return Icons.numbers;
    case ComponentType.STRING_WRITABLE:
      return Icons.text_fields;

    case ComponentType.BOOLEAN_POINT:
      return Icons.toggle_off;
    case ComponentType.NUMERIC_POINT:
      return Icons.format_list_numbered;
    case ComponentType.STRING_POINT:
      return Icons.text_snippet;

    default:
      return Icons.help_outline;
  }
}

void showSnackBarMsg(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

Color getPortColor(PortType type) {
  switch (type) {
    case PortType.boolean:
      return Colors.green;
    case PortType.number:
      return Colors.blue;
    case PortType.string:
      return Colors.orange;
    case PortType.any:
    default:
      return Colors.purple;
  }
}

Color getStatusColor(CommandStatus status) {
  switch (status) {
    case CommandStatus.queued:
      return Colors.grey;
    case CommandStatus.executing:
      return Colors.blue;
    case CommandStatus.completed:
      return Colors.green;
    case CommandStatus.failed:
      return Colors.red;
    case CommandStatus.cancelled:
      return Colors.orange;
    case CommandStatus.timedOut:
      return Colors.black38;
  }
}
