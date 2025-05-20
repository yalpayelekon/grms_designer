import 'package:flutter/material.dart';
import '../models/helvar_models/helvar_device.dart';
import '../models/link.dart';
import '../niagara/models/component.dart';
import '../niagara/models/component_type.dart';
import '../niagara/models/ramp_component.dart';
import '../niagara/models/rectangle.dart';

const double rowHeight = 22.0;

String getDeviceIconAsset(HelvarDevice? device) {
  if (device == null) return 'assets/icons/device.png';

  String hexId =
      device.hexId.startsWith('0x') ? device.hexId.substring(2) : device.hexId;

  hexId = hexId.toLowerCase();

  if (device.isMultisensor ||
      device.helvarType == 'input' &&
          device.props.toLowerCase().contains('sensor')) {
    if (hexId == '312502') return 'assets/icons/312.png';
    if (hexId == '315602') return 'assets/icons/315.png';
    if (hexId == '5749701') return 'assets/icons/IR-Quattro-HD.png';
    if (hexId == '5748001') return 'assets/icons/HF-360.png';
    if (hexId == '5745901') return 'assets/icons/Dual-HF.png';
    if (hexId == '6624601' || hexId == '6626001') {
      return 'assets/icons/IS-3360-MX.png';
    }

    return 'assets/icons/sensor.png';
  }

  if (device.isButtonDevice || device.helvarType == 'input') {
    if (hexId == '100802') return 'assets/icons/100.png';
    if (hexId == '110702') return 'assets/icons/110.png';
    if (hexId == '111402') return 'assets/icons/111.png';
    if (hexId == '121302') return 'assets/icons/121.png';
    if (hexId == '122002') return 'assets/icons/122.png';
    if (hexId == '124402') return 'assets/icons/124.png';
    if (hexId == '125102') return 'assets/icons/125.png';
    if (hexId == '126802') return 'assets/icons/126.png';
    if (hexId == '131202' || hexId.contains('131')) {
      return 'assets/icons/131.png';
    }
    if (hexId == '134302' || hexId.contains('134')) {
      return 'assets/icons/134.png';
    }
    if (hexId == '135002' || hexId.contains('135')) {
      return 'assets/icons/135.png';
    }
    if (hexId == '136702' || hexId.contains('136')) {
      return 'assets/icons/136.png';
    }
    if (hexId == '137402' || hexId.contains('137')) {
      return 'assets/icons/137.png';
    }
    if (hexId == '170102') return 'assets/icons/170.png';
    if (hexId.contains('142')) return 'assets/icons/142WD2.png';
    if (hexId.contains('144')) return 'assets/icons/144WD2.png';
    if (hexId.contains('146')) return 'assets/icons/146WD2.png';
    if (hexId.contains('148')) return 'assets/icons/148WD2.png';
    if (hexId.contains('160')) return 'assets/icons/160.PNG';
    if (hexId.contains('935')) return 'assets/icons/935.png';
    if (hexId.contains('939')) return 'assets/icons/939.png';
    if (hexId.contains('434')) return 'assets/icons/EnOcean.png';

    return 'assets/icons/device.png';
  }

  if (device.helvarType == 'output') {
    if (hexId.contains('55') || hexId == '601' || hexId == '801') {
      return 'assets/icons/LEDunit.png';
    }

    if (hexId.contains('492') ||
        hexId.contains('493') ||
        hexId.contains('42') ||
        hexId.contains('43') ||
        hexId == '1') {
      return 'assets/icons/ballast.png';
    }

    if (hexId.contains('416') ||
        hexId.contains('425') ||
        hexId.contains('452') ||
        hexId.contains('454') ||
        hexId.contains('455') ||
        hexId.contains('458') ||
        hexId.contains('804') ||
        hexId == '401') {
      return 'assets/icons/dimmer.png';
    }

    if (hexId.contains('490')) return 'assets/icons/490.png';
    if (hexId.contains('491') ||
        hexId.contains('492') ||
        hexId.contains('493') ||
        hexId.contains('494') ||
        hexId.contains('498') ||
        hexId.contains('499') ||
        hexId == '701' ||
        hexId == '1793') {
      return 'assets/icons/491.png';
    }

    if (hexId.contains('472') ||
        hexId.contains('474') ||
        hexId.contains('478') ||
        hexId == '501') {
      return 'assets/icons/472.png';
    }

    if (hexId.contains('208') || hexId.contains('108')) {
      return 'assets/icons/dmx.png';
    }
  }

  if (device.helvarType == 'emergency' || device.emergency) {
    return 'assets/icons/outputemergency.png';
  }

  if (hexId.contains('444') || hexId.contains('445') || hexId.contains('441')) {
    return 'assets/icons/444.png';
  }

  if (hexId.contains('942')) {
    return 'assets/icons/942.png';
  }

  return 'assets/icons/device.png';
}

Widget getDeviceIconWidget(HelvarDevice? device, {double size = 24.0}) {
  return Image.asset(
    getDeviceIconAsset(device),
    width: size,
    height: size,
  );
}

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
