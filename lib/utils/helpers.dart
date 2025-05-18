import '../models/helvar_models/helvar_device.dart';
import '../models/helvar_models/workgroup.dart';
import '../niagara/models/component.dart';
import '../niagara/models/component_type.dart';
import '../niagara/models/logic_components.dart';
import '../niagara/models/math_components.dart';
import '../niagara/models/point_components.dart';
import '../niagara/models/port.dart';
import '../niagara/models/port_type.dart';

HelvarDevice? findDevice(
    int deviceId, List<Workgroup> workgroups, String deviceAddress) {
  for (final workgroup in workgroups) {
    for (final router in workgroup.routers) {
      for (final device in router.devices) {
        if (device.deviceId == deviceId && device.address == deviceAddress) {
          return device;
        }
      }
    }
  }

  return null;
}

Component deepCopyComponent(Component original, String newId) {
  Component copy;

  if (original is PointComponent) {
    copy = PointComponent(
      id: newId,
      type: ComponentType(original.type.type),
    );
  } else if (original is LogicComponent) {
    copy = LogicComponent(
      id: newId,
      type: ComponentType(original.type.type),
    );
  } else if (original is MathComponent) {
    copy = MathComponent(
      id: newId,
      type: ComponentType(original.type.type),
    );
  } else {
    copy = PointComponent(
      id: newId,
      type: ComponentType(original.type.type),
    );
  }

  copy.properties.clear();
  copy.actions.clear();
  copy.topics.clear();

  for (var prop in original.properties) {
    final propCopy = Property(
      name: prop.name,
      index: prop.index,
      isInput: prop.isInput,
      type: PortType(prop.type.type),
      value: prop.value,
    );
    copy.properties.add(propCopy);
  }

  for (var action in original.actions) {
    final actionCopy = ActionSlot(
      name: action.name,
      index: action.index,
      parameterType: action.parameterType != null
          ? PortType(action.parameterType!.type)
          : null,
      returnType:
          action.returnType != null ? PortType(action.returnType!.type) : null,
      parameter: action.parameter,
      returnValue: action.returnValue,
    );
    copy.actions.add(actionCopy);
  }

  for (var topic in original.topics) {
    final topicCopy = Topic(
      name: topic.name,
      index: topic.index,
      eventType: PortType(topic.eventType.type),
    );
    if (topic.lastEvent != null) {
      topicCopy.fire(topic.lastEvent);
    }
    copy.topics.add(topicCopy);
  }

  return copy;
}
