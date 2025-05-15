import 'package:flutter/material.dart';
import 'package:grms_designer/niagara/models/port_type.dart';
import '../niagara/models/component.dart';
import '../niagara/models/connection.dart';
import '../niagara/models/component_type.dart';
import '../niagara/models/logic_components.dart';
import '../niagara/models/math_components.dart';
import '../niagara/models/point_components.dart';
import '../niagara/models/port.dart';
import '../niagara/models/rectangle.dart';
import '../niagara/models/ramp_component.dart';

class Flowsheet {
  String id;
  String name;
  DateTime createdAt;
  DateTime modifiedAt;
  List<Component> components;
  Size canvasSize;
  Offset canvasOffset;
  List<Connection> connections;
  final Map<String, Offset> componentPositions = {};
  final Map<String, double> componentWidths = {};

  Flowsheet({
    required this.id,
    required this.name,
    DateTime? createdAt,
    DateTime? modifiedAt,
    List<Component>? components,
    Size? canvasSize,
    Offset? canvasOffset,
    List<Connection>? connections,
  })  : createdAt = createdAt ?? DateTime.now(),
        modifiedAt = modifiedAt ?? DateTime.now(),
        components = components ?? [],
        canvasSize = canvasSize ?? const Size(2000, 2000),
        connections = connections ?? [],
        canvasOffset = canvasOffset ?? const Offset(0, 0);

// Add these methods to the Flowsheet class

  void updateComponentPosition(String componentId, Offset position) {
    // Store the component position in a map
    if (!componentPositions.containsKey(componentId)) {
      componentPositions[componentId] = position;
    } else {
      componentPositions[componentId] = position;
    }
    modifiedAt = DateTime.now();
  }

  void updateComponentWidth(String componentId, double width) {
    // Store the component width in a map
    if (!componentWidths.containsKey(componentId)) {
      componentWidths[componentId] = width;
    } else {
      componentWidths[componentId] = width;
    }
    modifiedAt = DateTime.now();
  }

  void updatePortValue(String componentId, int slotIndex, dynamic value) {
    // Find the component and update the port value
    final componentIndex =
        components.indexWhere((comp) => comp.id == componentId);
    if (componentIndex >= 0) {
      final component = components[componentIndex];

      // Find the slot by index
      Slot? slot;

      // Check properties
      for (var prop in component.properties) {
        if (prop.index == slotIndex) {
          slot = prop;
          break;
        }
      }

      // Check actions if not found in properties
      if (slot == null) {
        for (var action in component.actions) {
          if (action.index == slotIndex) {
            slot = action;
            break;
          }
        }
      }

      // Check topics if not found in actions
      if (slot == null) {
        for (var topic in component.topics) {
          if (topic.index == slotIndex) {
            slot = topic;
            break;
          }
        }
      }

      // Update the value if the slot was found
      if (slot is Property) {
        slot.value = value;
      } else if (slot is ActionSlot) {
        slot.parameter = value;
      }

      modifiedAt = DateTime.now();
    }
  }

  static Flowsheet fromJsonSuper(Map<String, dynamic> json) {
    List<Component> parsedComponents = [];
    if (json['components'] != null) {
      final componentsList = json['components'] as List;
      for (var componentJson in componentsList) {
        final component =
            _componentFromJson(componentJson as Map<String, dynamic>);

        if (componentJson['properties'] != null) {
          component.properties.clear();

          for (var propJson in componentJson['properties'] as List) {
            final Map<String, dynamic> propMap =
                propJson as Map<String, dynamic>;
            component.properties.add(Property(
              name: propMap['name'] as String,
              index: propMap['index'] as int,
              isInput: propMap['isInput'] as bool,
              type: PortType(propMap['type']['type'] as String),
              value: propMap['value'],
            ));
          }
        }

        if (componentJson['actions'] != null) {
          component.actions.clear();

          for (var actionJson in componentJson['actions'] as List) {
            final Map<String, dynamic> actionMap =
                actionJson as Map<String, dynamic>;

            PortType? parameterType;
            if (actionMap['parameterType'] != null) {
              parameterType =
                  PortType(actionMap['parameterType']['type'] as String);
            }

            PortType? returnType;
            if (actionMap['returnType'] != null) {
              returnType = PortType(actionMap['returnType']['type'] as String);
            }

            component.actions.add(ActionSlot(
              name: actionMap['name'] as String,
              index: actionMap['index'] as int,
              parameterType: parameterType,
              returnType: returnType,
              parameter: actionMap['parameter'],
              returnValue: actionMap['returnValue'],
            ));
          }
        }

        if (componentJson['topics'] != null) {
          component.topics.clear();

          for (var topicJson in componentJson['topics'] as List) {
            final Map<String, dynamic> topicMap =
                topicJson as Map<String, dynamic>;

            component.topics.add(Topic(
              name: topicMap['name'] as String,
              index: topicMap['index'] as int,
              eventType: PortType(topicMap['eventType']['type'] as String),
            ));

            if (topicMap['lastEvent'] != null) {
              final topic = component.topics.last;
              topic.fire(topicMap['lastEvent']);
            }
          }
        }

        if (componentJson['inputConnections'] != null) {
          final inputConnections =
              componentJson['inputConnections'] as Map<String, dynamic>;

          for (var entry in inputConnections.entries) {
            final slotIndex = int.parse(entry.key);
            final connectionData = entry.value as Map<String, dynamic>;

            component.inputConnections[slotIndex] = ConnectionEndpoint(
              componentId: connectionData['componentId'] as String,
              portIndex: connectionData['portIndex'] as int,
            );
          }
        }

        parsedComponents.add(component);
      }
    }
    List<Connection> parsedConnections = [];
    if (json['connections'] != null) {
      final connectionsList = json['connections'] as List;
      for (var connectionJson in connectionsList) {
        final Map<String, dynamic> connMap =
            connectionJson as Map<String, dynamic>;
        parsedConnections.add(Connection(
          fromComponentId: connMap['fromComponentId'] as String,
          fromPortIndex: connMap['fromPortIndex'] as int,
          toComponentId: connMap['toComponentId'] as String,
          toPortIndex: connMap['toPortIndex'] as int,
        ));
      }
    }

    if (json['inputConnectionsMap'] != null) {
      final inputConnectionsMap =
          json['inputConnectionsMap'] as Map<String, dynamic>;

      for (var entry in inputConnectionsMap.entries) {
        final componentId = entry.key;
        final connectionsList = entry.value as Map<String, dynamic>;

        final component = parsedComponents.firstWhere(
          (comp) => comp.id == componentId,
          orElse: () => null as Component,
        );

        for (var connEntry in connectionsList.entries) {
          final slotIndex = int.parse(connEntry.key);
          final Map<String, dynamic> endpointData =
              connEntry.value as Map<String, dynamic>;

          component.inputConnections[slotIndex] = ConnectionEndpoint(
            componentId: endpointData['componentId'] as String,
            portIndex: endpointData['portIndex'] as int,
          );
        }
      }
    }

    return Flowsheet(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      modifiedAt: DateTime.parse(json['modifiedAt'] as String),
      components: parsedComponents,
      connections: parsedConnections,
      canvasSize: Size(
        (json['canvasSize']['width'] as num).toDouble(),
        (json['canvasSize']['height'] as num).toDouble(),
      ),
      canvasOffset: Offset(
        (json['canvasOffset']['dx'] as num).toDouble(),
        (json['canvasOffset']['dy'] as num).toDouble(),
      ),
    );
  }

  void addComponent(Component component) {
    components.add(component);
    modifiedAt = DateTime.now();
  }

  void removeComponent(String componentId) {
    components.removeWhere((component) => component.id == componentId);

    // Also remove any connections to/from this component
    connections.removeWhere(
      (connection) =>
          connection.fromComponentId == componentId ||
          connection.toComponentId == componentId,
    );

    modifiedAt = DateTime.now();
  }

  void updateComponent(String componentId, Component updatedComponent) {
    final index =
        components.indexWhere((component) => component.id == componentId);
    if (index >= 0) {
      components[index] = updatedComponent;
      modifiedAt = DateTime.now();
    }
  }

  void addConnection(Connection connection) {
    connections.add(connection);
    modifiedAt = DateTime.now();
  }

  void removeConnection(String fromComponentId, int fromPortIndex,
      String toComponentId, int toPortIndex) {
    connections.removeWhere(
      (connection) =>
          connection.fromComponentId == fromComponentId &&
          connection.fromPortIndex == fromPortIndex &&
          connection.toComponentId == toComponentId &&
          connection.toPortIndex == toPortIndex,
    );
    modifiedAt = DateTime.now();
  }

  void updateCanvasSize(Size newSize) {
    canvasSize = newSize;
    modifiedAt = DateTime.now();
  }

  void updateCanvasOffset(Offset newOffset) {
    canvasOffset = newOffset;
    modifiedAt = DateTime.now();
  }

  // Helper method to create components based on their type
  static Component _componentFromJson(Map<String, dynamic> json) {
    final String componentType = json['type']['type'] as String;
    final String id = json['id'] as String;

    // Create different component types based on the type string
    switch (componentType) {
      case ComponentType.AND_GATE:
      case ComponentType.OR_GATE:
      case ComponentType.XOR_GATE:
      case ComponentType.NOT_GATE:
      case ComponentType.IS_GREATER_THAN:
      case ComponentType.IS_LESS_THAN:
      case ComponentType.IS_EQUAL:
        return LogicComponent(
          id: id,
          type: ComponentType(componentType),
        );

      case ComponentType.ADD:
      case ComponentType.SUBTRACT:
      case ComponentType.MULTIPLY:
      case ComponentType.DIVIDE:
      case ComponentType.MAX:
      case ComponentType.MIN:
      case ComponentType.POWER:
      case ComponentType.ABS:
        return MathComponent(
          id: id,
          type: ComponentType(componentType),
        );

      case ComponentType.BOOLEAN_WRITABLE:
      case ComponentType.NUMERIC_WRITABLE:
      case ComponentType.STRING_WRITABLE:
      case ComponentType.BOOLEAN_POINT:
      case ComponentType.NUMERIC_POINT:
      case ComponentType.STRING_POINT:
        return PointComponent(
          id: id,
          type: ComponentType(componentType),
        );

      case RectangleComponent.RECTANGLE:
        return RectangleComponent(
          id: id,
        );

      case RampComponent.RAMP:
        return RampComponent(
          id: id,
        );

      default:
        // Default fallback - create a simple point component
        return PointComponent(
          id: id,
          type: const ComponentType(ComponentType.NUMERIC_POINT),
        );
    }
  }

  // Helper method to convert component to JSON
  static Map<String, dynamic> _componentToJson(Component component) {
    final Map<String, dynamic> json = {
      'id': component.id,
      'type': {
        'type': component.type.type,
      },
      'properties': component.properties
          .map((prop) => {
                'name': prop.name,
                'index': prop.index,
                'isInput': prop.isInput,
                'type': {
                  'type': prop.type.type,
                },
                'value': prop.value,
              })
          .toList(),
      'actions': component.actions
          .map((action) => {
                'name': action.name,
                'index': action.index,
                'parameterType': action.parameterType != null
                    ? {
                        'type': action.parameterType!.type,
                      }
                    : null,
                'returnType': action.returnType != null
                    ? {
                        'type': action.returnType!.type,
                      }
                    : null,
              })
          .toList(),
      'topics': component.topics
          .map((topic) => {
                'name': topic.name,
                'index': topic.index,
                'eventType': {
                  'type': topic.eventType.type,
                },
              })
          .toList(),
      'inputConnections':
          component.inputConnections.map((key, value) => MapEntry(
                key.toString(),
                {
                  'componentId': value.componentId,
                  'portIndex': value.portIndex,
                },
              )),
    };

    return json;
  }

  factory Flowsheet.fromJson(Map<String, dynamic> json) {
    final flowsheet = Flowsheet.fromJsonSuper(json);

    // Read componentPositions
    if (json['componentPositions'] != null) {
      (json['componentPositions'] as Map<String, dynamic>)
          .forEach((key, value) {
        flowsheet.componentPositions[key] = Offset(
          (value['dx'] as num).toDouble(),
          (value['dy'] as num).toDouble(),
        );
      });
    }

    // Read componentWidths
    if (json['componentWidths'] != null) {
      (json['componentWidths'] as Map<String, dynamic>).forEach((key, value) {
        flowsheet.componentWidths[key] = (value as num).toDouble();
      });
    }

    return flowsheet;
  }

  Map<String, dynamic> toJson() {
    final Map<String, Map<String, dynamic>> inputConnectionsMap = {};

    for (var component in components) {
      if (component.inputConnections.isNotEmpty) {
        inputConnectionsMap[component.id] = {};

        for (var entry in component.inputConnections.entries) {
          inputConnectionsMap[component.id]![entry.key.toString()] = {
            'componentId': entry.value.componentId,
            'portIndex': entry.value.portIndex,
          };
        }
      }
    }

    var json = {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
      'components':
          components.map((component) => _componentToJson(component)).toList(),
      'connections': connections
          .map((connection) => {
                'fromComponentId': connection.fromComponentId,
                'fromPortIndex': connection.fromPortIndex,
                'toComponentId': connection.toComponentId,
                'toPortIndex': connection.toPortIndex,
              })
          .toList(),
      'canvasSize': {
        'width': canvasSize.width,
        'height': canvasSize.height,
      },
      'canvasOffset': {
        'dx': canvasOffset.dx,
        'dy': canvasOffset.dy,
      },
      'inputConnectionsMap': inputConnectionsMap,
    };

    json['componentPositions'] =
        componentPositions.map((key, value) => MapEntry(
              key,
              {
                'dx': value.dx,
                'dy': value.dy,
              },
            ));

    json['componentWidths'] = componentWidths;

    return json;
  }

  Flowsheet copy() {
    return Flowsheet(
      id: id,
      name: name,
      createdAt: createdAt,
      modifiedAt: modifiedAt,
      components: List.from(components),
      connections: List.from(connections),
      canvasSize: canvasSize,
      canvasOffset: canvasOffset,
    );
  }
}
