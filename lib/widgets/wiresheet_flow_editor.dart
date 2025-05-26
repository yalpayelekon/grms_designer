import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grms_designer/models/flowsheet.dart';
import 'package:grms_designer/providers/button_point_status_provider.dart';
import 'package:grms_designer/providers/flowsheet_provider.dart';
import 'package:grms_designer/providers/workgroups_provider.dart';
import 'package:grms_designer/services/button_point_status_service.dart';
import 'package:grms_designer/utils/logger.dart';

import '../models/helvar_models/helvar_device.dart';
import '../models/helvar_models/input_device.dart';
import '../niagara/home/command.dart';
import '../niagara/home/handlers.dart';
import '../niagara/home/utils.dart';
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
import '../niagara/models/helvar_device_component.dart';
import '../niagara/models/port_type.dart';
import '../niagara/models/ramp_component.dart';
import '../niagara/models/rectangle.dart';
import '../services/flowsheet_storage_service.dart';
import '../utils/general_ui.dart';
import '../utils/persistent_helper.dart';

class WiresheetFlowEditor extends ConsumerStatefulWidget {
  final Flowsheet flowsheet;

  const WiresheetFlowEditor({
    super.key,
    required this.flowsheet,
  });

  @override
  WiresheetFlowEditorState createState() => WiresheetFlowEditorState();
}

class WiresheetFlowEditorState extends ConsumerState<WiresheetFlowEditor> {
  late FlowManager _flowManager;
  late CommandHistory _commandHistory;
  final GlobalKey _canvasKey = GlobalKey();

  final Map<String, Offset> _componentPositions = {};
  final Map<String, GlobalKey> _componentKeys = {};
  late FlowHandlers _flowHandlers;
  late PersistenceHelper _persistenceHelper;
  late FlowsheetStorageService _storageService;
  Offset? _selectionBoxStart;
  Offset? _selectionBoxEnd;
  bool _isDraggingSelectionBox = false;
  bool isPanelExpanded = false;
  SlotDragInfo? _currentDraggedPort;
  Offset? _tempLineEndPoint;
  Offset? _dragStartPosition;
  Offset? _clipboardComponentPosition;
  final TransformationController _transformationController =
      TransformationController();
  final GlobalKey _interactiveViewerChildKey = GlobalKey();
  final Map<String, double> _componentWidths = {};
  Size _canvasSize = const Size(2000, 2000);
  Offset _canvasOffset = Offset.zero; // Canvas position within the view
  static const double _canvasPadding = 100.0;

  final List<Component> _clipboardComponents = [];
  final List<Offset> _clipboardPositions = [];
  final List<Connection> _clipboardConnections = [];
  final Set<Component> _selectedComponents = {};

  @override
  void initState() {
    super.initState();
    _transformationController.value = Matrix4.identity();
    _flowManager = FlowManager();
    _commandHistory = CommandHistory();
    _storageService = ref.read(flowsheetStorageServiceProvider);
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

    _persistenceHelper = PersistenceHelper(
      flowsheet: widget.flowsheet,
      storageService: _storageService,
      flowManager: _flowManager,
      componentPositions: _componentPositions,
      componentWidths: _componentWidths,
      getMountedStatus: () => mounted,
      onFlowsheetUpdate: (updatedFlowsheet) {
        if (mounted) {
          ref.read(flowsheetsProvider.notifier).updateFlowsheet(
                widget.flowsheet.id,
                updatedFlowsheet,
              );
        }
      },
    );

    _initializeComponents();
    _initializeButtonPointStatusMonitoring();
  }

  @override
  void dispose() {
    final monitoringNotifier = ref.read(buttonPointMonitoringProvider.notifier);
    for (final metadata in _buttonPointMetadata.values) {
      final deviceAddress = metadata['deviceAddress'] as String;
      final workgroups = ref.read(workgroupsProvider);
      for (final workgroup in workgroups) {
        for (final router in workgroup.routers) {
          if (router.devices.any((d) => d.address == deviceAddress)) {
            monitoringNotifier.stopMonitoring(deviceAddress, router.ipAddress);
            break;
          }
        }
      }
    }

    _saveStateSync();
    super.dispose();
  }

  void _saveStateSync() {
    try {
      final updatedFlowsheet = widget.flowsheet.copy();
      updatedFlowsheet.components = _flowManager.components;

      final List<Connection> connections = [];
      for (final component in _flowManager.components) {
        for (final entry in component.inputConnections.entries) {
          connections.add(Connection(
            fromComponentId: entry.value.componentId,
            fromPortIndex: entry.value.portIndex,
            toComponentId: component.id,
            toPortIndex: entry.key,
          ));
        }
      }
      updatedFlowsheet.connections = connections;

      for (final entry in _componentPositions.entries) {
        updatedFlowsheet.updateComponentPosition(entry.key, entry.value);
      }

      for (final entry in _componentWidths.entries) {
        updatedFlowsheet.updateComponentWidth(entry.key, entry.value);
      }

      _storageService.saveFlowsheet(updatedFlowsheet);
    } catch (e) {
      print('Error saving flowsheet state in dispose: $e');
    }
  }

  @override
  void didUpdateWidget(WiresheetFlowEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.flowsheet.id != widget.flowsheet.id) {
      _saveStateSync();

      _flowManager = FlowManager();
      _commandHistory = CommandHistory();
      _componentPositions.clear();
      _componentKeys.clear();
      _componentWidths.clear();
      _selectedComponents.clear();
      _clipboardComponents.clear();
      _clipboardPositions.clear();
      _clipboardConnections.clear();

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

      _persistenceHelper = PersistenceHelper(
        flowsheet: widget.flowsheet,
        storageService: _storageService,
        flowManager: _flowManager,
        componentPositions: _componentPositions,
        componentWidths: _componentWidths,
        getMountedStatus: () => mounted,
        onFlowsheetUpdate: (updatedFlowsheet) {
          if (mounted) {
            ref.read(flowsheetsProvider.notifier).updateFlowsheet(
                  widget.flowsheet.id,
                  updatedFlowsheet,
                );
          }
        },
      );

      _initializeComponents();
    }
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
      setState(() {
        _canvasSize = newCanvasSize;
      });

      _canvasOffset = newCanvasOffset;
      _updateCanvasSizeAsync(newCanvasSize, newCanvasOffset);
    }
  }

  Future<void> _updateCanvasSizeAsync(
      Size newCanvasSize, Offset newCanvasOffset) async {
    Future.microtask(() async {
      if (!mounted) return;

      await ref.read(flowsheetsProvider.notifier).updateCanvasSize(
            widget.flowsheet.id,
            newCanvasSize,
          );

      await ref.read(flowsheetsProvider.notifier).updateCanvasOffset(
            widget.flowsheet.id,
            newCanvasOffset,
          );

      for (var id in _componentPositions.keys) {
        await _persistenceHelper.saveComponentPosition(
            id, _componentPositions[id]!);
      }
    });
  }

  Future<void> saveFullState() async {
    await _persistenceHelper.saveFullState();
  }

  void _updateButtonPointComponentStatus(ButtonPointStatus status) {
    final matchingComponents = _buttonPointMetadata.entries.where((entry) {
      final metadata = entry.value;
      return metadata['deviceAddress'] == status.deviceAddress &&
          metadata['buttonId'] == status.buttonId;
    }).map((entry) => entry.key);

    for (final componentId in matchingComponents) {
      final component = _flowManager.findComponentById(componentId);
      if (component != null) {
        for (var property in component.properties) {
          if (!property.isInput && property.type.type == PortType.BOOLEAN) {
            if (property.value != status.value) {
              logInfo(
                  'Updating button point component $componentId: ${property.value} -> ${status.value}');

              setState(() {
                property.value = status.value;
                _flowManager.recalculateAll();
              });

              _persistenceHelper.savePortValue(
                  componentId, property.index, status.value);
            }
            break;
          }
        }
      }
    }
  }

  void _initializeButtonPointStatusMonitoring() {
    ref.listen<AsyncValue<ButtonPointStatus>>(
      buttonPointStatusStreamProvider,
      (previous, next) {
        next.whenData((status) {
          _updateButtonPointComponentStatus(status);
        });
      },
    );
  }

  bool _getInitialButtonPointValue(ButtonPoint buttonPoint) {
    if (buttonPoint.function.contains('Status') ||
        buttonPoint.name.toLowerCase().contains('missing')) {
      return false;
    }

    return false;
  }

  final Map<String, Map<String, dynamic>> _buttonPointMetadata = {};

  void _storeButtonPointMetadata(
      String componentId, ButtonPoint buttonPoint, HelvarDevice parentDevice) {
    _buttonPointMetadata[componentId] = {
      'buttonPoint': buttonPoint,
      'parentDevice': parentDevice,
      'deviceAddress': parentDevice.address,
      'buttonId': buttonPoint.buttonId,
      'function': buttonPoint.function,
    };
  }

  void _initializeComponents() {
    for (var component in widget.flowsheet.components) {
      _flowManager.addComponent(component);

      if (widget.flowsheet.componentPositions.containsKey(component.id)) {
        _componentPositions[component.id] =
            widget.flowsheet.componentPositions[component.id]!;
      }

      if (widget.flowsheet.componentWidths.containsKey(component.id)) {
        _componentWidths[component.id] =
            widget.flowsheet.componentWidths[component.id]!;
      } else {
        _componentWidths[component.id] = 160.0; // Default width
      }

      _componentKeys[component.id] = GlobalKey();
    }

    for (var connection in widget.flowsheet.connections) {
      _flowManager.createConnection(
          connection.fromComponentId,
          connection.fromPortIndex,
          connection.toComponentId,
          connection.toPortIndex);
    }

    _flowManager.recalculateAll();
    _updateCanvasSize();
    _commandHistory.clear();
  }

  void _handleComponentResize(String componentId, double newWidth) {
    _flowHandlers.handleComponentResize(componentId, newWidth);
    _componentWidths[componentId] = newWidth;

    _persistenceHelper.saveComponentWidth(componentId, newWidth);
    _updateCanvasSize();
  }

  void _addNewComponent(ComponentType type, {Offset? clickPosition}) {
    String baseName = getNameForComponentType(type);
    int counter = 1;
    String newName = '$baseName $counter';

    while (_flowManager.components.any((comp) => comp.id == newName)) {
      counter++;
      newName = '$baseName $counter';
    }

    Component newComponent =
        _flowManager.createComponentByType(newName, type.type);

    Offset newPosition;
    if (clickPosition != null) {
      newPosition = clickPosition;
    } else {
      final RenderBox? viewerChildRenderBox =
          _interactiveViewerChildKey.currentContext?.findRenderObject()
              as RenderBox?;

      newPosition = Offset(_canvasSize.width / 2, _canvasSize.height / 2);

      if (viewerChildRenderBox != null) {
        final viewportSize = viewerChildRenderBox.size;
        final viewportCenter =
            Offset(viewportSize.width / 2, viewportSize.height / 2);

        final matrix = _transformationController.value;
        final inverseMatrix = Matrix4.inverted(matrix);
        final transformedCenter =
            MatrixUtils.transformPoint(inverseMatrix, viewportCenter);

        final random = Random();
        final randomOffset = Offset(
          (random.nextDouble() * 200) - 100,
          (random.nextDouble() * 200) - 100,
        );

        newPosition = transformedCenter + randomOffset;
      }
    }

    final newKey = GlobalKey();

    Map<String, dynamic> state = {
      'position': newPosition,
      'key': newKey,
      'positions': _componentPositions,
      'keys': _componentKeys,
    };

    setState(() {
      final command = AddComponentCommand(_flowManager, newComponent, state);
      _commandHistory.execute(command);
      _componentWidths[newComponent.id] = 160.0;
      _componentPositions[newComponent.id] = newPosition;
      _componentKeys[newComponent.id] = newKey;

      _persistenceHelper.saveAddComponent(newComponent);
      _persistenceHelper.saveComponentPosition(newComponent.id, newPosition);
      _persistenceHelper.saveComponentWidth(newComponent.id, 160.0);
      _updateCanvasSize();
    });
  }

  void _handleValueChanged(
      String componentId, int slotIndex, dynamic newValue) {
    _flowHandlers.handleValueChanged(componentId, slotIndex, newValue);
    final comp = _flowManager.findComponentById(componentId);
    if (comp != null) {
      _persistenceHelper.savePortValue(componentId, slotIndex, newValue);
      _persistenceHelper.saveUpdateComponent(componentId, comp);
    }
  }

  Offset? getPosition(Offset globalPosition) {
    final RenderBox? canvasBox =
        _canvasKey.currentContext?.findRenderObject() as RenderBox?;

    if (canvasBox != null) {
      final Offset localPosition = canvasBox.globalToLocal(globalPosition);

      final matrix = _transformationController.value;
      final inverseMatrix = Matrix4.inverted(matrix);
      final canvasPosition =
          MatrixUtils.transformPoint(inverseMatrix, localPosition);
      // TODO: use _canvasOffset to update get actual position,
      // there is a bug after scrolling on empty canvas with right-click
      return canvasPosition;
    }
    return null;
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
            final command = CreateConnectionCommand(
              _flowManager,
              _currentDraggedPort!.componentId,
              _currentDraggedPort!.slotIndex,
              targetSlotInfo.componentId,
              targetSlotInfo.slotIndex,
            );
            _commandHistory.execute(command);
            _persistenceHelper.saveAddConnection(Connection(
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _persistenceHelper.saveFullState();
            }
          });
        }
      },
      child: Shortcuts(
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
                      _handleDeleteComponent(component);
                    }
                    _selectedComponents.clear();
                  }
                });
                return null;
              },
            ),
            CopyIntent: CallbackAction<CopyIntent>(
              onInvoke: (CopyIntent intent) {
                if (_selectedComponents.length == 1) {
                  _handleCopyComponent(_selectedComponents.first);
                } else if (_selectedComponents.isNotEmpty) {
                  _handleCopyMultipleComponents();
                }
                return null;
              },
            ),
            MoveDownIntent: CallbackAction<MoveDownIntent>(
              onInvoke: (MoveDownIntent intent) {
                if (_selectedComponents.isNotEmpty) {
                  for (var component in _selectedComponents) {
                    _handleMoveComponentDown(component);
                  }
                }
                return null;
              },
            ),
            MoveLeftIntent: CallbackAction<MoveLeftIntent>(
              onInvoke: (MoveLeftIntent intent) {
                if (_selectedComponents.isNotEmpty) {
                  for (var component in _selectedComponents) {
                    _handleMoveComponentLeft(component);
                  }
                }
                return null;
              },
            ),
            MoveRightIntent: CallbackAction<MoveRightIntent>(
              onInvoke: (MoveRightIntent intent) {
                if (_selectedComponents.isNotEmpty) {
                  for (var component in _selectedComponents) {
                    _handleMoveComponentRight(component);
                  }
                }
                return null;
              },
            ),
            MoveUpIntent: CallbackAction<MoveUpIntent>(
              onInvoke: (MoveUpIntent intent) {
                if (_selectedComponents.isNotEmpty) {
                  for (var component in _selectedComponents) {
                    _handleMoveComponentUp(component);
                  }
                }
                return null;
              },
            ),
            PasteIntent: CallbackAction<PasteIntent>(
              onInvoke: (PasteIntent intent) {
                if (_clipboardComponents.isNotEmpty) {
                  if (_clipboardComponentPosition != null) {
                    const double offsetAmount = 30.0;
                    final Offset pastePosition = _clipboardComponentPosition! +
                        const Offset(offsetAmount, offsetAmount);

                    _handlePasteComponent(pastePosition);
                  } else {
                    final RenderBox? viewerChildRenderBox =
                        _interactiveViewerChildKey.currentContext
                            ?.findRenderObject() as RenderBox?;

                    if (viewerChildRenderBox != null) {
                      final viewportSize = viewerChildRenderBox.size;
                      final viewportCenter = Offset(
                          viewportSize.width / 2, viewportSize.height / 2);

                      final matrix = _transformationController.value;
                      final inverseMatrix = Matrix4.inverted(matrix);
                      final canvasPosition = MatrixUtils.transformPoint(
                          inverseMatrix, viewportCenter);

                      _handlePasteComponent(canvasPosition);
                    }
                  }
                }
                return null;
              },
            ),
          },
          child: Focus(
            autofocus: true,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Visual Flow Editor'),
                actions: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Center(
                      child: Text(
                        'Canvas: ${_canvasSize.width.toInt()} × ${_canvasSize.height.toInt()}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
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
                            });
                          }
                        : null, // Disable button if cannot undo
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
                            });
                          }
                        : null, // Disable button if cannot redo
                  ),
                ],
              ),
              body: ClipRect(
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  boundaryMargin: const EdgeInsets.all(1000),
                  minScale: 0.1,
                  constrained: false,
                  maxScale: 3.0,
                  panEnabled: true,
                  scaleEnabled: true,
                  child: CustomPaint(
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
                      onPanStart: (details) {
                        Offset? canvasPosition =
                            getPosition(details.globalPosition);
                        if (canvasPosition != null) {
                          bool isClickOnComponent = false;

                          for (final componentId in _componentPositions.keys) {
                            final componentPos =
                                _componentPositions[componentId]!;
                            const double componentWidth = 180.0;
                            const double componentHeight = 150.0;

                            final componentRect = Rect.fromLTWH(
                              componentPos.dx,
                              componentPos.dy,
                              componentWidth,
                              componentHeight,
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
                      },
                      onPanUpdate: (details) {
                        if (_isDraggingSelectionBox) {
                          Offset? canvasPosition =
                              getPosition(details.globalPosition);
                          if (canvasPosition != null) {
                            setState(() {
                              _selectionBoxEnd = canvasPosition;
                            });
                          }
                        }
                      },
                      onPanEnd: (details) {
                        if (_isDraggingSelectionBox &&
                            _selectionBoxStart != null &&
                            _selectionBoxEnd != null) {
                          final selectionRect = Rect.fromPoints(
                              _selectionBoxStart!, _selectionBoxEnd!);

                          setState(() {
                            if (!HardwareKeyboard.instance.isControlPressed) {
                              _selectedComponents.clear();
                            }

                            for (final component in _flowManager.components) {
                              final componentPos =
                                  _componentPositions[component.id];
                              if (componentPos != null) {
                                const double componentWidth = 180.0;
                                const double componentHeight = 150.0;

                                final componentRect = Rect.fromLTWH(
                                  componentPos.dx,
                                  componentPos.dy,
                                  componentWidth,
                                  componentHeight,
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
                      },
                      onDoubleTapDown: (TapDownDetails details) {
                        Offset? canvasPosition =
                            getPosition(details.globalPosition);
                        if (canvasPosition != null) {
                          bool isClickOnComponent = false;

                          for (final componentId in _componentPositions.keys) {
                            final componentPos =
                                _componentPositions[componentId]!;

                            const double componentWidth = 180.0;
                            const double componentHeight = 150.0;

                            final componentRect = Rect.fromLTWH(
                              componentPos.dx,
                              componentPos.dy,
                              componentWidth,
                              componentHeight,
                            );

                            if (componentRect.contains(canvasPosition)) {
                              isClickOnComponent = true;
                              break;
                            }
                          }

                          if (!isClickOnComponent) {
                            _showCanvasContextMenu(
                                context, details.globalPosition);
                          }
                        }
                      },
                      child: DragTarget<Object>(
                        onAcceptWithDetails:
                            (DragTargetDetails<dynamic> details) {
                          final RenderBox? canvasBox = _canvasKey.currentContext
                              ?.findRenderObject() as RenderBox?;

                          if (canvasBox != null) {
                            final Offset localPosition =
                                canvasBox.globalToLocal(details.offset);
                            print("localPosition: $localPosition");

                            final matrix = _transformationController.value;
                            final inverseMatrix = Matrix4.inverted(matrix);
                            final canvasPosition = MatrixUtils.transformPoint(
                                inverseMatrix, localPosition);
                            print("canvasPosition: $canvasPosition");

                            if (details.data is ComponentType) {
                              _addNewComponent(details.data,
                                  clickPosition: canvasPosition);
                            } else if (details.data is Map<String, dynamic>) {
                              Map<String, dynamic> dragData = details.data;

                              if (dragData.containsKey("buttonPoint") &&
                                  dragData.containsKey("pointData")) {
                                _addNewButtonPointComponent(dragData,
                                    clickPosition: canvasPosition);
                              } else if (dragData.containsKey("device")) {
                                _addNewDeviceComponent(dragData,
                                    clickPosition: canvasPosition);
                              }
                            }
                          }
                        },
                        builder: (context, candidateData, rejectedData) {
                          return Container(
                            key: _canvasKey,
                            width: _canvasSize.width,
                            height: _canvasSize.height,
                            color: Colors.grey[50],
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                CustomPaint(
                                  painter: GridPainter(),
                                  size: _canvasSize,
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
                                if (_flowManager.components.isEmpty)
                                  const Center(
                                    child: Text(
                                      'Add components to the canvas',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ..._flowManager.components.map(
                                  (component) {
                                    return Positioned(
                                      left: _componentPositions[component.id]
                                              ?.dx ??
                                          0,
                                      top: _componentPositions[component.id]
                                              ?.dy ??
                                          0,
                                      child: Draggable<String>(
                                        data: component.id,
                                        feedback: Material(
                                          elevation: 5.0,
                                          color: Colors.transparent,
                                          child: ComponentWidget(
                                            component: component,
                                            height: component.allSlots.length *
                                                rowHeight,
                                            isSelected: _selectedComponents
                                                .contains(component),
                                            widgetKey:
                                                _componentKeys[component.id] ??
                                                    GlobalKey(),
                                            position: _componentPositions[
                                                    component.id] ??
                                                Offset.zero,
                                            width: _componentWidths[
                                                    component.id] ??
                                                160.0,
                                            onValueChanged: _handleValueChanged,
                                            onSlotDragStarted:
                                                _handlePortDragStarted,
                                            onSlotDragAccepted:
                                                _handlePortDragAccepted,
                                            onWidthChanged:
                                                _handleComponentResize,
                                          ),
                                        ),
                                        childWhenDragging: Opacity(
                                          opacity: 0.3,
                                          child: ComponentWidget(
                                            component: component,
                                            height: component.allSlots.length *
                                                rowHeight,
                                            isSelected: _selectedComponents
                                                .contains(component),
                                            widgetKey: GlobalKey(),
                                            position: _componentPositions[
                                                    component.id] ??
                                                Offset.zero,
                                            width: _componentWidths[
                                                    component.id] ??
                                                160.0,
                                            onValueChanged: _handleValueChanged,
                                            onSlotDragStarted:
                                                _handlePortDragStarted,
                                            onSlotDragAccepted:
                                                _handlePortDragAccepted,
                                            onWidthChanged:
                                                _handleComponentResize,
                                          ),
                                        ),
                                        onDragStarted: () {
                                          _dragStartPosition =
                                              _componentPositions[component.id];
                                        },
                                        onDragEnd: (details) {
                                          final RenderBox?
                                              viewerChildRenderBox =
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
                                                            selectedComponent
                                                                .id];
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
                                                      _persistenceHelper
                                                          .saveComponentPosition(
                                                              selectedComponent
                                                                  .id,
                                                              newPos);
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
                                                  _persistenceHelper
                                                      .saveComponentPosition(
                                                          component.id,
                                                          localOffset);
                                                  _selectedComponents.clear();
                                                  _selectedComponents
                                                      .add(component);
                                                }

                                                _dragStartPosition = null;

                                                _updateCanvasSize();
                                              });
                                            }
                                          }
                                        },
                                        child: GestureDetector(
                                          onSecondaryTapDown: (details) {
                                            _showContextMenu(
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
                                            height: component.allSlots.length *
                                                rowHeight,
                                            width: _componentWidths[
                                                    component.id] ??
                                                160.0,
                                            onWidthChanged:
                                                _handleComponentResize,
                                            isSelected: _selectedComponents
                                                .contains(component),
                                            widgetKey:
                                                _componentKeys[component.id] ??
                                                    GlobalKey(),
                                            position: _componentPositions[
                                                    component.id] ??
                                                Offset.zero,
                                            onValueChanged: _handleValueChanged,
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
                          );
                        },
                      ),
                    ),
                  ),
                ),
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
        ),
      ),
    );
  }

  void _showCanvasContextMenu(BuildContext context, Offset globalPosition) {
    Offset canvasPosition = getPosition(globalPosition)!;

    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(globalPosition, globalPosition),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          value: 'paste',
          enabled: _clipboardComponents.isNotEmpty,
          child: Row(
            children: [
              Icon(Icons.content_paste,
                  size: 18,
                  color: _clipboardComponents.isNotEmpty ? null : Colors.grey),
              const SizedBox(width: 8),
              Text(
                'Paste',
                style: TextStyle(
                    color:
                        _clipboardComponents.isNotEmpty ? null : Colors.grey),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'paste-special',
          enabled: _clipboardComponents.isNotEmpty,
          child: Row(
            children: [
              Icon(Icons.copy_all,
                  size: 18,
                  color: _clipboardComponents.isNotEmpty ? null : Colors.grey),
              const SizedBox(width: 8),
              Text(
                'Paste Special...',
                style: TextStyle(
                    color:
                        _clipboardComponents.isNotEmpty ? null : Colors.grey),
              ),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'add-component',
          child: Row(
            children: [
              Icon(Icons.add_box, size: 18),
              SizedBox(width: 8),
              Text('Add New Component...'),
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
          _showAddComponentDialogAtPosition(canvasPosition);
          break;
        case 'paste':
          _handlePasteComponent(canvasPosition);
          break;
        case 'paste-special':
          _showPasteSpecialDialog(canvasPosition);
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

  void _showPasteSpecialDialog(Offset pastePosition) {
    if (_clipboardComponents.isEmpty) return;

    TextEditingController copiesController = TextEditingController(text: '1');
    bool keepConnections = true;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Paste Special'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text('Number of copies:'),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 50,
                    child: TextField(
                      controller: copiesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              StatefulBuilder(
                builder: (context, setState) {
                  return CheckboxListTile(
                    title: const Text('Keep connections between copies'),
                    value: keepConnections,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (value) {
                      setState(() {
                        keepConnections = value ?? true;
                      });
                    },
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                int copies = int.tryParse(copiesController.text) ?? 1;
                copies = copies.clamp(1, 20); // Limit to reasonable number

                _flowHandlers.handlePasteSpecialComponent(
                    pastePosition, copies, keepConnections);
              },
              child: const Text('Paste'),
            ),
          ],
        );
      },
    );
  }

  void _handlePasteComponent(Offset position) {
    _flowHandlers.handlePasteComponent(position);
  }

  void _showAddComponentDialogAtPosition(Offset position) {
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
                    'Custom Components',
                    [
                      RectangleComponent.RECTANGLE,
                      RampComponent.RAMP,
                    ],
                    position),
                _buildComponentCategorySection(
                    'Logic Gates',
                    [
                      ComponentType.AND_GATE,
                      ComponentType.OR_GATE,
                      ComponentType.XOR_GATE,
                      ComponentType.NOT_GATE,
                    ],
                    position),
                _buildComponentCategorySection(
                    'Math Operations',
                    [
                      ComponentType.ADD,
                      ComponentType.SUBTRACT,
                      ComponentType.MULTIPLY,
                      ComponentType.DIVIDE,
                      ComponentType.MAX,
                      ComponentType.MIN,
                      ComponentType.POWER,
                      ComponentType.ABS,
                    ],
                    position),
                _buildComponentCategorySection(
                    'Comparisons',
                    [
                      ComponentType.IS_GREATER_THAN,
                      ComponentType.IS_LESS_THAN,
                      ComponentType.IS_EQUAL,
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

  Widget _buildComponentCategorySection(
      String title, List<String> typeStrings, Offset position) {
    List<ComponentType> types =
        typeStrings.map((t) => ComponentType(t)).toList();

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
          children: types.map((type) {
            return InkWell(
              onTap: () {
                _addNewComponent(type, clickPosition: position);
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
                    Icon(getIconForComponentType(type)),
                    const SizedBox(height: 4.0),
                    Text(getNameForComponentType(type)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showContextMenu(
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
            _handleCopyComponent(_selectedComponents.first);
          } else if (_selectedComponents.isNotEmpty) {
            _handleCopyMultipleComponents();
          }
          break;
        case 'edit':
          _handleEditComponent(context, component);
          break;
        case 'delete':
          _handleDeleteComponent(component);
          break;
      }
    });
  }

  void _handleEditComponent(BuildContext context, Component component) {
    _flowHandlers.handleEditComponent(context, component);
  }

  void _handleDeleteComponent(Component component) {
    final componentId = component.id;

    final List<Connection> connectionsToDelete = [];
    for (final comp in _flowManager.components) {
      for (final entry in comp.inputConnections.entries) {
        if (entry.value.componentId == componentId) {
          connectionsToDelete.add(Connection(
            fromComponentId: entry.value.componentId,
            fromPortIndex: entry.value.portIndex,
            toComponentId: comp.id,
            toPortIndex: entry.key,
          ));
        }
      }
    }

    for (final entry in component.inputConnections.entries) {
      connectionsToDelete.add(Connection(
        fromComponentId: entry.value.componentId,
        fromPortIndex: entry.value.portIndex,
        toComponentId: componentId,
        toPortIndex: entry.key,
      ));
    }

    _flowHandlers.handleDeleteComponent(component);

    _persistenceHelper.saveRemoveComponent(componentId);

    for (final connection in connectionsToDelete) {
      _persistenceHelper.saveRemoveConnection(
          connection.fromComponentId,
          connection.fromPortIndex,
          connection.toComponentId,
          connection.toPortIndex);
    }

    if (_selectedComponents.contains(component)) {
      setState(() {
        _selectedComponents.remove(component);
      });
    }
  }

  void _addNewButtonPointComponent(Map<String, dynamic> buttonPointData,
      {Offset? clickPosition}) {
    final ButtonPoint buttonPoint =
        buttonPointData["buttonPoint"] as ButtonPoint;
    final HelvarDevice parentDevice =
        buttonPointData["parentDevice"] as HelvarDevice;
    final Map<String, dynamic> pointData =
        buttonPointData["pointData"] as Map<String, dynamic>;

    String baseName = buttonPoint.name;
    String componentId = baseName;
    int counter = 1;

    while (_flowManager.components.any((comp) => comp.id == componentId)) {
      componentId = "${baseName}_$counter";
      counter++;
    }

    Component newComponent = _flowManager.createComponentByType(
        componentId, ComponentType.BOOLEAN_POINT);

    bool initialValue = _getInitialButtonPointValue(buttonPoint);

    for (var property in newComponent.properties) {
      if (!property.isInput && property.type.type == PortType.BOOLEAN) {
        property.value = initialValue;
        break;
      }
    }

    _storeButtonPointMetadata(componentId, buttonPoint, parentDevice);

    Offset newPosition = clickPosition ?? _getDefaultPosition();
    final newKey = GlobalKey();

    Map<String, dynamic> state = {
      'position': newPosition,
      'key': newKey,
      'positions': _componentPositions,
      'keys': _componentKeys,
    };

    setState(() {
      final command = AddComponentCommand(_flowManager, newComponent, state);
      _commandHistory.execute(command);
      _componentWidths[newComponent.id] = 160.0;
      _componentPositions[newComponent.id] = newPosition;
      _componentKeys[newComponent.id] = newKey;

      _persistenceHelper.saveAddComponent(newComponent);
      _persistenceHelper.saveComponentPosition(newComponent.id, newPosition);
      _persistenceHelper.saveComponentWidth(newComponent.id, 160.0);

      _updateCanvasSize();
    });

    _startButtonPointMonitoring(parentDevice, buttonPoint);
  }

  void _startButtonPointMonitoring(
      HelvarDevice parentDevice, ButtonPoint buttonPoint) {
    final workgroups = ref.read(workgroupsProvider);
    String? routerIpAddress;

    for (final workgroup in workgroups) {
      for (final router in workgroup.routers) {
        if (router.devices.any((d) => d.address == parentDevice.address)) {
          routerIpAddress = router.ipAddress;
          break;
        }
      }
      if (routerIpAddress != null) break;
    }

    if (routerIpAddress != null && routerIpAddress.isNotEmpty) {
      logInfo(
          'Starting button point monitoring for ${parentDevice.address} on router $routerIpAddress');
      ref
          .read(buttonPointMonitoringProvider.notifier)
          .startMonitoring(parentDevice.address, routerIpAddress, parentDevice);
    } else {
      logWarning('Could not find router IP for device ${parentDevice.address}');
    }
  }

  Offset _getDefaultPosition() {
    final RenderBox? viewerChildRenderBox =
        _interactiveViewerChildKey.currentContext?.findRenderObject()
            as RenderBox?;

    if (viewerChildRenderBox != null) {
      final viewportSize = viewerChildRenderBox.size;
      final viewportCenter =
          Offset(viewportSize.width / 2, viewportSize.height / 2);

      final matrix = _transformationController.value;
      final inverseMatrix = Matrix4.inverted(matrix);
      final transformedCenter =
          MatrixUtils.transformPoint(inverseMatrix, viewportCenter);

      return transformedCenter;
    }

    return Offset(_canvasSize.width / 2, _canvasSize.height / 2);
  }

  void _handleCopyComponent(Component component) {
    _flowHandlers.handleCopyComponent(component);
  }

  void _handleCopyMultipleComponents() {
    _flowHandlers.handleCopyMultipleComponents();
  }

  void _handleMoveComponentDown(Component component) {
    _flowHandlers.handleMoveComponentDown(component);
  }

  void _handleMoveComponentUp(Component component) {
    _flowHandlers.handleMoveComponentUp(component);
  }

  void _handleMoveComponentLeft(Component component) {
    _flowHandlers.handleMoveComponentLeft(component);
  }

  void _handleMoveComponentRight(Component component) {
    _flowHandlers.handleMoveComponentRight(component);
  }

  void _addNewDeviceComponent(Map<String, dynamic> deviceData,
      {Offset? clickPosition}) {
    HelvarDevice? device = deviceData["device"] as HelvarDevice?;

    if (device == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid device data')),
      );
      return;
    }

    String deviceName = device.description.isEmpty
        ? "Device_${device.deviceId}"
        : device.description;

    int counter = 1;
    String componentId = deviceName;
    while (_flowManager.components.any((comp) => comp.id == componentId)) {
      counter++;
      componentId = "${deviceName}_$counter";
    }

    Component newComponent = _createComponentFromDevice(componentId, device);

    Offset newPosition;
    if (clickPosition != null) {
      newPosition = clickPosition;
    } else {
      final RenderBox? viewerChildRenderBox =
          _interactiveViewerChildKey.currentContext?.findRenderObject()
              as RenderBox?;

      newPosition = Offset(_canvasSize.width / 2, _canvasSize.height / 2);

      if (viewerChildRenderBox != null) {
        final viewportSize = viewerChildRenderBox.size;
        final viewportCenter =
            Offset(viewportSize.width / 2, viewportSize.height / 2);
        final matrix = _transformationController.value;
        final inverseMatrix = Matrix4.inverted(matrix);
        final transformedCenter =
            MatrixUtils.transformPoint(inverseMatrix, viewportCenter);

        newPosition = transformedCenter;
      }
    }

    final newKey = GlobalKey();

    Map<String, dynamic> state = {
      'position': newPosition,
      'key': newKey,
      'positions': _componentPositions,
      'keys': _componentKeys,
    };

    setState(() {
      final command = AddComponentCommand(_flowManager, newComponent, state);
      _commandHistory.execute(command);
      _componentWidths[newComponent.id] = 180.0;
      _componentPositions[newComponent.id] = newPosition;
      _componentKeys[newComponent.id] = newKey;

      _persistenceHelper.saveAddComponent(newComponent);
      _persistenceHelper.saveComponentPosition(newComponent.id, newPosition);
      _persistenceHelper.saveComponentWidth(newComponent.id, 180.0);

      _updateCanvasSize();
    });
  }

  Component _createComponentFromDevice(String id, HelvarDevice device) {
    return HelvarDeviceComponent(
      id: id,
      deviceId: device.deviceId,
      deviceAddress: device.address,
      deviceType: device.helvarType,
      description: device.description.isEmpty
          ? "Device_${device.deviceId}"
          : device.description,
      type: ComponentType(getHelvarComponentType(device.helvarType)),
    );
  }

  String getHelvarComponentType(String helvarType) {
    switch (helvarType) {
      case 'output':
        return ComponentType.HELVAR_OUTPUT;
      case 'input':
        return ComponentType.HELVAR_INPUT;
      case 'emergency':
        return ComponentType.HELVAR_EMERGENCY;
      default:
        return ComponentType.HELVAR_DEVICE;
    }
  }
}
