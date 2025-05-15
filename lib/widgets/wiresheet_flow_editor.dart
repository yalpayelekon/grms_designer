import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../niagara/models/command_history.dart';
import '../niagara/home/component_widget.dart';
import '../niagara/home/connection_painter.dart';
import '../niagara/home/grid_painter.dart';
import '../niagara/home/intents.dart';
import '../niagara/home/manager.dart';
import '../niagara/home/selection_box_painter.dart';
import '../niagara/models/component.dart';
import '../niagara/models/component_type.dart';
import '../niagara/models/connection.dart';
import '../niagara/models/port.dart';
import '../niagara/models/port_type.dart';
import '../providers/flowsheet_provider.dart';

class WiresheetFlowEditor extends ConsumerStatefulWidget {
  final String flowsheetId;

  const WiresheetFlowEditor({
    super.key,
    required this.flowsheetId,
  });

  @override
  WiresheetFlowEditorState createState() => WiresheetFlowEditorState();
}

class WiresheetFlowEditorState extends ConsumerState<WiresheetFlowEditor> {
  final FlowManager _flowManager = FlowManager();
  final CommandHistory _commandHistory = CommandHistory();

  final Map<String, Offset> _componentPositions = {};
  final Map<String, GlobalKey> _componentKeys = {};
  Offset? _selectionBoxStart;
  Offset? _selectionBoxEnd;
  bool _isDraggingSelectionBox = false;

  SlotDragInfo? _currentDraggedPort;
  Offset? _tempLineEndPoint;
  Offset? _dragStartPosition;
  Offset? _clipboardComponentPosition;
  final TransformationController _transformationController =
      TransformationController();
  final GlobalKey _interactiveViewerChildKey = GlobalKey();
  final Map<String, double> _componentWidths = {};
  Size _canvasSize = const Size(2000, 2000); // Initial canvas size
  Offset _canvasOffset = Offset.zero; // Canvas position within the view
  static const double _canvasPadding = 100.0; // Padding around components

  final List<Component> _clipboardComponents = [];
  final List<Offset> _clipboardPositions = [];
  final List<Connection> _clipboardConnections = [];
  final Set<Component> _selectedComponents = {};

  int? selectedItemIndex;
  bool isPanelExpanded = false;
  double scale = 1.0;
  Offset viewportOffset = const Offset(0, 0);
  String? selectedSourceItemId;
  String? selectedSourcePortId;
  bool isDraggingLink = false;
  Offset? linkDragEndPoint;
  String? hoveredLinkId;
  String? selectedLinkId;
  Offset? _lastTapPosition;
  static const double rowHeight = 22.0;
  static const double headerHeight = 28.0;
  final Map<String, Map<String, dynamic>> _portValues = {};
  final Set<String> _evaluatingLinks = {};

  @override
  void initState() {
    super.initState();
    _transformationController.value = Matrix4.identity();
    _initializeData();
  }

  void _initializeData() {
    final flowsheet = ref.read(flowsheetsProvider).firstWhere(
          (sheet) => sheet.id == widget.flowsheetId,
          orElse: () => throw Exception('Flowsheet not found'),
        );

    // Initialize FlowManager with flowsheet components
    for (final component in flowsheet.components) {
      _flowManager.addComponent(component);

      // Setup positions based on flowsheet data
      final position = flowsheet.componentPositions[component.id] ??
          Offset(_canvasSize.width / 2, _canvasSize.height / 2);
      _componentPositions[component.id] = position;
      _componentKeys[component.id] = GlobalKey();
      _componentWidths[component.id] = 160.0; // Default width
    }

    // Initialize connections
    for (final connection in flowsheet.connections) {
      _flowManager.createConnection(
        connection.fromComponentId,
        connection.fromPortIndex,
        connection.toComponentId,
        connection.toPortIndex,
      );
    }

    _flowManager.recalculateAll();
    _updateCanvasSize();
    _commandHistory.clear();

    // Set active flowsheet in provider
    ref
        .read(flowsheetsProvider.notifier)
        .setActiveFlowsheet(widget.flowsheetId);
  }

  void _updateCanvasSize() {
    if (_componentPositions.isEmpty) return;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (var entry in _componentPositions.entries) {
      final position = entry.value;

      const estimatedWidth = 180.0; // 160 width + 20 padding
      const estimatedHeight = 120.0;

      minX = min(minX, position.dx);
      minY = min(minY, position.dy);
      maxX = max(maxX, position.dx + estimatedWidth);
      maxY = max(maxY, position.dy + estimatedHeight);
    }

    bool needsUpdate = false;
    Size newCanvasSize = _canvasSize;
    Offset newCanvasOffset = _canvasOffset;

    if (minX < _canvasPadding) {
      double extraWidth = _canvasPadding - minX;
      newCanvasSize =
          Size(_canvasSize.width + extraWidth, newCanvasSize.height);
      newCanvasOffset =
          Offset(_canvasOffset.dx - extraWidth, newCanvasOffset.dy);

      for (var id in _componentPositions.keys) {
        _componentPositions[id] = Offset(
          _componentPositions[id]!.dx + extraWidth,
          _componentPositions[id]!.dy,
        );
      }
      needsUpdate = true;
    }

    if (minY < _canvasPadding) {
      double extraHeight = _canvasPadding - minY;
      newCanvasSize =
          Size(newCanvasSize.width, _canvasSize.height + extraHeight);
      newCanvasOffset =
          Offset(newCanvasOffset.dx, _canvasOffset.dy - extraHeight);

      for (var id in _componentPositions.keys) {
        _componentPositions[id] = Offset(
          _componentPositions[id]!.dx,
          _componentPositions[id]!.dy + extraHeight,
        );
      }
      needsUpdate = true;
    }

    if (maxX > _canvasSize.width - _canvasPadding) {
      double extraWidth = maxX - (_canvasSize.width - _canvasPadding);
      newCanvasSize =
          Size(_canvasSize.width + extraWidth, newCanvasSize.height);
      needsUpdate = true;
    }

    if (maxY > _canvasSize.height - _canvasPadding) {
      double extraHeight = maxY - (_canvasSize.height - _canvasPadding);
      newCanvasSize =
          Size(newCanvasSize.width, _canvasSize.height + extraHeight);
      needsUpdate = true;
    }

    if (needsUpdate) {
      // Update local state
      setState(() {
        _canvasSize = newCanvasSize;
        _canvasOffset = newCanvasOffset;
      });

      // Update flowsheet state in provider
      final flowsheet = ref.read(activeFlowsheetProvider);
      if (flowsheet != null) {
        ref
            .read(flowsheetsProvider.notifier)
            .updateCanvasSize(widget.flowsheetId, newCanvasSize);
        ref
            .read(flowsheetsProvider.notifier)
            .updateCanvasOffset(widget.flowsheetId, newCanvasOffset);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: getShortcuts(),
      child: Actions(
        actions: <Type, Action<Intent>>{
          UndoIntent: CallbackAction<UndoIntent>(
            onInvoke: (UndoIntent intent) {
              if (_commandHistory.canUndo) {
                setState(() {
                  _commandHistory.undo();
                });
              }
              return null;
            },
          ),
          RedoIntent: CallbackAction<RedoIntent>(
            onInvoke: (RedoIntent intent) {
              if (_commandHistory.canRedo) {
                setState(() {
                  _commandHistory.redo();
                });
              }
              return null;
            },
          ),
          // Add more actions here...
        },
        child: Scaffold(
          body: Stack(
            children: [
              Listener(
                onPointerMove: _handlePointerMove,
                onPointerDown: _handlePointerDown,
                child: InteractiveViewer(
                  constrained: false,
                  boundaryMargin: const EdgeInsets.all(double.infinity),
                  minScale: 0.5,
                  maxScale: 2.0,
                  scaleEnabled: true,
                  transformationController: _transformationController,
                  onInteractionEnd: (ScaleEndDetails details) {
                    setState(() {});
                  },
                  child: Stack(
                    children: [
                      DragTarget<Map<String, dynamic>>(
                        onAcceptWithDetails: (details) {
                          _handleDragAccepted(details);
                        },
                        builder: (context, candidateData, rejectedData) {
                          return Stack(
                            children: [
                              Container(
                                width: _canvasSize.width,
                                height: _canvasSize.height,
                                color: Colors.grey[50],
                                child: Center(
                                  child: Text(
                                    _flowManager.components.isEmpty
                                        ? 'Drag and drop components or double-click to add'
                                        : '',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: _canvasSize.width,
                                height: _canvasSize.height,
                                child: CustomPaint(
                                  painter: GridPainter(),
                                  child: Container(),
                                ),
                              ),
                              if (_flowManager.connections.isNotEmpty)
                                CustomPaint(
                                  painter: ConnectionPainter(
                                    flowManager: _flowManager,
                                    componentPositions: _componentPositions,
                                    componentKeys: _componentKeys,
                                    componentWidths: _componentWidths,
                                    tempLineStartInfo: _currentDraggedPort,
                                    tempLineEndPoint: _tempLineEndPoint,
                                  ),
                                  size: Size(
                                    _canvasSize.width,
                                    _canvasSize.height,
                                  ),
                                ),
                              if (_isDraggingSelectionBox &&
                                  _selectionBoxStart != null &&
                                  _selectionBoxEnd != null)
                                CustomPaint(
                                  painter: SelectionBoxPainter(
                                    start: _selectionBoxStart,
                                    end: _selectionBoxEnd,
                                  ),
                                  size: _canvasSize,
                                ),
                              ..._flowManager.components.map(
                                (component) {
                                  return Positioned(
                                    left:
                                        _componentPositions[component.id]?.dx ??
                                            0,
                                    top:
                                        _componentPositions[component.id]?.dy ??
                                            0,
                                    child: _buildDraggableComponent(component),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              if (selectedItemIndex != null && isPanelExpanded)
                _buildPropertiesPanel(),
              if (selectedItemIndex != null)
                Positioned(
                  right: isPanelExpanded ? 250 : 0,
                  top: 10,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        isPanelExpanded = !isPanelExpanded;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8.0),
                          bottomLeft: Radius.circular(8.0),
                        ),
                      ),
                      child: Icon(
                        isPanelExpanded
                            ? Icons.arrow_forward
                            : Icons.arrow_back,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(
                mini: true,
                onPressed: () {
                  setState(() {
                    _transformationController.value = Matrix4.identity();
                  });
                },
                tooltip: 'Reset View',
                child: const Icon(Icons.center_focus_strong),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDraggableComponent(Component component) {
    final isSelected = _selectedComponents.contains(component);
    final height = component.allSlots.length * rowHeight;

    return Draggable<String>(
      data: component.id,
      feedback: Material(
        elevation: 5.0,
        color: Colors.transparent,
        child: ComponentWidget(
          component: component,
          height: height,
          isSelected: isSelected,
          widgetKey: _componentKeys[component.id] ?? GlobalKey(),
          position: _componentPositions[component.id] ?? Offset.zero,
          width: _componentWidths[component.id] ?? 160.0,
          onValueChanged: _handleValueChanged,
          onSlotDragStarted: _handlePortDragStarted,
          onSlotDragAccepted: _handlePortDragAccepted,
          onWidthChanged: _handleComponentWidthChanged,
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: ComponentWidget(
          component: component,
          height: height,
          isSelected: isSelected,
          widgetKey: GlobalKey(),
          position: _componentPositions[component.id] ?? Offset.zero,
          width: _componentWidths[component.id] ?? 160.0,
          onValueChanged: _handleValueChanged,
          onSlotDragStarted: _handlePortDragStarted,
          onSlotDragAccepted: _handlePortDragAccepted,
          onWidthChanged: _handleComponentWidthChanged,
        ),
      ),
      onDragStarted: () {
        _dragStartPosition = _componentPositions[component.id];
      },
      onDragEnd: (details) {
        _handleComponentDragEnd(details, component);
      },
      child: GestureDetector(
        onSecondaryTapDown: (details) {
          _showContextMenu(context, details.globalPosition, component);
        },
        onTap: () {
          setState(() {
            if (HardwareKeyboard.instance.isControlPressed) {
              if (_selectedComponents.contains(component)) {
                _selectedComponents.remove(component);
              } else {
                _selectedComponents.add(component);
              }
            } else {
              _selectedComponents.clear();
              _selectedComponents.add(component);

              // Set selectedItemIndex for properties panel
              selectedItemIndex =
                  _flowManager.components.toList().indexOf(component);
              isPanelExpanded = true;
            }
          });
        },
        child: ComponentWidget(
          component: component,
          height: height,
          width: _componentWidths[component.id] ?? 160.0,
          onWidthChanged: _handleComponentWidthChanged,
          isSelected: isSelected,
          widgetKey: _componentKeys[component.id] ?? GlobalKey(),
          position: _componentPositions[component.id] ?? Offset.zero,
          onValueChanged: _handleValueChanged,
          onSlotDragStarted: _handlePortDragStarted,
          onSlotDragAccepted: _handlePortDragAccepted,
        ),
      ),
    );
  }

  void _handleDragAccepted(DragTargetDetails<Map<String, dynamic>> details) {
    final data = details.data;
    final globalPosition = details.offset;
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(globalPosition);

    final matrix = _transformationController.value;
    final inverseMatrix = Matrix4.inverted(matrix);
    final canvasPosition =
        MatrixUtils.transformPoint(inverseMatrix, localPosition);

    Component? newComponent;

    // Handle device data if present
    if (data["deviceData"] != null) {
      // Create device component
      final deviceData = data["deviceData"] as Map<String, dynamic>;
      final id = const Uuid().v4();
      final deviceId = deviceData["deviceId"] as int;
      final deviceAddress = deviceData["deviceAddress"] as String;
      final deviceType = deviceData["deviceType"] as String;
      final description = deviceData["description"] as String;

      // Create component based on device type
      newComponent = _createComponentForDevice(
          id, deviceId, deviceAddress, deviceType, description);
    }
    // Handle regular component types
    else if (data["componentType"] != null) {
      final componentType = data["componentType"] as String;
      final label = data["label"] as String;
      final id = '$label ${DateTime.now().millisecondsSinceEpoch}';

      newComponent = _flowManager.createComponentByType(id, componentType);
    }

    if (newComponent != null) {
      _addNewComponent(newComponent, canvasPosition);
    }
  }

  Component _createComponentForDevice(String id, int deviceId,
      String deviceAddress, String deviceType, String description) {
    // Here you would implement the logic to create a component based on device type
    // This is a simplified example - you'll need to adapt to your specific needs
    const componentType = ComponentType.HELVAR_DEVICE;

    final component = _flowManager.createComponentByType(id, componentType);
    component.properties.first.value = description;

    // You might need to store device-specific info in properties
    component.properties.add(Property(
      name: "DeviceId",
      index: component.properties.length,
      isInput: false,
      type: const PortType(PortType.NUMERIC),
      value: deviceId,
    ));

    component.properties.add(Property(
      name: "Address",
      index: component.properties.length,
      isInput: false,
      type: const PortType(PortType.STRING),
      value: deviceAddress,
    ));

    return component;
  }

  void _addNewComponent(Component component, Offset position) {
    setState(() {
      _flowManager.addComponent(component);
      _componentPositions[component.id] = position;
      _componentKeys[component.id] = GlobalKey();
      _componentWidths[component.id] = 160.0; // Default width

      ref
          .read(flowsheetsProvider.notifier)
          .addFlowsheetComponent(widget.flowsheetId, component);

      _selectedComponents.clear();
      _selectedComponents.add(component);
      selectedItemIndex = _flowManager.components.length - 1;
      isPanelExpanded = true;

      _updateCanvasSize();
    });
  }

  void _handleComponentDragEnd(DraggableDetails details, Component component) {
    final RenderBox? viewerChildRenderBox =
        _interactiveViewerChildKey.currentContext?.findRenderObject()
            as RenderBox?;

    if (viewerChildRenderBox != null && _dragStartPosition != null) {
      final Offset localOffset =
          viewerChildRenderBox.globalToLocal(details.offset);

      if (_dragStartPosition != localOffset) {
        setState(() {
          final offset = localOffset - _dragStartPosition!;

          if (_selectedComponents.contains(component) &&
              _selectedComponents.length > 1) {
            for (var selectedComponent in _selectedComponents) {
              final currentPos = _componentPositions[selectedComponent.id];
              if (currentPos != null) {
                final newPos = currentPos + offset;
                _componentPositions[selectedComponent.id] = newPos;

                ref.read(flowsheetsProvider.notifier).updateComponentPosition(
                    widget.flowsheetId, selectedComponent.id, newPos);
              }
            }
          } else {
            _componentPositions[component.id] = localOffset;

            ref.read(flowsheetsProvider.notifier).updateComponentPosition(
                widget.flowsheetId, component.id, localOffset);
          }

          _dragStartPosition = null;
          _updateCanvasSize();
        });
      }
    }
  }

  void _handleComponentWidthChanged(String componentId, double newWidth) {
    setState(() {
      _componentWidths[componentId] = newWidth;

      // Update width in flowsheet
      ref
          .read(flowsheetsProvider.notifier)
          .updateComponentWidth(widget.flowsheetId, componentId, newWidth);
    });
  }

  void _handleValueChanged(
      String componentId, int slotIndex, dynamic newValue) {
    Component? component = _flowManager.findComponentById(componentId);
    if (component != null) {
      Slot? slot = component.getSlotByIndex(slotIndex);

      if (slot != null) {
        dynamic oldValue;
        if (slot is Property) {
          oldValue = slot.value;
        } else if (slot is ActionSlot) {
          oldValue = slot.parameter;
        }

        if (oldValue != newValue) {
          setState(() {
            _flowManager.updatePortValue(componentId, slotIndex, newValue);

            // Update port value in flowsheet
            ref.read(flowsheetsProvider.notifier).updatePortValue(
                widget.flowsheetId, componentId, slotIndex, newValue);
          });
        }
      }
    }
  }

  void _handlePortDragStarted(SlotDragInfo slotInfo) {
    setState(() {
      _currentDraggedPort = slotInfo;
    });
  }

  void _handlePortDragAccepted(SlotDragInfo targetSlotInfo) {
    if (_currentDraggedPort != null) {
      Component? sourceComponent =
          _flowManager.findComponentById(_currentDraggedPort!.componentId);
      Component? targetComponent =
          _flowManager.findComponentById(targetSlotInfo.componentId);

      if (sourceComponent != null && targetComponent != null) {
        if (_flowManager.canCreateConnection(
            _currentDraggedPort!.componentId,
            _currentDraggedPort!.slotIndex,
            targetSlotInfo.componentId,
            targetSlotInfo.slotIndex)) {
          setState(() {
            _flowManager.createConnection(
              _currentDraggedPort!.componentId,
              _currentDraggedPort!.slotIndex,
              targetSlotInfo.componentId,
              targetSlotInfo.slotIndex,
            );

            // Add connection to flowsheet
            ref.read(flowsheetsProvider.notifier).addConnection(
                widget.flowsheetId,
                Connection(
                  fromComponentId: _currentDraggedPort!.componentId,
                  fromPortIndex: _currentDraggedPort!.slotIndex,
                  toComponentId: targetSlotInfo.componentId,
                  toPortIndex: targetSlotInfo.slotIndex,
                ));
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Cannot connect these slots - type mismatch or invalid connection'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }

    setState(() {
      _currentDraggedPort = null;
      _tempLineEndPoint = null;
    });
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_currentDraggedPort != null) {
      setState(() {
        final RenderBox box = context.findRenderObject() as RenderBox;
        _tempLineEndPoint = box.globalToLocal(event.position);
      });
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    // Handle selection box start and component selection logic
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(event.position);

    final matrix = _transformationController.value;
    final inverseMatrix = Matrix4.inverted(matrix);
    final canvasPosition =
        MatrixUtils.transformPoint(inverseMatrix, localPosition);

    // Check if we clicked on a component
    bool clickedOnComponent = false;
    for (final componentId in _componentPositions.keys) {
      final pos = _componentPositions[componentId]!;
      final width = _componentWidths[componentId] ?? 160.0;
      final component = _flowManager.findComponentById(componentId);
      if (component == null) continue;

      final height =
          component.allSlots.length * rowHeight + 40; // Approximate height

      final rect = Rect.fromLTWH(pos.dx, pos.dy, width, height);
      if (rect.contains(canvasPosition)) {
        clickedOnComponent = true;
        break;
      }
    }

    if (!clickedOnComponent) {
      // Start selection box
      setState(() {
        _selectionBoxStart = canvasPosition;
        _isDraggingSelectionBox = false;

        // Clear selection unless Ctrl is pressed
        if (!HardwareKeyboard.instance.isControlPressed) {
          _selectedComponents.clear();
          selectedItemIndex = null;
          isPanelExpanded = false;
        }
      });

      if (event.kind == PointerDeviceKind.touch ||
          event.buttons == kSecondaryMouseButton) {
        _lastTapPosition = event.position;
      }
    }
  }

  void _showContextMenu(
      BuildContext context, Offset position, Component component) {
    _lastTapPosition ??= position;

    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;

    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(_lastTapPosition!.dx, _lastTapPosition!.dy, 1, 1),
        Offset.zero & overlay.size,
      ),
      items: [
        const PopupMenuItem(
          value: 'copy',
          child: Row(
            children: [
              Icon(Icons.copy, size: 18),
              SizedBox(width: 8),
              Text('Copy'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 18),
              SizedBox(width: 8),
              Text('Edit'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 18),
              SizedBox(width: 8),
              Text('Delete'),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == null) return;

      switch (value) {
        case 'copy':
          _copyComponent(component);
          break;
        case 'edit':
          _editComponent(context, component);
          break;
        case 'delete':
          _deleteComponent(component);
          break;
      }
    });
  }

  void _copyComponent(Component component) {
    _clipboardComponents.clear();
    _clipboardPositions.clear();
    _clipboardConnections.clear();

    _clipboardComponents.add(component);
    _clipboardPositions.add(_componentPositions[component.id] ?? Offset.zero);

    setState(() {
      _clipboardComponentPosition = _componentPositions[component.id];
    });
  }

  void _editComponent(BuildContext context, Component component) {
    TextEditingController nameController =
        TextEditingController(text: component.id);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Component'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Component Name'),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              // Here you would add fields for editing component properties
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              String newName = nameController.text.trim();
              if (newName.isNotEmpty && newName != component.id) {
                setState(() {
                  // Store current position and properties
                  final position = _componentPositions[component.id];
                  final width = _componentWidths[component.id];

                  // Update component ID in FlowManager
                  component.id = newName;

                  // Update positions and widths maps
                  if (position != null) {
                    _componentPositions.remove(component.id);
                    _componentPositions[newName] = position;
                  }

                  if (width != null) {
                    _componentWidths.remove(component.id);
                    _componentWidths[newName] = width;
                  }

                  // Update component in flowsheet provider
                  ref
                      .read(flowsheetsProvider.notifier)
                      .updateFlowsheetComponent(
                        widget.flowsheetId,
                        component.id,
                        component,
                      );
                });
              }

              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteComponent(Component component) {
    // Get connections that involve this component
    final affectedConnections = _flowManager.connections
        .where((connection) =>
            connection.fromComponentId == component.id ||
            connection.toComponentId == component.id)
        .toList();

    setState(() {
      // Remove component from FlowManager
      _flowManager.removeComponent(component.id);

      // Remove from positions and keys
      _componentPositions.remove(component.id);
      _componentKeys.remove(component.id);
      _componentWidths.remove(component.id);

      // Remove from selection
      _selectedComponents.remove(component);
      if (selectedItemIndex != null &&
          selectedItemIndex! < _flowManager.components.length &&
          _flowManager.components.toList()[selectedItemIndex!].id ==
              component.id) {
        selectedItemIndex = null;
        isPanelExpanded = false;
      }

      // Remove component from flowsheet provider
      ref.read(flowsheetsProvider.notifier).removeFlowsheetComponent(
            widget.flowsheetId,
            component.id,
          );

      _updateCanvasSize();
    });
  }

  Widget _buildPropertiesPanel() {
    if (selectedItemIndex == null ||
        selectedItemIndex! >= _flowManager.components.length) {
      return const SizedBox();
    }

    final component = _flowManager.components.toList()[selectedItemIndex!];

    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      width: 250,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Properties',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'ID',
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(text: component.id),
              onChanged: (value) {
                if (value.isNotEmpty && value != component.id) {
                  setState(() {
                    // Store current position and properties
                    final position = _componentPositions[component.id];
                    final width = _componentWidths[component.id];

                    // Update component ID
                    String oldId = component.id;
                    component.id = value;

                    // Update positions and widths maps
                    if (position != null) {
                      _componentPositions.remove(oldId);
                      _componentPositions[value] = position;
                    }

                    if (width != null) {
                      _componentWidths.remove(oldId);
                      _componentWidths[value] = width;
                    }

                    // Update component in flowsheet provider
                    ref
                        .read(flowsheetsProvider.notifier)
                        .updateFlowsheetComponent(
                          widget.flowsheetId,
                          oldId,
                          component,
                        );
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Position',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'X',
                      border: OutlineInputBorder(),
                    ),
                    controller: TextEditingController(
                      text: _componentPositions[component.id]
                              ?.dx
                              .toStringAsFixed(0) ??
                          '0',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final x = double.tryParse(value);
                      if (x != null) {
                        setState(() {
                          final currentPos = _componentPositions[component.id];
                          if (currentPos != null) {
                            _componentPositions[component.id] =
                                Offset(x, currentPos.dy);

                            // Update position in flowsheet
                            ref
                                .read(flowsheetsProvider.notifier)
                                .updateComponentPosition(
                                  widget.flowsheetId,
                                  component.id,
                                  Offset(x, currentPos.dy),
                                );
                          }
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Y',
                      border: OutlineInputBorder(),
                    ),
                    controller: TextEditingController(
                      text: _componentPositions[component.id]
                              ?.dy
                              .toStringAsFixed(0) ??
                          '0',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final y = double.tryParse(value);
                      if (y != null) {
                        setState(() {
                          final currentPos = _componentPositions[component.id];
                          if (currentPos != null) {
                            _componentPositions[component.id] =
                                Offset(currentPos.dx, y);

                            ref
                                .read(flowsheetsProvider.notifier)
                                .updateComponentPosition(
                                  widget.flowsheetId,
                                  component.id,
                                  Offset(currentPos.dx, y),
                                );
                          }
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildPropertiesList(component),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete),
              label: const Text('Delete Component'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(40),
              ),
              onPressed: () {
                _deleteComponent(component);
              },
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              icon: const Icon(Icons.close),
              label: const Text('Close Panel'),
              onPressed: () {
                setState(() {
                  isPanelExpanded = false;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertiesList(Component component) {
    return ListView(
      children: [
        if (component.properties.isNotEmpty) ...[
          Text(
            'Properties',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...component.properties.map((property) {
            return _buildPropertyEditor(component, property);
          }),
        ],
        if (component.actions.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Actions',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...component.actions.map((action) {
            return ListTile(
              title: Text(action.name),
              trailing: ElevatedButton(
                onPressed: () {
                  _handleValueChanged(component.id, action.index, null);
                },
                child: const Text('Execute'),
              ),
            );
          }),
        ],
        if (component.topics.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Topics',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...component.topics.map((topic) {
            return ListTile(
              title: Text(topic.name),
              subtitle: Text(
                topic.lastEvent != null
                    ? 'Last event: ${_formatEventValue(topic.lastEvent)}'
                    : 'No events',
              ),
            );
          }),
        ],
      ],
    );
  }

  String _formatEventValue(dynamic value) {
    if (value == null) return "null";
    if (value is bool) return value ? "true" : "false";
    if (value is num) return value.toString();
    if (value is String) return '"$value"';
    return value.toString();
  }

  Widget _buildPropertyEditor(Component component, Property property) {
    // Skip input properties that have a connection
    if (property.isInput &&
        component.inputConnections.containsKey(property.index)) {
      return ListTile(
        title: Text(property.name),
        subtitle: const Text('Connected from another component'),
        leading: const Icon(Icons.link),
      );
    }

    switch (property.type.type) {
      case PortType.BOOLEAN:
        return SwitchListTile(
          title: Text(property.name),
          value: property.value as bool? ?? false,
          onChanged: property.isInput
              ? null
              : (value) {
                  _handleValueChanged(component.id, property.index, value);
                },
        );

      case PortType.NUMERIC:
        return ListTile(
          title: Text(property.name),
          subtitle: TextField(
            controller: TextEditingController(
              text: (property.value as num?)?.toString() ?? '0',
            ),
            enabled: !property.isInput,
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final numValue = num.tryParse(value);
              if (numValue != null) {
                _handleValueChanged(component.id, property.index, numValue);
              }
            },
          ),
        );

      case PortType.STRING:
        return ListTile(
          title: Text(property.name),
          subtitle: TextField(
            controller: TextEditingController(
              text: (property.value as String?) ?? '',
            ),
            enabled: !property.isInput,
            onChanged: (value) {
              _handleValueChanged(component.id, property.index, value);
            },
          ),
        );

      default: // For ANY type or others
        return ListTile(
          title: Text(property.name),
          subtitle: Text(
            property.value?.toString() ?? 'null',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        );
    }
  }

  void _showAddComponentDialog(Offset position) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Component'),
        content: SizedBox(
          width: 300,
          height: 400,
          child: ListView(
            children: [
              _buildComponentCategorySection(
                'Logic Gates',
                [
                  ComponentType.AND_GATE,
                  ComponentType.OR_GATE,
                  ComponentType.XOR_GATE,
                  ComponentType.NOT_GATE,
                ],
                position,
              ),
              _buildComponentCategorySection(
                'Math Operations',
                [
                  ComponentType.ADD,
                  ComponentType.SUBTRACT,
                  ComponentType.MULTIPLY,
                  ComponentType.DIVIDE,
                ],
                position,
              ),
              _buildComponentCategorySection(
                'Comparison',
                [
                  ComponentType.IS_GREATER_THAN,
                  ComponentType.IS_LESS_THAN,
                  ComponentType.IS_EQUAL,
                ],
                position,
              ),
              _buildComponentCategorySection(
                'Points',
                [
                  ComponentType.BOOLEAN_POINT,
                  ComponentType.NUMERIC_POINT,
                  ComponentType.STRING_POINT,
                  ComponentType.BOOLEAN_WRITABLE,
                  ComponentType.NUMERIC_WRITABLE,
                  ComponentType.STRING_WRITABLE,
                ],
                position,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComponentCategorySection(
      String title, List<String> componentTypes, Offset position) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12.0, bottom: 6.0),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const Divider(),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: componentTypes.map((type) {
            return InkWell(
              onTap: () {
                _createComponentByType(type, position);
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Column(
                  children: [
                    Icon(_getIconForComponentType(type)),
                    const SizedBox(height: 4.0),
                    Text(_getNameForComponentType(type)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _createComponentByType(String typeStr, Offset position) {
    final id =
        '${_getNameForComponentType(typeStr)} ${DateTime.now().millisecondsSinceEpoch}';
    final component = _flowManager.createComponentByType(id, typeStr);
    _addNewComponent(component, position);
  }

  IconData _getIconForComponentType(String type) {
    switch (type) {
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
      case ComponentType.IS_GREATER_THAN:
        return Icons.navigate_next;
      case ComponentType.IS_LESS_THAN:
        return Icons.navigate_before;
      case ComponentType.IS_EQUAL:
        return Icons.drag_handle;
      case ComponentType.BOOLEAN_POINT:
        return Icons.toggle_off;
      case ComponentType.NUMERIC_POINT:
        return Icons.format_list_numbered;
      case ComponentType.STRING_POINT:
        return Icons.text_snippet;
      case ComponentType.BOOLEAN_WRITABLE:
        return Icons.toggle_on;
      case ComponentType.NUMERIC_WRITABLE:
        return Icons.numbers;
      case ComponentType.STRING_WRITABLE:
        return Icons.edit_note;
      default:
        return Icons.help_outline;
    }
  }

  String _getNameForComponentType(String type) {
    switch (type) {
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
      case ComponentType.IS_GREATER_THAN:
        return 'Greater Than';
      case ComponentType.IS_LESS_THAN:
        return 'Less Than';
      case ComponentType.IS_EQUAL:
        return 'Equals';
      case ComponentType.BOOLEAN_POINT:
        return 'Boolean Point';
      case ComponentType.NUMERIC_POINT:
        return 'Numeric Point';
      case ComponentType.STRING_POINT:
        return 'String Point';
      case ComponentType.BOOLEAN_WRITABLE:
        return 'Boolean Writable';
      case ComponentType.NUMERIC_WRITABLE:
        return 'Numeric Writable';
      case ComponentType.STRING_WRITABLE:
        return 'String Writable';
      default:
        return 'Unknown Component';
    }
  }
}
