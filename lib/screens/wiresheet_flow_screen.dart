import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/widget_type.dart';
import '../models/wiresheet.dart';
import '../models/canvas_item.dart';
import '../models/link.dart';
import '../niagara/home/command.dart';
import '../niagara/home/component_widget.dart';
import '../niagara/home/connection_painter.dart';
import '../niagara/home/grid_painter.dart';
import '../niagara/home/handlers.dart';
import '../niagara/home/intents.dart';
import '../niagara/home/manager.dart';
import '../niagara/home/paste_special_dialog.dart';
import '../niagara/home/selection_box_painter.dart';
import '../niagara/models/command_history.dart';
import '../niagara/models/component.dart';
import '../niagara/models/component_type.dart' as niagara;
import '../niagara/models/component_type.dart';
import '../niagara/models/connection.dart';
import '../niagara/models/helvar_device_component.dart';
import '../niagara/models/point_components.dart';
import '../niagara/models/port.dart';
import '../niagara/models/port_type.dart' as niagara_port;
import '../providers/wiresheets_provider.dart';
import '../utils/logger.dart';

class WiresheetFlowScreen extends ConsumerStatefulWidget {
  final String wiresheetId;

  const WiresheetFlowScreen({
    super.key,
    required this.wiresheetId,
  });

  @override
  ConsumerState<WiresheetFlowScreen> createState() =>
      _WiresheetFlowScreenState();
}

class _WiresheetFlowScreenState extends ConsumerState<WiresheetFlowScreen> {
  late FlowManager _flowManager;

  final CommandHistory _commandHistory = CommandHistory();

  final Map<String, Offset> _componentPositions = {};
  final Map<String, GlobalKey> _componentKeys = {};
  final Map<String, double> _componentWidths = {};
  late FlowHandlers _flowHandlers;

  Offset? _selectionBoxStart;
  Offset? _selectionBoxEnd;
  bool _isDraggingSelectionBox = false;
  SlotDragInfo? _currentDraggedPort;
  Offset? _tempLineEndPoint;
  Offset? _dragStartPosition;
  Offset? _clipboardComponentPosition;
  final Set<Component> _selectedComponents = {};

  final TransformationController _transformationController =
      TransformationController();
  final GlobalKey _interactiveViewerChildKey = GlobalKey();

  final List<Component> _clipboardComponents = [];
  final List<Offset> _clipboardPositions = [];
  final List<Connection> _clipboardConnections = [];

  Wiresheet? _currentWiresheet;

  @override
  void initState() {
    super.initState();
    _flowManager = FlowManager();
    _transformationController.value = Matrix4.identity();

    // Initialize handlers
    _flowHandlers = FlowHandlers(
      flowManager: _flowManager,
      commandHistory: _commandHistory,
      componentPositions: _componentPositions,
      componentKeys: _componentKeys,
      componentWidths: _componentWidths,
      setState: setState,
      updateCanvasSize: _updateCanvasSize,
      selectedComponents: _selectedComponents,
      clipboardComponents: _clipboardComponents,
      clipboardPositions: _clipboardPositions,
      clipboardConnections: _clipboardConnections,
      setClipboardComponentPosition: (position) {
        setState(() {
          _clipboardComponentPosition = position;
        });
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      GestureBinding.instance.pointerRouter.addGlobalRoute(_handlePointerEvent);
    });

    _loadWiresheet();
  }

  @override
  void dispose() {
    GestureBinding.instance.pointerRouter
        .removeGlobalRoute(_handlePointerEvent);
    super.dispose();
  }

  @override
  void didUpdateWidget(WiresheetFlowScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.wiresheetId != widget.wiresheetId) {
      _loadWiresheet();
    }
  }

  void _loadWiresheet() {
    final wiresheet = ref
        .read(wiresheetsProvider)
        .firstWhere((w) => w.id == widget.wiresheetId);

    setState(() {
      _currentWiresheet = wiresheet;

      _flowManager = FlowManager();
      _componentPositions.clear();
      _componentKeys.clear();
      _componentWidths.clear();
      _selectedComponents.clear();

      _transformationController.value = Matrix4.identity();

      _convertCanvasItemsToComponents(wiresheet);

      _flowManager.recalculateAll();
      _commandHistory.clear();
    });
  }

  void _initializeComponents(Wiresheet wiresheet) {
    if (wiresheet.canvasItems.isNotEmpty) {
      _convertCanvasItemsToComponents(wiresheet);
    } else {
      final numericWritable = PointComponent(
        id: 'Numeric Writable',
        type:
            const niagara.ComponentType(niagara.ComponentType.NUMERIC_WRITABLE),
      );
      _flowManager.addComponent(numericWritable);
      _componentPositions[numericWritable.id] = const Offset(500, 250);
      _componentKeys[numericWritable.id] = GlobalKey();
      _componentWidths[numericWritable.id] = 160.0;

      final numericPoint = PointComponent(
        id: 'Numeric Point',
        type: const niagara.ComponentType(niagara.ComponentType.NUMERIC_POINT),
      );
      _flowManager.addComponent(numericPoint);
      _componentPositions[numericPoint.id] = const Offset(900, 250);
      _componentKeys[numericPoint.id] = GlobalKey();
      _componentWidths[numericPoint.id] = 160.0;

      _saveWiresheet();
    }

    _updateCanvasSize();

    _flowManager.recalculateAll();
    _commandHistory.clear();
  }

  void _updateCanvasSize() {
    if (_currentWiresheet == null) return;

    if (_componentPositions.isEmpty) {
      ref
          .read(wiresheetsProvider.notifier)
          .updateCanvasSize(widget.wiresheetId, const Size(2000, 2000));
      return;
    }

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    const canvasPadding = 100.0;
    const estimatedWidth = 180.0;
    const estimatedHeight = 120.0;

    for (var entry in _componentPositions.entries) {
      final position = entry.value;
      minX = min(minX, position.dx);
      minY = min(minY, position.dy);
      maxX = max(maxX, position.dx + estimatedWidth);
      maxY = max(maxY, position.dy + estimatedHeight);
    }

    final newWidth = max(2000.0, maxX + canvasPadding);
    final newHeight = max(2000.0, maxY + canvasPadding);

    if (newWidth != _currentWiresheet!.canvasSize.width ||
        newHeight != _currentWiresheet!.canvasSize.height) {
      ref
          .read(wiresheetsProvider.notifier)
          .updateCanvasSize(widget.wiresheetId, Size(newWidth, newHeight));
    }
  }

  void _saveWiresheet() {
    if (_currentWiresheet == null) return;

    final currentWiresheet = ref
        .read(wiresheetsProvider)
        .firstWhere((w) => w.id == widget.wiresheetId);

    final canvasItems = _convertComponentsToCanvasItems();
    final links = _convertConnectionsToLinks();

    Wiresheet updatedWiresheet = Wiresheet(
      id: currentWiresheet.id,
      name: currentWiresheet.name,
      createdAt: currentWiresheet.createdAt,
      modifiedAt: DateTime.now(),
      canvasItems: canvasItems,
      links: links,
      canvasSize: currentWiresheet.canvasSize,
      canvasOffset: currentWiresheet.canvasOffset,
    );

    for (int i = 0; i < currentWiresheet.canvasItems.length; i++) {
      if (i < canvasItems.length) {
        ref.read(wiresheetsProvider.notifier).updateWiresheetItem(
              currentWiresheet.id,
              i,
              canvasItems[i],
            );
      }
    }

    if (canvasItems.length > currentWiresheet.canvasItems.length) {
      for (int i = currentWiresheet.canvasItems.length;
          i < canvasItems.length;
          i++) {
        ref.read(wiresheetsProvider.notifier).addWiresheetItem(
              currentWiresheet.id,
              canvasItems[i],
            );
      }
    }

    if (canvasItems.length < currentWiresheet.canvasItems.length) {
      for (int i = currentWiresheet.canvasItems.length - 1;
          i >= canvasItems.length;
          i--) {
        ref.read(wiresheetsProvider.notifier).removeWiresheetItem(
              currentWiresheet.id,
              i,
            );
      }
    }

    for (final link in currentWiresheet.links) {
      ref.read(wiresheetsProvider.notifier).removeLink(
            currentWiresheet.id,
            link.id,
          );
    }

    for (final link in links) {
      ref.read(wiresheetsProvider.notifier).addLink(
            currentWiresheet.id,
            link,
          );
    }

    ref.read(wiresheetsProvider.notifier).updateCanvasSize(
          currentWiresheet.id,
          updatedWiresheet.canvasSize,
        );

    if (updatedWiresheet.canvasOffset != currentWiresheet.canvasOffset) {
      ref.read(wiresheetsProvider.notifier).updateCanvasOffset(
            currentWiresheet.id,
            updatedWiresheet.canvasOffset,
          );
    }

    _currentWiresheet = updatedWiresheet;
  }

  // Handle component addition from drag-drop
  void _handleComponentDrop(
      Map<String, dynamic> componentData, Offset position) {
    final componentType = componentData["componentType"] as String;
    final label = componentData["label"] as String;

    Component newComponent;

    if (componentType == ComponentType.HELVAR_DEVICE &&
        componentData["deviceData"] != null) {
      final deviceData = componentData["deviceData"] as Map<String, dynamic>;

      newComponent = HelvarDeviceComponent(
        id: label,
        deviceId: deviceData["deviceId"],
        deviceAddress: deviceData["deviceAddress"],
        deviceType: deviceData["deviceType"],
        description: deviceData["description"],
      );
    } else {
      String newName = '$label ${_flowManager.components.length + 1}';
      newComponent = _flowManager.createComponentByType(newName, componentType);
    }

    final newKey = GlobalKey();

    Map<String, dynamic> state = {
      'position': position,
      'key': newKey,
      'positions': _componentPositions,
      'keys': _componentKeys,
    };

    setState(() {
      final command = AddComponentCommand(_flowManager, newComponent, state);
      _commandHistory.execute(command);
      _componentWidths[newComponent.id] = 160.0;
      _componentPositions[newComponent.id] = position;
      _componentKeys[newComponent.id] = newKey;

      // Select the new component
      _selectedComponents.clear();
      _selectedComponents.add(newComponent);

      _updateCanvasSize();
      _saveWiresheet();
    });
  }

  void _handlePointerEvent(PointerEvent event) {
    if (event is PointerMoveEvent) {
      if (_currentDraggedPort != null) {
        setState(() {
          final RenderBox box = context.findRenderObject() as RenderBox;
          _tempLineEndPoint = box.globalToLocal(event.position);
        });
      }
    }
  }

  void _onPanStart(DragStartDetails details) {
    Offset? canvasPosition = getPosition(details.globalPosition);
    if (canvasPosition != null) {
      bool isClickOnComponent = false;

      for (final componentId in _componentPositions.keys) {
        final componentPos = _componentPositions[componentId]!;
        final double componentWidth = _componentWidths[componentId] ?? 160.0;
        final componentHeight =
            _flowManager.findComponentById(componentId)?.allSlots.length ??
                0 * 36.0;

        final componentRect = Rect.fromLTWH(
          componentPos.dx,
          componentPos.dy,
          componentWidth,
          componentHeight + 50, // Add some padding for the header
        );

        if (componentRect.contains(canvasPosition)) {
          isClickOnComponent = true;
          break;
        }
      }

      if (!isClickOnComponent) {
        setState(() {
          _isDraggingSelectionBox = true;
          _selectionBoxStart = canvasPosition;
          _selectionBoxEnd = canvasPosition;
        });
      }
    }
  }

// Complete the onPanUpdate method for selection box
  void _onPanUpdate(DragUpdateDetails details) {
    if (_isDraggingSelectionBox) {
      Offset? canvasPosition = getPosition(details.globalPosition);
      if (canvasPosition != null) {
        setState(() {
          _selectionBoxEnd = canvasPosition;
        });
      }
    }
  }

// Complete the onPanEnd method for selection box
  void _onPanEnd(DragEndDetails details) {
    if (_isDraggingSelectionBox &&
        _selectionBoxStart != null &&
        _selectionBoxEnd != null) {
      final selectionRect =
          Rect.fromPoints(_selectionBoxStart!, _selectionBoxEnd!);

      setState(() {
        if (!HardwareKeyboard.instance.isControlPressed) {
          _selectedComponents.clear();
        }

        for (final component in _flowManager.components) {
          final componentPos = _componentPositions[component.id];
          if (componentPos != null) {
            final double componentWidth =
                _componentWidths[component.id] ?? 160.0;
            final componentHeight = component.allSlots.length * 36.0;

            final componentRect = Rect.fromLTWH(
              componentPos.dx,
              componentPos.dy,
              componentWidth,
              componentHeight + 50, // Add some padding for the header
            );

            if (selectionRect.overlaps(componentRect)) {
              _selectedComponents.add(component);
            }
          }
        }

        _isDraggingSelectionBox = false;
        _selectionBoxStart = null;
        _selectionBoxEnd = null;
      });
    }
  }

// Show context menu for component creation
  void _showCanvasContextMenu(BuildContext context, Offset position) {
    Offset? canvasPosition = getPosition(position);
    if (canvasPosition == null) return;

    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(position, position),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          value: 'add-component',
          child: Row(
            children: const [
              Icon(Icons.add_box, size: 18),
              SizedBox(width: 8),
              Text('Add Component'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'paste',
          child: Row(
            children: [
              Icon(Icons.paste,
                  size: 18,
                  color: _clipboardComponents.isNotEmpty ? null : Colors.grey),
              const SizedBox(width: 8),
              Text('Paste',
                  style: TextStyle(
                      color: _clipboardComponents.isNotEmpty
                          ? null
                          : Colors.grey)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'select-all',
          child: Row(
            children: [
              Icon(Icons.select_all, size: 18),
              SizedBox(width: 8),
              Text('Select All'),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == null) return;

      switch (value) {
        case 'add-component':
          _showAddComponentDialog(canvasPosition);
          break;
        case 'paste':
          if (_clipboardComponents.isNotEmpty) {
            _flowHandlers.handlePasteComponent(canvasPosition);
            _saveWiresheet();
          }
          break;
        case 'select-all':
          setState(() {
            _selectedComponents.clear();
            _selectedComponents.addAll(_flowManager.components);
          });
          break;
      }
    });
  }

// Show dialog to add a new component
  void _showAddComponentDialog(Offset position) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
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
                      ComponentType.NOT_GATE,
                      ComponentType.IS_GREATER_THAN,
                    ],
                    position),
                _buildComponentCategorySection(
                    'Math Operations',
                    [
                      ComponentType.ADD,
                      ComponentType.SUBTRACT,
                      ComponentType.MULTIPLY,
                      ComponentType.DIVIDE,
                    ],
                    position),
                _buildComponentCategorySection(
                    'Writable Points',
                    [
                      ComponentType.BOOLEAN_WRITABLE,
                      ComponentType.NUMERIC_WRITABLE,
                      ComponentType.STRING_WRITABLE,
                    ],
                    position),
                _buildComponentCategorySection(
                    'Read-Only Points',
                    [
                      ComponentType.BOOLEAN_POINT,
                      ComponentType.NUMERIC_POINT,
                      ComponentType.STRING_POINT,
                    ],
                    position),
              ],
            ),
          ),
        );
      },
    );
  }

// Helper method to build a section of component types
  Widget _buildComponentCategorySection(
      String title, List<String> typeStrings, Offset position) {
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
          children: typeStrings.map((typeString) {
            final componentType = ComponentType(typeString);
            IconData icon = _getIconForComponentType(componentType);
            String name = _getNameForComponentType(componentType);

            return InkWell(
              onTap: () {
                String componentId =
                    '${name}_${const Uuid().v4().substring(0, 8)}';
                Component newComponent =
                    _flowManager.createComponentByType(componentId, typeString);

                final newKey = GlobalKey();
                Map<String, dynamic> state = {
                  'position': position,
                  'key': newKey,
                  'positions': _componentPositions,
                  'keys': _componentKeys,
                };

                setState(() {
                  final command =
                      AddComponentCommand(_flowManager, newComponent, state);
                  _commandHistory.execute(command);
                  _componentWidths[newComponent.id] = 160.0;
                  _componentPositions[newComponent.id] = position;
                  _componentKeys[newComponent.id] = newKey;

                  // Select the new component
                  _selectedComponents.clear();
                  _selectedComponents.add(newComponent);

                  _updateCanvasSize();
                  _saveWiresheet();
                });

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
                    Icon(icon),
                    const SizedBox(height: 4.0),
                    Text(name),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

// Helper method to get icon for component type
  IconData _getIconForComponentType(ComponentType type) {
    switch (type.type) {
      case ComponentType.AND_GATE:
        return Icons.call_merge;
      case ComponentType.OR_GATE:
        return Icons.call_split;
      case ComponentType.NOT_GATE:
        return Icons.block;
      case ComponentType.IS_GREATER_THAN:
        return Icons.trending_up;
      case ComponentType.IS_LESS_THAN:
        return Icons.trending_down;
      case ComponentType.IS_EQUAL:
        return Icons.drag_handle;

      case ComponentType.ADD:
        return Icons.add;
      case ComponentType.SUBTRACT:
        return Icons.remove;
      case ComponentType.MULTIPLY:
        return Icons.close;
      case ComponentType.DIVIDE:
        return Icons.expand;

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

      case ComponentType.HELVAR_DEVICE:
        return Icons.device_hub;
      case ComponentType.HELVAR_OUTPUT:
        return Icons.lightbulb_outline;
      case ComponentType.HELVAR_INPUT:
        return Icons.input;
      case ComponentType.HELVAR_EMERGENCY:
        return Icons.local_fire_department;

      default:
        return Icons.help_outline;
    }
  }

// Helper method to get name for component type
  String _getNameForComponentType(ComponentType type) {
    switch (type.type) {
      case ComponentType.AND_GATE:
        return 'AND Gate';
      case ComponentType.OR_GATE:
        return 'OR Gate';
      case ComponentType.NOT_GATE:
        return 'NOT Gate';
      case ComponentType.IS_GREATER_THAN:
        return 'Greater Than';
      case ComponentType.IS_LESS_THAN:
        return 'Less Than';
      case ComponentType.IS_EQUAL:
        return 'Equals';

      case ComponentType.ADD:
        return 'Add';
      case ComponentType.SUBTRACT:
        return 'Subtract';
      case ComponentType.MULTIPLY:
        return 'Multiply';
      case ComponentType.DIVIDE:
        return 'Divide';

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

      case ComponentType.HELVAR_DEVICE:
        return 'Helvar Device';

      default:
        return 'Unknown Component';
    }
  }

  void _copyWiresheet() {
    if (_currentWiresheet == null) return;

    showDialog(
      context: context,
      builder: (context) {
        final controller =
            TextEditingController(text: "${_currentWiresheet!.name} Copy");

        return AlertDialog(
          title: const Text('Copy Wiresheet'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'New Wiresheet Name',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  ref
                      .read(wiresheetsProvider.notifier)
                      .duplicateWiresheet(_currentWiresheet!.id, newName)
                      .then((wiresheet) {
                    Navigator.pop(context);
                    if (wiresheet != null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Wiresheet "$newName" created')));
                    }
                  });
                }
              },
              child: const Text('Create Copy'),
            ),
          ],
        );
      },
    );
  }

  // Delete current wiresheet
  void _deleteWiresheet() {
    if (_currentWiresheet == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Wiresheet'),
        content: Text(
            'Are you sure you want to delete "${_currentWiresheet!.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(wiresheetsProvider.notifier)
                  .deleteWiresheet(_currentWiresheet!.id)
                  .then((success) {
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Wiresheet deleted')));
                  // Navigate back or to another wiresheet
                  Navigator.pop(context);
                }
              });
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get latest wiresheet from provider
    final wiresheets = ref.watch(wiresheetsProvider);
    final currentWiresheet = wiresheets.firstWhere(
      (sheet) => sheet.id == widget.wiresheetId,
      orElse: () => _currentWiresheet!,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(currentWiresheet.name),
        actions: [
          // Add wiresheet-specific actions
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy Wiresheet',
            onPressed: _copyWiresheet,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete Wiresheet',
            onPressed: _deleteWiresheet,
          ),
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: _commandHistory.canUndo
                ? 'Undo: ${_commandHistory.lastUndoDescription}'
                : 'Undo',
            onPressed: _commandHistory.canUndo
                ? () {
                    setState(() {
                      _commandHistory.undo();
                      _saveWiresheet();
                    });
                  }
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            tooltip: _commandHistory.canRedo
                ? 'Redo: ${_commandHistory.lastRedoDescription}'
                : 'Redo',
            onPressed: _commandHistory.canRedo
                ? () {
                    setState(() {
                      _commandHistory.redo();
                      _saveWiresheet();
                    });
                  }
                : null,
          ),
        ],
      ),
      body: Shortcuts(
        shortcuts: getShortcuts(),
        child: Actions(
          actions: <Type, Action<Intent>>{
            UndoIntent: CallbackAction<UndoIntent>(
              onInvoke: (UndoIntent intent) {
                if (_commandHistory.canUndo) {
                  setState(() {
                    _commandHistory.undo();
                    _saveWiresheet();
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
                    _saveWiresheet();
                  });
                }
                return null;
              },
            ),
            // Add more actions from flow_screen...
            SelectAllIntent: CallbackAction<SelectAllIntent>(
              onInvoke: (SelectAllIntent intent) {
                setState(() {
                  _selectedComponents.clear();
                  _selectedComponents.addAll(_flowManager.components);
                });
                return null;
              },
            ),
            DeleteIntent: CallbackAction<DeleteIntent>(
              onInvoke: (DeleteIntent intent) {
                setState(() {
                  if (_selectedComponents.isNotEmpty) {
                    for (var component in _selectedComponents.toList()) {
                      _flowHandlers.handleDeleteComponent(component);
                    }
                    _selectedComponents.clear();
                    _saveWiresheet();
                  }
                });
                return null;
              },
            ),
            // Add more keyboard actions...
          },
          child: Focus(
            autofocus: true,
            child: ClipRect(
              child: InteractiveViewer(
                transformationController: _transformationController,
                boundaryMargin: const EdgeInsets.all(1000),
                minScale: 0.1,
                constrained: false,
                maxScale: 3.0,
                panEnabled: true,
                scaleEnabled: true,
                child: DragTarget<Map<String, dynamic>>(
                  onAcceptWithDetails: (details) {
                    final data = details.data;
                    final globalPosition = details.offset;
                    final RenderBox box =
                        context.findRenderObject() as RenderBox;
                    final localPosition = box.globalToLocal(globalPosition);

                    final matrix = _transformationController.value;
                    final inverseMatrix = Matrix4.inverted(matrix);
                    final canvasPosition = MatrixUtils.transformPoint(
                        inverseMatrix, localPosition);

                    _handleComponentDrop(data, canvasPosition);
                  },
                  builder: (context, candidateData, rejectedData) {
                    return CustomPaint(
                      key: _interactiveViewerChildKey,
                      foregroundPainter: ConnectionPainter(
                        flowManager: _flowManager,
                        componentPositions: _componentPositions,
                        componentKeys: _componentKeys,
                        componentWidths: _componentWidths,
                        tempLineStartInfo: _currentDraggedPort,
                        tempLineEndPoint: _tempLineEndPoint,
                      ),
                      child: GestureDetector(
                        onTapDown: (details) {
                          Offset? canvasPosition =
                              getPosition(details.globalPosition);
                          if (canvasPosition != null) {
                            setState(() {
                              _selectionBoxStart = canvasPosition;
                              _isDraggingSelectionBox = false;
                              _selectedComponents.clear();
                            });
                          }
                        },
                        onPanStart: _onPanStart,
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: _onPanEnd,
                        onDoubleTapDown: (details) {
                          _showCanvasContextMenu(
                              context, details.globalPosition);
                        },
                        child: Container(
                          width: currentWiresheet.canvasSize.width,
                          height: currentWiresheet.canvasSize.height,
                          color: Colors.grey[50],
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CustomPaint(
                                painter: GridPainter(),
                                size: currentWiresheet.canvasSize,
                              ),
                              if (_isDraggingSelectionBox &&
                                  _selectionBoxStart != null &&
                                  _selectionBoxEnd != null)
                                CustomPaint(
                                  painter: SelectionBoxPainter(
                                    start: _selectionBoxStart,
                                    end: _selectionBoxEnd,
                                  ),
                                  size: currentWiresheet.canvasSize,
                                ),
                              if (_flowManager.components.isEmpty)
                                const Center(
                                  child: Text(
                                    'Drag components from the tree view or double-click to add components',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              // Replace the placeholder Draggable in the build method with this:
                              ..._flowManager.components.map(
                                (component) {
                                  return Positioned(
                                    left:
                                        _componentPositions[component.id]?.dx ??
                                            0,
                                    top:
                                        _componentPositions[component.id]?.dy ??
                                            0,
                                    child: Draggable<String>(
                                      data: component.id,
                                      feedback: Material(
                                        elevation: 5.0,
                                        color: Colors.transparent,
                                        child: ComponentWidget(
                                          component: component,
                                          height:
                                              component.allSlots.length * 36.0,
                                          isSelected: _selectedComponents
                                              .contains(component),
                                          widgetKey:
                                              _componentKeys[component.id] ??
                                                  GlobalKey(),
                                          position: _componentPositions[
                                                  component.id] ??
                                              Offset.zero,
                                          width:
                                              _componentWidths[component.id] ??
                                                  160.0,
                                          onValueChanged:
                                              _flowHandlers.handleValueChanged,
                                          onSlotDragStarted:
                                              _handlePortDragStarted,
                                          onSlotDragAccepted:
                                              _handlePortDragAccepted,
                                          onWidthChanged:
                                              _flowHandlers.handleWidthChanged,
                                        ),
                                      ),
                                      childWhenDragging: Opacity(
                                        opacity: 0.3,
                                        child: ComponentWidget(
                                          component: component,
                                          height:
                                              component.allSlots.length * 36.0,
                                          isSelected: _selectedComponents
                                              .contains(component),
                                          widgetKey: GlobalKey(),
                                          position: _componentPositions[
                                                  component.id] ??
                                              Offset.zero,
                                          width:
                                              _componentWidths[component.id] ??
                                                  160.0,
                                          onValueChanged:
                                              _flowHandlers.handleValueChanged,
                                          onSlotDragStarted:
                                              _handlePortDragStarted,
                                          onSlotDragAccepted:
                                              _handlePortDragAccepted,
                                          onWidthChanged:
                                              _flowHandlers.handleWidthChanged,
                                        ),
                                      ),
                                      onDragStarted: () {
                                        _dragStartPosition =
                                            _componentPositions[component.id];
                                      },
                                      onDragEnd: (details) {
                                        final RenderBox? viewerChildRenderBox =
                                            _interactiveViewerChildKey
                                                    .currentContext
                                                    ?.findRenderObject()
                                                as RenderBox?;

                                        if (viewerChildRenderBox != null) {
                                          final Offset localOffset =
                                              viewerChildRenderBox
                                                  .globalToLocal(
                                                      details.offset);

                                          if (_dragStartPosition != null &&
                                              _dragStartPosition !=
                                                  localOffset) {
                                            setState(() {
                                              final offset = localOffset -
                                                  _dragStartPosition!;

                                              if (_selectedComponents
                                                      .contains(component) &&
                                                  _selectedComponents.length >
                                                      1) {
                                                for (var selectedComponent
                                                    in _selectedComponents) {
                                                  final currentPos =
                                                      _componentPositions[
                                                          selectedComponent.id];
                                                  if (currentPos != null) {
                                                    final newPos =
                                                        currentPos + offset;
                                                    final command =
                                                        MoveComponentCommand(
                                                      selectedComponent.id,
                                                      newPos,
                                                      currentPos,
                                                      _componentPositions,
                                                    );
                                                    _commandHistory
                                                        .execute(command);
                                                  }
                                                }
                                              } else {
                                                final command =
                                                    MoveComponentCommand(
                                                  component.id,
                                                  localOffset,
                                                  _dragStartPosition!,
                                                  _componentPositions,
                                                );
                                                _commandHistory
                                                    .execute(command);

                                                _selectedComponents.clear();
                                                _selectedComponents
                                                    .add(component);
                                              }

                                              _dragStartPosition = null;
                                              _updateCanvasSize();
                                              _saveWiresheet();
                                            });
                                          }
                                        }
                                      },
                                      child: GestureDetector(
                                        onSecondaryTapDown: (details) {
                                          _showComponentContextMenu(
                                              context,
                                              details.globalPosition,
                                              component);
                                        },
                                        onTap: () {
                                          if (HardwareKeyboard
                                              .instance.isControlPressed) {
                                            setState(() {
                                              if (_selectedComponents
                                                  .contains(component)) {
                                                _selectedComponents
                                                    .remove(component);
                                              } else {
                                                _selectedComponents
                                                    .add(component);
                                              }
                                            });
                                          } else {
                                            setState(() {
                                              _selectedComponents.clear();
                                              _selectedComponents
                                                  .add(component);
                                            });
                                          }
                                        },
                                        child: ComponentWidget(
                                          component: component,
                                          height:
                                              component.allSlots.length * 36.0,
                                          width:
                                              _componentWidths[component.id] ??
                                                  160.0,
                                          onWidthChanged:
                                              _flowHandlers.handleWidthChanged,
                                          isSelected: _selectedComponents
                                              .contains(component),
                                          widgetKey:
                                              _componentKeys[component.id] ??
                                                  GlobalKey(),
                                          position: _componentPositions[
                                                  component.id] ??
                                              Offset.zero,
                                          onValueChanged:
                                              _flowHandlers.handleValueChanged,
                                          onSlotDragStarted:
                                              _handlePortDragStarted,
                                          onSlotDragAccepted:
                                              _handlePortDragAccepted,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Show context menu for a component
  void _showComponentContextMenu(
      BuildContext context, Offset position, Component component) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(position, position),
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
          if (_selectedComponents.length == 1) {
            _flowHandlers.handleCopyComponent(_selectedComponents.first);
          } else if (_selectedComponents.isNotEmpty) {
            _flowHandlers.handleCopyMultipleComponents();
          }
          break;
        case 'edit':
          _flowHandlers.handleEditComponent(context, component);
          break;
        case 'delete':
          setState(() {
            _flowHandlers.handleDeleteComponent(component);
            _saveWiresheet();
          });
          break;
      }
    });
  }

  Offset? getPosition(Offset globalPosition) {
    final RenderBox? viewerChildRenderBox =
        _interactiveViewerChildKey.currentContext?.findRenderObject()
            as RenderBox?;

    if (viewerChildRenderBox != null) {
      final Offset localPosition =
          viewerChildRenderBox.globalToLocal(globalPosition);

      final matrix = _transformationController.value;
      final inverseMatrix = Matrix4.inverted(matrix);
      final canvasPosition =
          MatrixUtils.transformPoint(inverseMatrix, localPosition);
      return canvasPosition;
    }
    return null;
  }

  // Complete port handling methods
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
            // Create the component connection
            final command = CreateConnectionCommand(
              _flowManager,
              _currentDraggedPort!.componentId,
              _currentDraggedPort!.slotIndex,
              targetSlotInfo.componentId,
              targetSlotInfo.slotIndex,
            );
            _commandHistory.execute(command);

            // Create wiresheet link
            String sourcePortId = _getPortIdFromSlotIndex(
                sourceComponent, _currentDraggedPort!.slotIndex);

            String targetPortId = _getPortIdFromSlotIndex(
                targetComponent, targetSlotInfo.slotIndex);

            if (sourcePortId.isNotEmpty && targetPortId.isNotEmpty) {
              // Create a new link object
              Link newLink = Link(
                id: const Uuid().v4(),
                sourceItemId: _currentDraggedPort!.componentId,
                sourcePortId: sourcePortId,
                targetItemId: targetSlotInfo.componentId,
                targetPortId: targetPortId,
                type: LinkType.dataFlow,
              );

              // Save to wiresheet
              if (_currentWiresheet != null) {
                ref.read(wiresheetsProvider.notifier).addLink(
                      _currentWiresheet!.id,
                      newLink,
                    );
              }
            }

            _saveWiresheet();
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

  void _convertCanvasItemsToComponents(Wiresheet wiresheet) {
    _flowManager = FlowManager();
    _componentPositions.clear();
    _componentKeys.clear();
    _componentWidths.clear();
    _selectedComponents.clear();

    for (final item in wiresheet.canvasItems) {
      Component? component = _createComponentFromCanvasItem(item);

      if (component != null) {
        _flowManager.addComponent(component);
        _componentPositions[component.id] = item.position;
        _componentKeys[component.id] = GlobalKey();
        _componentWidths[component.id] = item.size.width;
      }
    }

    for (final link in wiresheet.links) {
      _createConnectionFromLink(link);
    }
  }

  Component? _createComponentFromCanvasItem(CanvasItem item) {
    if (item.id == null) return null;

    Component? component;

    if (item.properties.containsKey('device_id')) {
      final deviceId = item.properties['device_id'] as int;
      final deviceAddress = item.properties['device_address'] as String;
      final deviceType = item.properties['device_type'] as String;

      component = HelvarDeviceComponent(
        id: item.id!,
        deviceId: deviceId,
        deviceAddress: deviceAddress,
        deviceType: deviceType,
        description: item.label ?? 'Device $deviceId',
      );
    } else if (item.category != null) {
      String componentType = "";

      switch (item.category!) {
        case ComponentCategory.logic:
          final logicType = item.properties['logic_type'] as String? ?? "";
          switch (logicType) {
            case "AND":
              componentType = ComponentType.AND_GATE;
              break;
            case "OR":
              componentType = ComponentType.OR_GATE;
              break;
            case "GreaterThan":
              componentType = ComponentType.IS_GREATER_THAN;
              break;
            case "IF":
              componentType = ComponentType.IS_EQUAL;
              break;
            default:
              componentType = ComponentType.AND_GATE;
          }
          break;

        case ComponentCategory.math:
          final operation = item.properties['operation'] as String? ?? "";
          switch (operation) {
            case "ADD":
              componentType = ComponentType.ADD;
              break;
            case "SUBTRACT":
              componentType = ComponentType.SUBTRACT;
              break;
            case "MULTIPLY":
              componentType = ComponentType.MULTIPLY;
              break;
            case "DIVIDE":
              componentType = ComponentType.DIVIDE;
              break;
            case "MODULO":
              componentType = ComponentType.MIN;
              break;
            case "POWER":
              componentType = ComponentType.POWER;
              break;
            default:
              componentType = ComponentType.ADD;
          }
          break;

        case ComponentCategory.point:
          final pointType = item.properties['point'] as String? ?? "";
          switch (pointType) {
            case "NumericPoint":
              componentType = ComponentType.NUMERIC_POINT;
              break;
            case "NumericWritable":
              componentType = ComponentType.NUMERIC_WRITABLE;
              break;
            case "BooleanPoint":
              componentType = ComponentType.BOOLEAN_POINT;
              break;
            case "BooleanWritable":
              componentType = ComponentType.BOOLEAN_WRITABLE;
              break;
            case "StringPoint":
              componentType = ComponentType.STRING_POINT;
              break;
            case "StringWritable":
              componentType = ComponentType.STRING_WRITABLE;
              break;
            default:
              componentType = ComponentType.NUMERIC_POINT;
          }
          break;

        case ComponentCategory.ui:
          final uiType = item.properties['ui_type'] as String? ?? "";
          // UI components don't have direct mappings, so we'll treat them as points
          componentType = ComponentType.STRING_POINT;
          break;

        case ComponentCategory.util:
          final utilType = item.properties['util_type'] as String? ?? "";
          // Util components don't have direct mappings
          componentType = ComponentType.NUMERIC_POINT;
          break;
      }

      component = _flowManager.createComponentByType(item.id!, componentType);
    }

    // Set initial property values if available
    if (component != null) {
      // TODO: Set property values from canvas item
    }

    return component;
  }

// Create a connection from a wiresheet link
  void _createConnectionFromLink(Link link) {
    final sourceComponent = _flowManager.findComponentById(link.sourceItemId);
    final targetComponent = _flowManager.findComponentById(link.targetItemId);

    if (sourceComponent == null || targetComponent == null) return;

    // Convert port IDs to slot indices
    int sourceSlotIndex =
        _getSlotIndexFromPortId(sourceComponent, link.sourcePortId);
    int targetSlotIndex =
        _getSlotIndexFromPortId(targetComponent, link.targetPortId);

    if (sourceSlotIndex >= 0 && targetSlotIndex >= 0) {
      _flowManager.createConnection(link.sourceItemId, sourceSlotIndex,
          link.targetItemId, targetSlotIndex);
    }
  }

// Convert port ID to slot index
  int _getSlotIndexFromPortId(Component component, String portId) {
    // In Component, slots are indexed numerically
    // In CanvasItem, ports have string IDs

    // First check properties (most common)
    for (int i = 0; i < component.properties.length; i++) {
      // Match by name or other criteria
      if (component.properties[i].name.toLowerCase() == portId.toLowerCase()) {
        return component.properties[i].index;
      }
    }

    // Then check actions
    for (int i = 0; i < component.actions.length; i++) {
      if (component.actions[i].name.toLowerCase() == portId.toLowerCase() ||
          component.actions[i].name.replaceAll(" ", "").toLowerCase() ==
              portId.toLowerCase()) {
        return component.actions[i].index;
      }
    }

    // Then check topics
    for (int i = 0; i < component.topics.length; i++) {
      if (component.topics[i].name.toLowerCase() == portId.toLowerCase()) {
        return component.topics[i].index;
      }
    }

    // For device components, match action names directly
    if (component is HelvarDeviceComponent) {
      try {
        // Try to match DeviceAction enum names
        return component.actions.indexWhere(
            (action) => action.name.toLowerCase() == portId.toLowerCase());
      } catch (e) {
        logError("Error matching device action: $e");
      }
    }

    return -1; // Port ID not found
  }

// Convert Niagara components back to wiresheet canvas items
  List<CanvasItem> _convertComponentsToCanvasItems() {
    List<CanvasItem> canvasItems = [];

    for (final component in _flowManager.components) {
      CanvasItem? item = _createCanvasItemFromComponent(component);
      if (item != null) {
        canvasItems.add(item);
      }
    }

    return canvasItems;
  }

// Create a canvas item from a component
  CanvasItem? _createCanvasItemFromComponent(Component component) {
    final position = _componentPositions[component.id] ?? Offset.zero;
    final width = _componentWidths[component.id] ?? 160.0;
    final height = component.allSlots.length * 36.0 + 50.0; // Add header height

    // Determine type and category based on component
    CanvasItem item;

    if (component is HelvarDeviceComponent) {
      // Create device item
      item = CanvasItem(
        id: component.id,
        type: WidgetType.treenode, // Using treenode type for all components
        position: position,
        size: Size(width, height),
        label: component.description,
        properties: {
          'device_id': component.deviceId,
          'device_address': component.deviceAddress,
          'device_type': component.deviceType,
        },
        category: ComponentCategory.logic, // Just use a placeholder category
      );

      // Add ports based on component's slots
      _addPortsFromComponent(item, component);
    } else if (component.type.isLogicGate) {
      // Logic component
      String logicType = "";
      switch (component.type.type) {
        case ComponentType.AND_GATE:
          logicType = "AND";
          break;
        case ComponentType.OR_GATE:
          logicType = "OR";
          break;
        case ComponentType.IS_GREATER_THAN:
          logicType = "GreaterThan";
          break;
        case ComponentType.IS_EQUAL:
          logicType = "IF";
          break;
        default:
          logicType = "AND";
      }

      item = CanvasItem(
        id: component.id,
        type: WidgetType.treenode,
        position: position,
        size: Size(width, height),
        label: component.id,
        properties: {'logic_type': logicType},
        category: ComponentCategory.logic,
      );

      // Add ports
      _addPortsFromComponent(item, component);
    } else if (component.type.isMathOperation) {
      // Math component
      String operation = "";
      switch (component.type.type) {
        case ComponentType.ADD:
          operation = "ADD";
          break;
        case ComponentType.SUBTRACT:
          operation = "SUBTRACT";
          break;
        case ComponentType.MULTIPLY:
          operation = "MULTIPLY";
          break;
        case ComponentType.DIVIDE:
          operation = "DIVIDE";
          break;
        case ComponentType.POWER:
          operation = "POWER";
          break;
        default:
          operation = "ADD";
      }

      item = CanvasItem(
        id: component.id,
        type: WidgetType.treenode,
        position: position,
        size: Size(width, height),
        label: component.id,
        properties: {'operation': operation},
        category: ComponentCategory.math,
      );

      // Add ports
      _addPortsFromComponent(item, component);
    } else if (component.type.isPoint) {
      // Point component
      String pointType = "";
      switch (component.type.type) {
        case ComponentType.NUMERIC_POINT:
          pointType = "NumericPoint";
          break;
        case ComponentType.NUMERIC_WRITABLE:
          pointType = "NumericWritable";
          break;
        case ComponentType.BOOLEAN_POINT:
          pointType = "BooleanPoint";
          break;
        case ComponentType.BOOLEAN_WRITABLE:
          pointType = "BooleanWritable";
          break;
        case ComponentType.STRING_POINT:
          pointType = "StringPoint";
          break;
        case ComponentType.STRING_WRITABLE:
          pointType = "StringWritable";
          break;
        default:
          pointType = "NumericPoint";
      }

      item = CanvasItem(
        id: component.id,
        type: WidgetType.treenode,
        position: position,
        size: Size(width, height),
        label: component.id,
        properties: {'point': pointType},
        category: ComponentCategory.point,
      );

      // Add ports
      _addPortsFromComponent(item, component);
    } else {
      // Default generic component
      item = CanvasItem(
        id: component.id,
        type: WidgetType.treenode,
        position: position,
        size: Size(width, height),
        label: component.id,
        category: ComponentCategory.logic,
      );

      // Add ports
      _addPortsFromComponent(item, component);
    }

    return item;
  }

  void _addPortsFromComponent(CanvasItem item, Component component) {
    // Add ports from properties
    for (var property in component.properties) {
      item.addPort(Port(
        id: property.name.toLowerCase(),
        type: _convertPortType(property.type),
        name: property.name,
        isInput: property.isInput,
      ));
    }

    // Add ports from actions
    for (var action in component.actions) {
      item.addPort(Port(
        id: action.name.replaceAll(" ", "").toLowerCase(),
        type: action.parameterType != null
            ? _convertPortType(action.parameterType!)
            : PortType.any,
        name: action.name,
        isInput: true, // Actions are always inputs
      ));
    }

    // Add ports from topics
    for (var topic in component.topics) {
      item.addPort(Port(
        id: topic.name.toLowerCase(),
        type: _convertPortType(topic.eventType),
        name: topic.name,
        isInput: false, // Topics are always outputs
      ));
    }
  }

  PortType _convertPortType(niagara_port.PortType portType) {
    switch (portType.type) {
      case niagara_port.PortType.BOOLEAN:
        return PortType.boolean;
      case niagara_port.PortType.NUMERIC:
        return PortType.number;
      case niagara_port.PortType.STRING:
        return PortType.string;
      default:
        return PortType.any;
    }
  }

// Convert Niagara connections to wiresheet links
  List<Link> _convertConnectionsToLinks() {
    List<Link> links = [];

    for (final connection in _flowManager.connections) {
      Link? link = _createLinkFromConnection(connection);
      if (link != null) {
        links.add(link);
      }
    }

    return links;
  }

// Create a wiresheet link from a connection
  Link? _createLinkFromConnection(Connection connection) {
    final sourceComponent =
        _flowManager.findComponentById(connection.fromComponentId);
    final targetComponent =
        _flowManager.findComponentById(connection.toComponentId);

    if (sourceComponent == null || targetComponent == null) return null;

    // Convert slot indices to port IDs
    String sourcePortId =
        _getPortIdFromSlotIndex(sourceComponent, connection.fromPortIndex);
    String targetPortId =
        _getPortIdFromSlotIndex(targetComponent, connection.toPortIndex);

    if (sourcePortId.isNotEmpty && targetPortId.isNotEmpty) {
      return Link(
        id: const Uuid().v4(),
        sourceItemId: connection.fromComponentId,
        sourcePortId: sourcePortId,
        targetItemId: connection.toComponentId,
        targetPortId: targetPortId,
        type: LinkType.dataFlow, // Default to dataFlow type
      );
    }

    return null;
  }

  String _getPortIdFromSlotIndex(Component component, int slotIndex) {
    Slot? slot = component.getSlotByIndex(slotIndex);
    if (slot == null) return "";

    if (slot is Property) {
      return slot.name.toLowerCase();
    } else if (slot is ActionSlot) {
      return slot.name.replaceAll(" ", "").toLowerCase();
    } else if (slot is Topic) {
      return slot.name.toLowerCase();
    }

    return "";
  }
}
