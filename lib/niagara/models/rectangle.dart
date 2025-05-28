import 'component.dart';
import 'component_type.dart';
import 'port.dart';
import 'port_type.dart';

class RectangleComponent extends Component {
  static const String RECTANGLE = "RECTANGLE";

  RectangleComponent({required super.id})
    : super(type: const ComponentType(RECTANGLE)) {
    _setupPorts();
  }

  void _setupPorts() {
    properties.add(
      Property(
        name: "Length",
        index: 0,
        isInput: true,
        type: const PortType(PortType.NUMERIC),
        value: 0.0,
      ),
    );

    properties.add(
      Property(
        name: "Width",
        index: 1,
        isInput: true,
        type: const PortType(PortType.NUMERIC),
        value: 0.0,
      ),
    );

    properties.add(
      Property(
        name: "Threshold",
        index: 2,
        isInput: true,
        type: const PortType(PortType.NUMERIC),
        value: 1000.0,
      ),
    );

    topics.add(
      Topic(
        name: "Detected",
        index: 3,
        eventType: const PortType(PortType.NUMERIC),
      ),
    );
  }

  @override
  void calculate() {
    double length = properties[0].value as double;
    double width = properties[1].value as double;
    double threshold = properties[2].value as double;

    double area = length * width;

    if (area > threshold) {
      topics[0].fire(area);
    }
  }
}
