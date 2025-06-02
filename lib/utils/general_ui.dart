import 'package:flutter/material.dart';
import '../comm/models/command_models.dart';
import '../niagara/models/component_type.dart';
import '../niagara/models/ramp_component.dart';
import '../niagara/models/rectangle.dart';

const double rowHeight = 22.0;

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
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Widget buildInfoRow(String label, String value, {double? width}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: width ?? 220,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
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
