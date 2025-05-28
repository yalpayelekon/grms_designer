import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grms_designer/models/flowsheet.dart';
import 'package:grms_designer/providers/flowsheet_provider.dart';
import 'package:grms_designer/utils/canvas_utils.dart';
import 'package:grms_designer/utils/device_utils.dart';
import 'package:grms_designer/utils/logger.dart';

import '../models/helvar_models/helvar_device.dart';
import '../models/helvar_models/input_device.dart';
import '../niagara/controllers/flow_editor_state.dart';
import '../niagara/controllers/clipboard_manager.dart';
import '../niagara/controllers/drag_operation_manager.dart';
import '../niagara/controllers/canvas_interaction_controller.dart';
import '../niagara/controllers/selection_manager.dart';
import '../niagara/home/command.dart';
import '../niagara/home/handlers.dart';
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
import '../niagara/models/port_type.dart';
import '../niagara/models/ramp_component.dart';
import '../niagara/models/rectangle.dart';
import '../services/flowsheet_storage_service.dart';
import '../utils/general_ui.dart';
import '../utils/persistent_helper.dart';

class WiresheetFlowEditor extends ConsumerStatefulWidget {
  final Flowsheet flowsheet;

  const WiresheetFlowEditor({super.key, required this.flowsheet});

  @override
  WiresheetFlowEditorState createState() => WiresheetFlowEditorState();
}

class WiresheetFlowEditorState extends ConsumerState<WiresheetFlowEditor> {
  late FlowEditorState _editorState;
  late ClipboardManager _clipboardManager;
  late PersistenceHelper _persistenceHelper;
  late FlowsheetStorageService _storageService;
  late SelectionManager _selectionManager;
  late FlowHandlers _flowHandlers;
  late DragOperationManager _dragManager;
  late CanvasInteractionController _canvasController;

  final Map<String, Map<String, dynamic>> _buttonPointMetadata = {};

  final TransformationController _transformationController =
      TransformationController();
  final Size _canvasSize = const Size(2000, 2000);

  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  void _initializeState() {
    _transformationController.value = Matrix4.identity();
    _canvasController = CanvasInteractionController();
    final flowManager = FlowManager();
    final commandHistory = CommandHistory();
    _editorState = FlowEditorState(
      flowManager: flowManager,
      commandHistory: commandHistory,
    );

    _selectionManager = SelectionManager();
    _selectionManager.setOnSelectionChanged(_onSelectionChanged);

    _clipboardManager = ClipboardManager();
    _dragManager = DragOperationManager();
    _storageService = ref.read(flowsheetStorageServiceProvider);

    _flowHandlers = FlowHandlers(
      flowManager: _editorState.flowManager,
      commandHistory: _editorState.commandHistory,
      componentPositions: _editorState.componentPositions,
      componentKeys: _editorState.componentKeys,
      componentWidths: _editorState.componentWidths,
      setState: setState,
      updateCanvasSize: _updateCanvasSize,
      selectedComponents: _selectionManager.selectedComponents,
      clipboardComponents: _clipboardManager.clipboardComponents,
      clipboardPositions: _clipboardManager.clipboardPositions,
      clipboardConnections: _clipboardManager.clipboardConnections,
      setClipboardComponentPosition: (position) {
        _clipboardManager.setClipboardReferencePosition(position);
      },
    );

    _persistenceHelper = PersistenceHelper(
      flowsheet: widget.flowsheet,
      storageService: _storageService,
      flowManager: _editorState.flowManager,
      componentPositions: _editorState.componentPositions,
      componentWidths: _editorState.componentWidths,
      getMountedStatus: () => mounted,
      onFlowsheetUpdate: (updatedFlowsheet) {
        if (mounted) {
          ref
              .read(flowsheetsProvider.notifier)
              .updateFlowsheet(widget.flowsheet.id, updatedFlowsheet);
        }
      },
    );

    _initializeComponents();
  }

  void _onSelectionChanged(Set<Component> selectedComponents) {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _saveStateSync();
    super.dispose();
  }

  void _saveStateSync() {
    try {
      final updatedFlowsheet = widget.flowsheet.copy();
      updatedFlowsheet.components = _editorState.flowManager.components;

      final List<Connection> connections = [];
      for (final component in _editorState.flowManager.components) {
        for (final entry in component.inputConnections.entries) {
          connections.add(
            Connection(
              fromComponentId: entry.value.componentId,
              fromPortIndex: entry.value.portIndex,
              toComponentId: component.id,
              toPortIndex: entry.key,
            ),
          );
        }
      }
      updatedFlowsheet.connections = connections;

      for (final entry in _editorState.componentPositions.entries) {
        updatedFlowsheet.updateComponentPosition(entry.key, entry.value);
      }

      for (final entry in _editorState.componentWidths.entries) {
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

      _editorState.clear();
      _selectionManager.clearSelection();
      _clipboardManager.clear();

      _flowHandlers = FlowHandlers(
        flowManager: _editorState.flowManager,
        commandHistory: _editorState.commandHistory,
        componentPositions: _editorState.componentPositions,
        componentKeys: _editorState.componentKeys,
        componentWidths: _editorState.componentWidths,
        setState: setState,
        updateCanvasSize: _updateCanvasSize,
        selectedComponents: _selectionManager.selectedComponents,
        clipboardComponents: _clipboardManager.clipboardComponents,
        clipboardPositions: _clipboardManager.clipboardPositions,
        clipboardConnections: _clipboardManager.clipboardConnections,
        setClipboardComponentPosition: (position) {
          _clipboardManager.setClipboardReferencePosition(position);
        },
      );

      _persistenceHelper = PersistenceHelper(
        flowsheet: widget.flowsheet,
        storageService: _storageService,
        flowManager: _editorState.flowManager,
        componentPositions: _editorState.componentPositions,
        componentWidths: _editorState.componentWidths,
        getMountedStatus: () => mounted,
        onFlowsheetUpdate: (updatedFlowsheet) {
          if (mounted) {
            ref
                .read(flowsheetsProvider.notifier)
                .updateFlowsheet(widget.flowsheet.id, updatedFlowsheet);
          }
        },
      );

      _initializeComponents();
    }
  }

  void _updateCanvasSize() {
    if (_canvasController.updateCanvasSize(
      _editorState.componentPositions,
      _editorState.componentWidths,
    )) {
      setState(() {});
      _updateCanvasSizeAsync();
    }
  }

  Future<void> _updateCanvasSizeAsync() async {
    Future.microtask(() async {
      if (!mounted) return;

      await ref
          .read(flowsheetsProvider.notifier)
          .updateCanvasSize(widget.flowsheet.id, _canvasController.canvasSize);

      await ref
          .read(flowsheetsProvider.notifier)
          .updateCanvasOffset(
            widget.flowsheet.id,
            _canvasController.canvasOffset,
          );

      for (var id in _editorState.componentPositions.keys) {
        await _persistenceHelper.saveComponentPosition(
          id,
          _editorState.getComponentPosition(id),
        );
      }
    });
  }

  Future<void> saveFullState() async {
    await _persistenceHelper.saveFullState();
  }

  void _initializeComponents() {
    for (var component in widget.flowsheet.components) {
      _editorState.flowManager.addComponent(component);

      Offset position = Offset.zero;
      if (widget.flowsheet.componentPositions.containsKey(component.id)) {
        position = widget.flowsheet.componentPositions[component.id]!;
      }

      double width = 160.0;
      if (widget.flowsheet.componentWidths.containsKey(component.id)) {
        width = widget.flowsheet.componentWidths[component.id]!;
      }

      _editorState.initializeComponentState(
        component,
        position: position,
        width: width,
      );
    }

    for (var connection in widget.flowsheet.connections) {
      _editorState.flowManager.createConnection(
        connection.fromComponentId,
        connection.fromPortIndex,
        connection.toComponentId,
        connection.toPortIndex,
      );
    }

    _editorState.flowManager.recalculateAll();
    _updateCanvasSize();
    _editorState.commandHistory.clear();
  }

  void _handleComponentResize(String componentId, double newWidth) {
    _flowHandlers.handleComponentResize(componentId, newWidth);
    _editorState.setComponentWidth(componentId, newWidth);

    _persistenceHelper.saveComponentWidth(componentId, newWidth);
    _updateCanvasSize();
  }

  void _addNewComponent(ComponentType type, {Offset? clickPosition}) {
    String baseName = getNameForComponentType(type);
    int counter = 1;
    String newName = '$baseName $counter';

    while (_editorState.flowManager.components.any(
      (comp) => comp.id == newName,
    )) {
      counter++;
      newName = '$baseName $counter';
    }

    Component newComponent = _editorState.flowManager.createComponentByType(
      newName,
      type.type,
    );

    Offset newPosition =
        clickPosition ?? getDefaultPosition(_canvasController, _editorState);

    Map<String, dynamic> state = {
      'position': newPosition,
      'key': _editorState.getComponentKey(newComponent.id),
      'positions': _editorState.componentPositions,
      'keys': _editorState.componentKeys,
    };

    setState(() {
      final command = AddComponentCommand(
        _editorState.flowManager,
        newComponent,
        state,
      );
      _editorState.commandHistory.execute(command);

      _editorState.initializeComponentState(
        newComponent,
        position: newPosition,
        width: 160.0,
      );
      _persistenceHelper.saveAddComponent(newComponent);
      _persistenceHelper.saveComponentPosition(newComponent.id, newPosition);
      _persistenceHelper.saveComponentWidth(newComponent.id, 160.0);
      _updateCanvasSize();
    });
  }

  void _handleValueChanged(
    String componentId,
    int slotIndex,
    dynamic newValue,
  ) {
    _flowHandlers.handleValueChanged(componentId, slotIndex, newValue);
    final comp = _editorState.flowManager.findComponentById(componentId);
    if (comp != null) {
      _persistenceHelper.savePortValue(componentId, slotIndex, newValue);
      _persistenceHelper.saveUpdateComponent(componentId, comp);
    }
  }

  void _handlePortDragStarted(SlotDragInfo slotInfo) {
    setState(() {
      _dragManager.startPortDrag(slotInfo);
    });
  }

  void _handlePortDragAccepted(SlotDragInfo targetSlotInfo) {
    if (_dragManager.currentDraggedPort != null) {
      Component? sourceComponent = _editorState.flowManager.findComponentById(
        _dragManager.currentDraggedPort!.componentId,
      );
      Component? targetComponent = _editorState.flowManager.findComponentById(
        targetSlotInfo.componentId,
      );

      if (sourceComponent != null && targetComponent != null) {
        if (_editorState.flowManager.canCreateConnection(
          _dragManager.currentDraggedPort!.componentId,
          _dragManager.currentDraggedPort!.slotIndex,
          targetSlotInfo.componentId,
          targetSlotInfo.slotIndex,
        )) {
          setState(() {
            final command = CreateConnectionCommand(
              _editorState.flowManager,
              _dragManager.currentDraggedPort!.componentId,
              _dragManager.currentDraggedPort!.slotIndex,
              targetSlotInfo.componentId,
              targetSlotInfo.slotIndex,
            );
            _editorState.commandHistory.execute(command);
            _persistenceHelper.saveAddConnection(
              Connection(
                fromComponentId: _dragManager.currentDraggedPort!.componentId,
                fromPortIndex: _dragManager.currentDraggedPort!.slotIndex,
                toComponentId: targetSlotInfo.componentId,
                toPortIndex: targetSlotInfo.slotIndex,
              ),
            );
          });
        } else {
          logWarning(
            'Cannot connect these slots - type mismatch or invalid connection',
          );
        }
      }
    }

    setState(() {
      _dragManager.endPortDrag();
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
                if (_editorState.commandHistory.canUndo) {
                  setState(() {
                    _editorState.commandHistory.undo();
                  });
                }
                return null;
              },
            ),
            RedoIntent: CallbackAction<RedoIntent>(
              onInvoke: (RedoIntent intent) {
                if (_editorState.commandHistory.canRedo) {
                  setState(() {
                    _editorState.commandHistory.redo();
                  });
                }
                return null;
              },
            ),
            SelectAllIntent: CallbackAction<SelectAllIntent>(
              onInvoke: (SelectAllIntent intent) {
                _selectionManager.selectAll(
                  _editorState.flowManager.components,
                );
                return null;
              },
            ),
            DeleteIntent: CallbackAction<DeleteIntent>(
              onInvoke: (DeleteIntent intent) {
                if (_selectionManager.selectedComponents.isNotEmpty) {
                  setState(() {
                    for (var component
                        in _selectionManager.selectedComponents.toList()) {
                      _handleDeleteComponent(component);
                    }
                    _selectionManager.clearSelection();
                  });
                }
                return null;
              },
            ),
            CopyIntent: CallbackAction<CopyIntent>(
              onInvoke: (CopyIntent intent) {
                if (_selectionManager.selectedComponents.length == 1) {
                  _handleCopyComponent(
                    _selectionManager.selectedComponents.first,
                  );
                } else if (_selectionManager.selectedComponents.isNotEmpty) {
                  _handleCopyMultipleComponents();
                }
                return null;
              },
            ),
            MoveDownIntent: CallbackAction<MoveDownIntent>(
              onInvoke: (MoveDownIntent intent) {
                if (_selectionManager.selectedComponents.isNotEmpty) {
                  for (var component in _selectionManager.selectedComponents) {
                    _handleMoveComponentDown(component);
                  }
                }
                return null;
              },
            ),
            MoveLeftIntent: CallbackAction<MoveLeftIntent>(
              onInvoke: (MoveLeftIntent intent) {
                if (_selectionManager.selectedComponents.isNotEmpty) {
                  for (var component in _selectionManager.selectedComponents) {
                    _handleMoveComponentLeft(component);
                  }
                }
                return null;
              },
            ),
            MoveRightIntent: CallbackAction<MoveRightIntent>(
              onInvoke: (MoveRightIntent intent) {
                if (_selectionManager.selectedComponents.isNotEmpty) {
                  for (var component in _selectionManager.selectedComponents) {
                    _handleMoveComponentRight(component);
                  }
                }
                return null;
              },
            ),
            MoveUpIntent: CallbackAction<MoveUpIntent>(
              onInvoke: (MoveUpIntent intent) {
                if (_selectionManager.selectedComponents.isNotEmpty) {
                  for (var component in _selectionManager.selectedComponents) {
                    _handleMoveComponentUp(component);
                  }
                }
                return null;
              },
            ),
            PasteIntent: CallbackAction<PasteIntent>(
              onInvoke: (PasteIntent intent) {
                if (!_clipboardManager.isEmpty) {
                  if (_clipboardManager.clipboardReferencePosition != null) {
                    const double offsetAmount = 30.0;
                    final Offset pastePosition =
                        _clipboardManager.clipboardReferencePosition! +
                        const Offset(offsetAmount, offsetAmount);

                    _handlePasteComponent(pastePosition);
                  } else {
                    final RenderBox? viewerChildRenderBox =
                        _editorState.interactiveViewerChildKey.currentContext
                                ?.findRenderObject()
                            as RenderBox?;

                    if (viewerChildRenderBox != null) {
                      final viewportSize = viewerChildRenderBox.size;
                      final viewportCenter = Offset(
                        viewportSize.width / 2,
                        viewportSize.height / 2,
                      );

                      final matrix = _transformationController.value;
                      final inverseMatrix = Matrix4.inverted(matrix);
                      final canvasPosition = MatrixUtils.transformPoint(
                        inverseMatrix,
                        viewportCenter,
                      );

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
                        'Canvas: ${_canvasController.canvasSize.width.toInt()} × ${_canvasController.canvasSize.height.toInt()}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.undo),
                    tooltip: _editorState.commandHistory.canUndo
                        ? 'Undo: ${_editorState.commandHistory.lastUndoDescription}'
                        : 'Undo',
                    onPressed: _editorState.commandHistory.canUndo
                        ? () {
                            setState(() {
                              _editorState.commandHistory.undo();
                            });
                          }
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.redo),
                    tooltip: _editorState.commandHistory.canRedo
                        ? 'Redo: ${_editorState.commandHistory.lastRedoDescription}'
                        : 'Redo',
                    onPressed: _editorState.commandHistory.canRedo
                        ? () {
                            setState(() {
                              _editorState.commandHistory.redo();
                            });
                          }
                        : null,
                  ),
                ],
              ),
              body: ClipRect(
                child: InteractiveViewer(
                  transformationController:
                      _canvasController.transformationController,
                  boundaryMargin: const EdgeInsets.all(1000),
                  minScale: 0.1,
                  constrained: false,
                  maxScale: 3.0,
                  panEnabled: true,
                  scaleEnabled: true,
                  child: CustomPaint(
                    key: _editorState.interactiveViewerChildKey,
                    foregroundPainter: ConnectionPainter(
                      flowManager: _editorState.flowManager,
                      componentPositions: _editorState.componentPositions,
                      componentKeys: _editorState.componentKeys,
                      componentWidths: _editorState.componentWidths,
                      tempLineStartInfo: _dragManager.currentDraggedPort,
                      tempLineEndPoint: _dragManager.tempLineEndPoint,
                    ),
                    child: GestureDetector(
                      onTapDown: (details) {
                        final canvasBox =
                            _editorState.canvasKey.currentContext
                                    ?.findRenderObject()
                                as RenderBox?;
                        if (canvasBox != null) {
                          final canvasPosition = _canvasController
                              .getCanvasPosition(
                                details.globalPosition,
                                canvasBox,
                              );
                          if (canvasPosition != null) {
                            _selectionManager.clearSelection();
                          }
                        }
                      },
                      onPanStart: (details) {
                        final canvasBox =
                            _editorState.canvasKey.currentContext
                                    ?.findRenderObject()
                                as RenderBox?;
                        if (canvasBox != null) {
                          final canvasPosition = _canvasController
                              .getCanvasPosition(
                                details.globalPosition,
                                canvasBox,
                              );
                          if (canvasPosition != null) {
                            bool isClickOnComponent = _editorState
                                .isPointOverComponent(canvasPosition);
                            if (!isClickOnComponent) {
                              _selectionManager.startSelectionBox(
                                canvasPosition,
                              );
                            }
                          }
                        }
                      },
                      onPanUpdate: (details) {
                        final canvasBox =
                            _editorState.canvasKey.currentContext
                                    ?.findRenderObject()
                                as RenderBox?;
                        if (canvasBox != null) {
                          final canvasPosition = _canvasController
                              .getCanvasPosition(
                                details.globalPosition,
                                canvasBox,
                              );
                          if (canvasPosition != null) {
                            if (_selectionManager.isDraggingSelectionBox) {
                              setState(() {
                                _selectionManager.updateSelectionBox(
                                  canvasPosition,
                                );
                              });
                            } else if (_dragManager.isPortDragInProgress()) {
                              setState(() {
                                _dragManager.updatePortDragPosition(
                                  canvasPosition,
                                );
                              });
                            }
                          }
                        }
                      },
                      onPanEnd: (details) {
                        if (_selectionManager.isDraggingSelectionBox) {
                          setState(() {
                            _selectionManager.endSelectionBoxWithSizes(
                              _editorState.flowManager.components,
                              _editorState.componentPositions,
                              _editorState.componentWidths,
                              150.0,
                            );
                          });
                        }
                      },
                      onDoubleTapDown: (TapDownDetails details) {
                        final canvasBox =
                            _editorState.canvasKey.currentContext
                                    ?.findRenderObject()
                                as RenderBox?;
                        if (canvasBox != null) {
                          final canvasPosition = _canvasController
                              .getCanvasPosition(
                                details.globalPosition,
                                canvasBox,
                              );
                          if (canvasPosition != null) {
                            bool isClickOnComponent = _editorState
                                .isPointOverComponent(canvasPosition);
                            if (!isClickOnComponent) {
                              _showCanvasContextMenu(
                                context,
                                details.globalPosition,
                              );
                            }
                          }
                        }
                      },
                      child: DragTarget<Object>(
                        onAcceptWithDetails:
                            (DragTargetDetails<dynamic> details) {
                              final canvasBox =
                                  _editorState.canvasKey.currentContext
                                          ?.findRenderObject()
                                      as RenderBox?;
                              if (canvasBox != null) {
                                final canvasPosition = _canvasController
                                    .getCanvasPosition(
                                      details.offset,
                                      canvasBox,
                                    );

                                if (canvasPosition != null) {
                                  _handleCanvasDropAccept(
                                    details.data,
                                    canvasPosition,
                                  );
                                }
                              }
                            },
                        builder: (context, candidateData, rejectedData) {
                          return Container(
                            key: _editorState.canvasKey,
                            width: _canvasController.canvasSize.width,
                            height: _canvasController.canvasSize.height,
                            color: Colors.grey[50],
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                CustomPaint(
                                  painter: GridPainter(),
                                  size: _canvasSize,
                                ),
                                if (_selectionManager.isDraggingSelectionBox &&
                                    _selectionManager.selectionBoxStart !=
                                        null &&
                                    _selectionManager.selectionBoxEnd != null)
                                  CustomPaint(
                                    painter: SelectionBoxPainter(
                                      start:
                                          _selectionManager.selectionBoxStart,
                                      end: _selectionManager.selectionBoxEnd,
                                    ),
                                    size: _canvasSize,
                                  ),
                                if (_editorState.flowManager.components.isEmpty)
                                  const Center(
                                    child: Text(
                                      'Add components to the canvas',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ..._editorState.flowManager.components.map((
                                  component,
                                ) {
                                  return Positioned(
                                    left: _editorState
                                        .getComponentPosition(component.id)
                                        .dx,
                                    top: _editorState
                                        .getComponentPosition(component.id)
                                        .dy,
                                    child: Draggable<String>(
                                      data: component.id,
                                      feedback: Material(
                                        elevation: 5.0,
                                        color: Colors.transparent,
                                        child: ComponentWidget(
                                          component: component,
                                          height:
                                              component.allSlots.length *
                                              rowHeight,
                                          isSelected: _selectionManager
                                              .isComponentSelected(component),
                                          widgetKey: _editorState
                                              .getComponentKey(component.id),
                                          position: _editorState
                                              .getComponentPosition(
                                                component.id,
                                              ),
                                          width: _editorState.getComponentWidth(
                                            component.id,
                                          ),
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
                                          height:
                                              component.allSlots.length *
                                              rowHeight,
                                          isSelected: _selectionManager
                                              .isComponentSelected(component),
                                          widgetKey: GlobalKey(),
                                          position: _editorState
                                              .getComponentPosition(
                                                component.id,
                                              ),
                                          width: _editorState.getComponentWidth(
                                            component.id,
                                          ),
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
                                        _dragManager.startComponentDrag(
                                          _editorState.getComponentPosition(
                                            component.id,
                                          ),
                                        );
                                      },
                                      onDragEnd: (details) {
                                        _handleComponentDragEnd(
                                          component,
                                          details,
                                        );
                                      },
                                      child: GestureDetector(
                                        onSecondaryTapDown: (details) {
                                          _showContextMenu(
                                            context,
                                            details.globalPosition,
                                            component,
                                          );
                                        },
                                        onTap: () {
                                          if (HardwareKeyboard
                                              .instance
                                              .isControlPressed) {
                                            _selectionManager
                                                .toggleComponentSelection(
                                                  component,
                                                );
                                          } else {
                                            _selectionManager.selectComponent(
                                              component,
                                            );
                                          }
                                        },
                                        child: ComponentWidget(
                                          component: component,
                                          height:
                                              component.allSlots.length *
                                              rowHeight,
                                          width: _editorState.getComponentWidth(
                                            component.id,
                                          ),
                                          onWidthChanged:
                                              _handleComponentResize,
                                          isSelected: _selectionManager
                                              .isComponentSelected(component),
                                          widgetKey: _editorState
                                              .getComponentKey(component.id),
                                          position: _editorState
                                              .getComponentPosition(
                                                component.id,
                                              ),
                                          onValueChanged: _handleValueChanged,
                                          onSlotDragStarted:
                                              _handlePortDragStarted,
                                          onSlotDragAccepted:
                                              _handlePortDragAccepted,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
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
                        _canvasController.resetView();
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
    final canvasBox =
        _editorState.canvasKey.currentContext?.findRenderObject() as RenderBox?;
    final canvasPosition = canvasBox != null
        ? _canvasController.getCanvasPosition(globalPosition, canvasBox)
        : null;

    if (canvasPosition == null) return;

    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(globalPosition, globalPosition),
        Offset.zero & overlay.size,
      ),
      items: [...canvasMenuOptions(_clipboardManager)],
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
          _selectionManager.selectAll(_editorState.flowManager.components);
          break;
      }
    });
  }

  void _showPasteSpecialDialog(Offset pastePosition) {
    if (_clipboardManager.isEmpty) return;

    TextEditingController copiesController = TextEditingController(text: '1');
    ValueNotifier<bool> keepConnections = ValueNotifier<bool>(true);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return showPasteSpecialDialog(
          context,
          copiesController,
          keepConnections,
          _handlePasteSpecialComponent,
          pastePosition,
        );
      },
    );
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
                _buildComponentCategorySection('Custom Components', [
                  RectangleComponent.RECTANGLE,
                  RampComponent.RAMP,
                ], position),
                _buildComponentCategorySection('Logic Gates', [
                  ComponentType.AND_GATE,
                  ComponentType.OR_GATE,
                  ComponentType.XOR_GATE,
                  ComponentType.NOT_GATE,
                ], position),
                _buildComponentCategorySection('Math Operations', [
                  ComponentType.ADD,
                  ComponentType.SUBTRACT,
                  ComponentType.MULTIPLY,
                  ComponentType.DIVIDE,
                  ComponentType.MAX,
                  ComponentType.MIN,
                  ComponentType.POWER,
                  ComponentType.ABS,
                ], position),
                _buildComponentCategorySection('Comparisons', [
                  ComponentType.IS_GREATER_THAN,
                  ComponentType.IS_LESS_THAN,
                  ComponentType.IS_EQUAL,
                ], position),
                _buildComponentCategorySection('Writable Points', [
                  ComponentType.BOOLEAN_WRITABLE,
                  ComponentType.NUMERIC_WRITABLE,
                  ComponentType.STRING_WRITABLE,
                ], position),
                _buildComponentCategorySection('Read-Only Points', [
                  ComponentType.BOOLEAN_POINT,
                  ComponentType.NUMERIC_POINT,
                  ComponentType.STRING_POINT,
                ], position),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildComponentCategorySection(
    String title,
    List<String> typeStrings,
    Offset position,
  ) {
    List<ComponentType> types = typeStrings
        .map((t) => ComponentType(t))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12.0, bottom: 6.0),
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
    BuildContext context,
    Offset position,
    Component component,
  ) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(position, position),
        Offset.zero & overlay.size,
      ),
      items: showContextMenuOptions(_clipboardManager),
    ).then((value) {
      if (value == null) return;

      switch (value) {
        case 'copy':
          if (_selectionManager.selectedComponents.length == 1) {
            _handleCopyComponent(_selectionManager.selectedComponents.first);
          } else if (_selectionManager.selectedComponents.isNotEmpty) {
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

  void _addNewDeviceComponent(
    Map<String, dynamic> deviceData, {
    Offset? clickPosition,
  }) {
    HelvarDevice? device = deviceData["device"] as HelvarDevice?;

    if (device == null) {
      logError('Invalid device data');
      return;
    }

    String deviceName = device.description.isEmpty
        ? "Device_${device.deviceId}"
        : device.description;

    int counter = 1;
    String componentId = deviceName;
    while (_editorState.flowManager.components.any(
      (comp) => comp.id == componentId,
    )) {
      counter++;
      componentId = "${deviceName}_$counter";
    }

    Component newComponent = createComponentFromDevice(componentId, device);

    Offset newPosition;
    if (clickPosition != null) {
      newPosition = clickPosition;
    } else {
      final RenderBox? viewerChildRenderBox =
          _editorState.interactiveViewerChildKey.currentContext
                  ?.findRenderObject()
              as RenderBox?;

      newPosition = Offset(_canvasSize.width / 2, _canvasSize.height / 2);

      if (viewerChildRenderBox != null) {
        final viewportSize = viewerChildRenderBox.size;
        final viewportCenter = Offset(
          viewportSize.width / 2,
          viewportSize.height / 2,
        );
        final matrix = _transformationController.value;
        final inverseMatrix = Matrix4.inverted(matrix);
        final transformedCenter = MatrixUtils.transformPoint(
          inverseMatrix,
          viewportCenter,
        );

        newPosition = transformedCenter;
      }
    }

    Map<String, dynamic> state = {
      'position': newPosition,
      'key': _editorState.getComponentKey(newComponent.id),
      'positions': _editorState.componentPositions,
      'keys': _editorState.componentKeys,
    };

    setState(() {
      final command = AddComponentCommand(
        _editorState.flowManager,
        newComponent,
        state,
      );
      _editorState.commandHistory.execute(command);

      _editorState.initializeComponentState(
        newComponent,
        position: newPosition,
        width: 180.0,
      );

      _persistenceHelper.saveAddComponent(newComponent);
      _persistenceHelper.saveComponentPosition(newComponent.id, newPosition);
      _persistenceHelper.saveComponentWidth(newComponent.id, 180.0);

      _updateCanvasSize();
    });
  }

  void _addNewButtonPointComponent(
    Map<String, dynamic> buttonPointData, {
    Offset? clickPosition,
  }) {
    final ButtonPoint buttonPoint =
        buttonPointData["buttonPoint"] as ButtonPoint;
    final HelvarDevice parentDevice =
        buttonPointData["parentDevice"] as HelvarDevice;
    final Map<String, dynamic> pointData =
        buttonPointData["pointData"] as Map<String, dynamic>;

    String baseName = buttonPoint.name;
    String componentId = baseName;
    int counter = 1;

    while (_editorState.flowManager.components.any(
      (comp) => comp.id == componentId,
    )) {
      componentId = "${baseName}_$counter";
      counter++;
    }

    Component newComponent = _editorState.flowManager.createComponentByType(
      componentId,
      ComponentType.BOOLEAN_POINT,
    );

    bool initialValue = _getInitialButtonPointValue(buttonPoint);

    for (var property in newComponent.properties) {
      if (!property.isInput && property.type.type == PortType.BOOLEAN) {
        property.value = initialValue;
        break;
      }
    }

    _storeButtonPointMetadata(componentId, buttonPoint, parentDevice);

    Offset newPosition =
        clickPosition ?? getDefaultPosition(_canvasController, _editorState);

    Map<String, dynamic> state = {
      'position': newPosition,
      'key': _editorState.getComponentKey(newComponent.id),
      'positions': _editorState.componentPositions,
      'keys': _editorState.componentKeys,
    };

    setState(() {
      final command = AddComponentCommand(
        _editorState.flowManager,
        newComponent,
        state,
      );
      _editorState.commandHistory.execute(command);

      _editorState.initializeComponentState(
        newComponent,
        position: newPosition,
        width: 160.0,
      );

      _persistenceHelper.saveAddComponent(newComponent);
      _persistenceHelper.saveComponentPosition(newComponent.id, newPosition);
      _persistenceHelper.saveComponentWidth(newComponent.id, 160.0);

      _updateCanvasSize();
    });
  }

  bool _getInitialButtonPointValue(ButtonPoint buttonPoint) {
    if (buttonPoint.function.contains('Status') ||
        buttonPoint.name.toLowerCase().contains('missing')) {
      return false;
    }

    return false;
  }

  void _storeButtonPointMetadata(
    String componentId,
    ButtonPoint buttonPoint,
    HelvarDevice parentDevice,
  ) {
    _buttonPointMetadata[componentId] = {
      'buttonPoint': buttonPoint,
      'parentDevice': parentDevice,
      'deviceAddress': parentDevice.address,
      'buttonId': buttonPoint.buttonId,
      'function': buttonPoint.function,
    };
  }

  void _handleCanvasDropAccept(dynamic data, Offset canvasPosition) {
    if (data is ComponentType) {
      _addNewComponent(data, clickPosition: canvasPosition);
    } else if (data is Map<String, dynamic>) {
      if (data.containsKey("buttonPoint") && data.containsKey("pointData")) {
        _addNewButtonPointComponent(data, clickPosition: canvasPosition);
      } else if (data.containsKey("device")) {
        _addNewDeviceComponent(data, clickPosition: canvasPosition);
      }
    }
  }

  void _handleComponentDragEnd(Component component, DraggableDetails details) {
    final RenderBox? viewerChildRenderBox =
        _editorState.interactiveViewerChildKey.currentContext
                ?.findRenderObject()
            as RenderBox?;

    if (viewerChildRenderBox != null) {
      final Offset localOffset = viewerChildRenderBox.globalToLocal(
        details.offset,
      );

      if (_dragManager.dragStartPosition != null &&
          _dragManager.dragStartPosition != localOffset) {
        setState(() {
          if (_selectionManager.isComponentSelected(component) &&
              _selectionManager.selectedComponents.length > 1) {
            _handleMultiComponentDrag(localOffset);
          } else {
            _handleSingleComponentDrag(component, localOffset);
          }

          _dragManager.endComponentDrag();
          _updateCanvasSize();
        });
      }
    }
  }

  void _handleMultiComponentDrag(Offset localOffset) {
    final offset = localOffset - _dragManager.dragStartPosition!;
    final updatedPositions = _dragManager.moveComponentsByOffset(
      _editorState.componentPositions,
      _selectionManager.selectedComponents,
      offset,
    );

    for (var selectedComponent in _selectionManager.selectedComponents) {
      final newPos = updatedPositions[selectedComponent.id]!;
      final command = MoveComponentCommand(
        selectedComponent.id,
        newPos,
        _editorState.getComponentPosition(selectedComponent.id),
        _editorState.componentPositions,
      );
      _editorState.commandHistory.execute(command);
      _persistenceHelper.saveComponentPosition(selectedComponent.id, newPos);
    }
  }

  void _handleSingleComponentDrag(Component component, Offset localOffset) {
    final command = MoveComponentCommand(
      component.id,
      localOffset,
      _dragManager.dragStartPosition!,
      _editorState.componentPositions,
    );
    _editorState.commandHistory.execute(command);
    _persistenceHelper.saveComponentPosition(component.id, localOffset);
    _selectionManager.selectComponent(component);
  }

  void _handleCopyMultipleComponents() {
    if (_selectionManager.selectedComponents.isEmpty) return;

    _clipboardManager.copyMultipleComponents(
      _selectionManager.selectedComponents,
      _editorState.componentPositions,
      _editorState.flowManager.connections,
    );
  }

  void _handlePasteComponent(Offset position) {
    if (_clipboardManager.isEmpty) return;

    final pastePositions = _clipboardManager.calculatePastePositions(position);

    Map<String, String> idMap = {};

    for (int i = 0; i < _clipboardManager.clipboardComponents.length; i++) {
      var originalComponent = _clipboardManager.clipboardComponents[i];
      var newPosition = pastePositions[i];

      String newName = '${originalComponent.id} (Copy)';
      int counter = 1;
      while (_editorState.flowManager.components.any(
        (comp) => comp.id == newName,
      )) {
        counter++;
        newName = '${originalComponent.id} (Copy $counter)';
      }

      Component newComponent = _editorState.flowManager.createComponentByType(
        newName,
        originalComponent.type.type,
      );

      for (var sourceProperty in originalComponent.properties) {
        if (!originalComponent.inputConnections.containsKey(
          sourceProperty.index,
        )) {
          for (var targetProperty in newComponent.properties) {
            if (targetProperty.index == sourceProperty.index) {
              targetProperty.value = sourceProperty.value;
              break;
            }
          }
        }
      }

      Map<String, dynamic> state = {
        'position': newPosition,
        'key': _editorState.getComponentKey(newComponent.id),
        'positions': _editorState.componentPositions,
        'keys': _editorState.componentKeys,
      };

      idMap[originalComponent.id] = newComponent.id;
      final command = AddComponentCommand(
        _editorState.flowManager,
        newComponent,
        state,
      );
      _editorState.commandHistory.execute(command);

      _editorState.initializeComponentState(
        newComponent,
        position: newPosition,
        width: 160.0,
      );
    }

    for (var connection in _clipboardManager.clipboardConnections) {
      String? newFromId = idMap[connection.fromComponentId];
      String? newToId = idMap[connection.toComponentId];

      if (newFromId != null && newToId != null) {
        final command = CreateConnectionCommand(
          _editorState.flowManager,
          newFromId,
          connection.fromPortIndex,
          newToId,
          connection.toPortIndex,
        );
        _editorState.commandHistory.execute(command);
      }
    }

    setState(() {
      _updateCanvasSize();
    });
  }

  void _handlePasteSpecialComponent(
    Offset position,
    int numberOfCopies,
    bool keepAllLinks,
  ) {
    if (_clipboardManager.isEmpty) return;

    const double offsetX = 50.0;
    const double offsetY = 50.0;

    for (int copyIndex = 0; copyIndex < numberOfCopies; copyIndex++) {
      final double baseOffsetX = copyIndex * offsetX;
      final double baseOffsetY = copyIndex * offsetY;

      Map<String, String> idMap = {};

      final basePastePositions = _clipboardManager.calculatePastePositions(
        Offset(position.dx + baseOffsetX, position.dy + baseOffsetY),
      );

      for (int i = 0; i < _clipboardManager.clipboardComponents.length; i++) {
        var originalComponent = _clipboardManager.clipboardComponents[i];
        var newPosition = basePastePositions[i];

        String newName = '${originalComponent.id} (Copy)';
        int counter = 1;
        while (_editorState.flowManager.components.any(
          (comp) => comp.id == newName,
        )) {
          counter++;
          newName = '${originalComponent.id} (Copy $counter)';
        }

        Component newComponent = _editorState.flowManager.createComponentByType(
          newName,
          originalComponent.type.type,
        );

        for (var sourceProperty in originalComponent.properties) {
          if (!originalComponent.inputConnections.containsKey(
                sourceProperty.index,
              ) ||
              !keepAllLinks) {
            for (var targetProperty in newComponent.properties) {
              if (targetProperty.index == sourceProperty.index) {
                targetProperty.value = sourceProperty.value;
                break;
              }
            }
          }
        }

        Map<String, dynamic> state = {
          'position': newPosition,
          'key': _editorState.getComponentKey(newComponent.id),
          'positions': _editorState.componentPositions,
          'keys': _editorState.componentKeys,
        };

        idMap[originalComponent.id] = newComponent.id;
        final command = AddComponentCommand(
          _editorState.flowManager,
          newComponent,
          state,
        );
        _editorState.commandHistory.execute(command);

        _editorState.initializeComponentState(
          newComponent,
          position: newPosition,
          width: 160.0,
        );
      }

      if (keepAllLinks) {
        for (var connection in _clipboardManager.clipboardConnections) {
          String? newFromId = idMap[connection.fromComponentId];
          String? newToId = idMap[connection.toComponentId];

          if (newFromId != null && newToId != null) {
            final command = CreateConnectionCommand(
              _editorState.flowManager,
              newFromId,
              connection.fromPortIndex,
              newToId,
              connection.toPortIndex,
            );
            _editorState.commandHistory.execute(command);
          }
        }
      }
    }

    setState(() {
      _updateCanvasSize();
    });
  }

  void _handleCopyComponent(Component component) {
    final position = _editorState.getComponentPosition(component.id);
    _clipboardManager.copyComponent(component, position);
  }

  void _handleEditComponent(BuildContext context, Component component) {
    _flowHandlers.handleEditComponent(context, component);
  }

  void _handleDeleteComponent(Component component) {
    final componentId = component.id;

    final List<Connection> connectionsToDelete = [];
    for (final comp in _editorState.flowManager.components) {
      for (final entry in comp.inputConnections.entries) {
        if (entry.value.componentId == componentId) {
          connectionsToDelete.add(
            Connection(
              fromComponentId: entry.value.componentId,
              fromPortIndex: entry.value.portIndex,
              toComponentId: comp.id,
              toPortIndex: entry.key,
            ),
          );
        }
      }
    }

    for (final entry in component.inputConnections.entries) {
      connectionsToDelete.add(
        Connection(
          fromComponentId: entry.value.componentId,
          fromPortIndex: entry.value.portIndex,
          toComponentId: componentId,
          toPortIndex: entry.key,
        ),
      );
    }

    _flowHandlers.handleDeleteComponent(component);

    _persistenceHelper.saveRemoveComponent(componentId);

    for (final connection in connectionsToDelete) {
      _persistenceHelper.saveRemoveConnection(
        connection.fromComponentId,
        connection.fromPortIndex,
        connection.toComponentId,
        connection.toPortIndex,
      );
    }
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
}
