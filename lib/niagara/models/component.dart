import 'package:grms_designer/niagara/home/component_mixin.dart';

import 'port.dart';
import 'connection.dart';
import 'component_type.dart';

abstract class Component with ComponentMixin {
  String id;
  final ComponentType type;
  @override
  final List<Property> properties;
  @override
  final List<ActionSlot> actions;
  @override
  final List<Topic> topics;
  Map<int, ConnectionEndpoint> inputConnections = {};

  Component({
    required this.id,
    required this.type,
    List<Property>? properties,
    List<ActionSlot>? actions,
    List<Topic>? topics,
  }) : properties = properties ?? [],
       actions = actions ?? [],
       topics = topics ?? [];

  List<Slot> get allSlots {
    List<Slot> slots = [];
    slots.addAll(properties);
    slots.addAll(actions);
    slots.addAll(topics);
    return slots;
  }

  void addInputConnection(int slotIndex, ConnectionEndpoint endpoint) {
    inputConnections[slotIndex] = endpoint;
  }

  void removeInputConnection(int slotIndex) {
    inputConnections.remove(slotIndex);
  }

  void calculate();
}
