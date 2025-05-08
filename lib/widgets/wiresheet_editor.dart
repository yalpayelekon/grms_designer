import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/helvar_models/device_action.dart';
import '../models/helvar_models/helvar_device.dart';
import '../models/link.dart';
import '../models/widget_type.dart';
import '../models/wiresheet.dart';
import '../models/canvas_item.dart';
import '../providers/wiresheets_provider.dart';
import '../providers/workgroups_provider.dart';
import '../utils/general_ui.dart';
import '../utils/helpers.dart';
import '../utils/logger.dart';
import '../widgets/grid_painter.dart';
import 'link_painter.dart';
import '../models/dragging_link_painter.dart';
import 'dart:math' as math;

class WiresheetEditor extends ConsumerStatefulWidget {
  final Wiresheet wiresheet;

  const WiresheetEditor({
    super.key,
    required this.wiresheet,
  });

  @override
  WiresheetEditorState createState() => WiresheetEditorState();
}

class WiresheetEditorState extends ConsumerState<WiresheetEditor> {
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
    _initializePortValues();
    _setupRampComponents();
  }

  void _initializePortValues() {
    for (final item in widget.wiresheet.canvasItems) {
      if (item.id != null) {
        _portValues[item.id!] = {};

        _initializeDefaultValues(item);
      }
    }
  }

  void _initializeDefaultValues(CanvasItem item) {
    if (item.category == ComponentCategory.point) {
      final pointType = item.properties['point'] as String?;
      if (pointType == 'NumericPoint') {
        _portValues[item.id!]!['out'] = 0;
      } else if (pointType == 'BooleanPoint') {
        _portValues[item.id!]!['out'] = false;
      }
    }
  }

  dynamic _getPortValue(String itemId, String portId) {
    if (_portValues.containsKey(itemId) &&
        _portValues[itemId]!.containsKey(portId)) {
      return _portValues[itemId]![portId];
    }
    return null;
  }

  void _setPortValue(String itemId, String portId, dynamic value) {
    if (!_portValues.containsKey(itemId)) {
      _portValues[itemId] = {};
    }

    final previousValue = _portValues[itemId]![portId];
    _portValues[itemId]![portId] = value;

    // Only trigger evaluation if value actually changed
    if (previousValue != value) {
      _evaluateLinks(updatedItemId: itemId, updatedPortId: portId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
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
            onInteractionEnd: (ScaleEndDetails details) {
              setState(() {});
            },
            child: Stack(
              children: [
                DragTarget<Object>(
                  onAcceptWithDetails: (details) {
                    final data = details.data;
                    final globalPosition = details.offset;
                    final RenderBox box =
                        context.findRenderObject() as RenderBox;
                    final localPosition = box.globalToLocal(globalPosition);
                    CanvasItem? newItem;

                    if (data is WidgetData) {
                      final additionalData = data.additionalData;
                      HelvarDevice? device;

                      if (additionalData["device"] != null) {
                        device = additionalData["device"];
                        newItem =
                            CanvasItem.createDeviceItem(device!, localPosition);
                      } else if (data.type == WidgetType.treenode) {
                        switch (data.category!) {
                          case ComponentCategory.logic:
                            newItem = CanvasItem.createLogicItem(
                                additionalData["label"]!, localPosition);
                            break;
                          case ComponentCategory.math:
                            newItem = CanvasItem.createMathItem(
                                additionalData["label"]!, localPosition);
                            break;
                          case ComponentCategory.point:
                            newItem = CanvasItem.createPointItem(
                                additionalData["label"]!, localPosition);
                            break;
                          case ComponentCategory.ui:
                            newItem = CanvasItem.createUIItem(
                                additionalData["label"]!, localPosition);
                            break;
                          case ComponentCategory.util:
                            newItem = CanvasItem.createUtilItem(
                                additionalData["label"]!, localPosition);
                            break;
                        }
                      } else {
                        newItem = CanvasItem(
                            type: WidgetType.container,
                            position: localPosition,
                            size: const Size(120, 80));
                      }

                      ref.read(wiresheetsProvider.notifier).addWiresheetItem(
                            widget.wiresheet.id,
                            newItem!,
                          );

                      setState(() {
                        selectedItemIndex =
                            widget.wiresheet.canvasItems.length - 1;
                        isPanelExpanded = true;
                      });

                      updateCanvasSize(widget.wiresheet, ref);
                    }
                  },
                  builder: (context, candidateData, rejectedData) {
                    return Stack(
                      children: [
                        Container(
                          width: widget.wiresheet.canvasSize.width,
                          height: widget.wiresheet.canvasSize.height,
                          color: Colors.grey[50],
                          child: Center(
                            child: Text(
                              widget.wiresheet.canvasItems.isEmpty
                                  ? 'Drag and drop items here'
                                  : '',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: widget.wiresheet.canvasSize.width,
                          height: widget.wiresheet.canvasSize.height,
                          child: CustomPaint(
                            painter: GridPainter(),
                            child: Container(),
                          ),
                        ),
                        if (widget.wiresheet.links.isNotEmpty)
                          CustomPaint(
                            painter: LinkPainter(
                              links: widget.wiresheet.links,
                              items: widget.wiresheet.canvasItems,
                              onLinkSelected: _handleLinkSelected,
                              hoveredLinkId: hoveredLinkId,
                              selectedLinkId: selectedLinkId,
                            ),
                            size: Size(
                              widget.wiresheet.canvasSize.width,
                              widget.wiresheet.canvasSize.height,
                            ),
                          ),
                        if (isDraggingLink &&
                            selectedSourceItemId != null &&
                            selectedSourcePortId != null &&
                            linkDragEndPoint != null)
                          CustomPaint(
                            painter: DraggingLinkPainter(
                              startItem: widget.wiresheet.canvasItems
                                  .firstWhere((item) =>
                                      item.id == selectedSourceItemId),
                              startPortId: selectedSourcePortId!,
                              endPoint: linkDragEndPoint!,
                            ),
                            size: Size(
                              widget.wiresheet.canvasSize.width,
                              widget.wiresheet.canvasSize.height,
                            ),
                          ),
                        ...widget.wiresheet.canvasItems
                            .asMap()
                            .entries
                            .map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          return Positioned(
                            left: item.position.dx,
                            top: item.position.dy,
                            child: _buildDraggableCanvasItem(item, index),
                          );
                        }),
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
                  isPanelExpanded ? Icons.arrow_forward : Icons.arrow_back,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (isDraggingLink) {
      setState(() {
        final RenderBox box = context.findRenderObject() as RenderBox;
        linkDragEndPoint = box.globalToLocal(event.position);
      });
    } else {
      final hoveredLink = _findLinkAtPosition(event.position);
      if (hoveredLink != hoveredLinkId) {
        setState(() {
          hoveredLinkId = hoveredLink;
        });
      }
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    final clickedLinkId = _findLinkAtPosition(event.position);
    if (clickedLinkId != null) {
      setState(() {
        selectedLinkId = clickedLinkId;
      });

      _handleLinkSelected(clickedLinkId);
    } else {
      if (selectedLinkId != null) {
        setState(() {
          selectedLinkId = null;
        });
      }
    }
  }

  Widget _buildDraggableCanvasItem(CanvasItem item, int index) {
    final isSelected = selectedItemIndex == index;

    final calculatedHeight =
        headerHeight + (item.ports.length * rowHeight) + 10;
    final itemHeight = math.max(item.size.height, calculatedHeight);

    if (itemHeight > item.size.height) {
      final updatedItem = item.copyWith(
        size: Size(item.size.width, itemHeight),
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(wiresheetsProvider.notifier).updateWiresheetItem(
              widget.wiresheet.id,
              index,
              updatedItem,
            );
      });
    }

    return Stack(
      children: [
        Draggable<int>(
          data: index,
          feedback: Material(
            elevation: 4,
            color: Colors.transparent,
            child: Container(
              width: item.size.width,
              height: itemHeight, // Use the calculated height for feedback
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.8),
                border: Border.all(
                  color: Colors.blue,
                  width: 2.0,
                ),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: _buildItemContents(item, true),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: Container(
              width: item.size.width,
              height:
                  itemHeight, // Use the calculated height for dragging placeholder
              decoration: BoxDecoration(
                color: Colors.grey,
                border: Border.all(
                  color: Colors.grey,
                  width: 1.0,
                ),
                borderRadius: BorderRadius.circular(4.0),
              ),
            ),
          ),
          onDragEnd: (details) {
            if (details.wasAccepted) {
              final RenderBox box = context.findRenderObject() as RenderBox;
              final localOffset = box.globalToLocal(details.offset);
              final updatedItem = item.copyWith(
                position: localOffset,
                size: Size(item.size.width,
                    itemHeight), // Preserve the calculated height
              );

              ref.read(wiresheetsProvider.notifier).updateWiresheetItem(
                    widget.wiresheet.id,
                    index,
                    updatedItem,
                  );
              setState(() {});
            }
          },
          child: GestureDetector(
            onTap: () {
              setState(() {
                selectedItemIndex = index;
                isPanelExpanded = true;
              });
            },
            onSecondaryTapDown: (details) {
              _lastTapPosition = details.globalPosition;
            },
            onSecondaryTap: () {
              _showContextMenu(context, item, index);
            },
            child: Container(
              width: item.size.width,
              height: itemHeight, // Use the calculated height
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue.shade100 : Colors.white,
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey,
                  width: isSelected ? 2.0 : 1.0,
                ),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: _buildItemContents(item, false),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemContents(CanvasItem item, bool isFeedback) {
    final List<Port> allPorts = item.ports;
    if (item.category == ComponentCategory.ui) {
      final uiType = item.properties['ui_type'] as String?;

      if (uiType == 'Button') {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: headerHeight,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              alignment: Alignment.centerLeft,
              child: Text(
                item.label ?? "Button",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isFeedback ? Colors.white : Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              height: 1,
              color: Colors.grey.withOpacity(0.5),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: isFeedback ? null : () => _handleButtonClick(item),
                  child: Text(
                    _getPortValue(item.id!, 'label') as String? ?? 'Click Me',
                    style: TextStyle(
                      color: isFeedback ? Colors.white.withOpacity(0.9) : null,
                    ),
                  ),
                ),
              ),
            ),
            // We still need to show the ports for connections
            Container(
              height: allPorts.length * rowHeight,
              child: ListView.builder(
                itemCount: allPorts.length,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, i) {
                  return _buildPortRow(item, allPorts[i], allPorts[i].isInput,
                      rowHeight, isFeedback);
                },
              ),
            ),
          ],
        );
      } else if (uiType == 'Text') {
        // Handle text component rendering
        // ...
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: headerHeight,
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          alignment: Alignment.centerLeft,
          child: Text(
            item.label ?? "Item",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isFeedback ? Colors.white : Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          height: 1,
          color: Colors.grey.withOpacity(0.5),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: allPorts.length,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, i) {
              return _buildPortRow(item, allPorts[i], allPorts[i].isInput,
                  rowHeight, isFeedback);
            },
          ),
        ),
      ],
    );
  }

  // Handle button click - set output port value and trigger link evaluation
  void _handleButtonClick(CanvasItem buttonItem) {
    if (buttonItem.id == null) return;

    // Set 'click' port to true
    _setPortValue(buttonItem.id!, 'click', true);

    // Schedule to reset the click value after a short delay
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _setPortValue(buttonItem.id!, 'click', false);
      }
    });

    // Update UI
    setState(() {});
  }

  Timer? _rampTimer;

  void _setupRampComponents() {
    _rampTimer?.cancel();

    // Create a new timer that updates ramp values
    _rampTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      // Find and update all Ramp components
      for (final item in widget.wiresheet.canvasItems) {
        if (item.category == ComponentCategory.util &&
            item.properties['util_type'] == 'Ramp' &&
            item.id != null) {
          _updateRampValue(item);
        }
      }
    });
  }

  @override
  void dispose() {
    _rampTimer?.cancel();
    super.dispose();
  }

  void _updateRampValue(CanvasItem rampItem) {
    final min =
        _getPortValue(rampItem.id!, 'min') ?? rampItem.properties['min'] ?? 0;
    final max =
        _getPortValue(rampItem.id!, 'max') ?? rampItem.properties['max'] ?? 100;
    final period = _getPortValue(rampItem.id!, 'period') ??
        rampItem.properties['period'] ??
        10.0;

    // Calculate current value based on time
    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final phase = (now % period) / period; // 0.0 to 1.0

    // Use sine wave pattern for smooth transition
    final normalized =
        (math.sin(phase * 2 * math.pi - math.pi / 2) + 1) / 2; // 0.0 to 1.0
    final value = min + normalized * (max - min);

    // Update the output port value
    final previousValue = _getPortValue(rampItem.id!, 'out');
    _setPortValue(rampItem.id!, 'out', value);

    // Force UI update occasionally
    if (previousValue == null || (previousValue - value).abs() > 5) {
      setState(() {});
    }
  }

  Widget _buildPortRow(CanvasItem item, Port port, bool isInput, double height,
      bool isFeedback) {
    final Color portColor = isInput ? Colors.blue : Colors.green;

    return DragTarget<Map<String, dynamic>>(
      onAcceptWithDetails: (details) {
        final data = details.data;
        if (isInput &&
            !isFeedback &&
            data.containsKey('itemId') &&
            data.containsKey('portId')) {
          if (data['itemId'] != item.id || data['portId'] != port.id) {
            _handlePortConnection(
                data['itemId'], data['portId'], item.id!, port.id);
          }
        }
      },
      builder: (context, candidateData, rejectedData) {
        final bool isCompatible = candidateData.isNotEmpty && isInput;

        return LongPressDraggable<Map<String, dynamic>>(
          data: {
            'itemId': item.id,
            'portId': port.id,
            'isInput': isInput,
          },
          feedback: Material(
            color: Colors.transparent,
            child: Container(
              width: 100,
              height: height,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.3),
                border: Border.all(color: Colors.blue),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  port.name,
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
          ),
          onDragStarted: () {
            if (!isInput && !isFeedback) {
              setState(() {
                selectedSourceItemId = item.id;
                selectedSourcePortId = port.id;
                isDraggingLink = true;
              });
            }
          },
          onDragEnd: (details) {
            if (!isInput && !isFeedback) {
              setState(() {
                isDraggingLink = false;
                selectedSourceItemId = null;
                selectedSourcePortId = null;
                linkDragEndPoint = null;
              });
            }
          },
          onDraggableCanceled: (velocity, offset) {
            setState(() {
              isDraggingLink = false;
              selectedSourceItemId = null;
              selectedSourcePortId = null;
              linkDragEndPoint = null;
            });
          },
          child: GestureDetector(
            onTap: () {
              if (!isFeedback) {
                _handlePortTap(item.id!, port.id, isInput);
              }
            },
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: isCompatible ? Colors.green.withOpacity(0.2) : null,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  if (isInput) ...[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: portColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      port.name,
                      style: TextStyle(
                        fontSize: 10,
                        color: isFeedback
                            ? Colors.white.withOpacity(0.9)
                            : Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!isInput) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: portColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showContextMenu(BuildContext context, CanvasItem item, int index) {
    if (_lastTapPosition == null) {
      final RenderBox overlay = Navigator.of(context)
          .overlay!
          .context
          .findRenderObject() as RenderBox;

      _lastTapPosition = overlay.localToGlobal(Offset(
          item.position.dx + item.size.width / 2,
          item.position.dy + item.size.height / 2));
    }
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromLTWH(_lastTapPosition!.dx, _lastTapPosition!.dy, 1, 1),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: context,
      position: position,
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
          _copyItem(item);
          break;
        case 'edit':
          _editItem(context, item, index);
          break;
        case 'delete':
          _deleteItem(index);
          break;
      }
    });
  }

  void _executeAction(String targetItemId, String targetPortId, dynamic value) {
    CanvasItem? targetItem;
    for (CanvasItem item in widget.wiresheet.canvasItems) {
      if (item.id == targetItemId) {
        targetItem = item;
        break;
      }
    }
    if (targetItem == null) {
      return;
    }

    if (targetItem.properties.containsKey('device_id')) {
      _executeDeviceAction(targetItem, targetPortId, value);
    } else if (targetItem.category != null) {
      if (targetItem.category! case ComponentCategory.logic) {
        _processLogicComponent(targetItem, targetPortId, value);
      } else if (targetItem.category! case ComponentCategory.math) {
        _processMathComponent(targetItem, targetPortId, value);
      } else if (targetItem.category! case ComponentCategory.point) {
        _processPointComponent(targetItem, targetPortId, value);
      } else if (targetItem.category!
          case ComponentCategory.ui || ComponentCategory.util) {}
    }
  }

  void _executeDeviceAction(
      CanvasItem deviceItem, String portId, dynamic value) {
    final deviceId = deviceItem.properties['device_id'] as int?;
    final deviceAddress = deviceItem.properties['device_address'] as String?;

    if (deviceId == null || deviceAddress == null) return;

    final device =
        findDevice(deviceId, ref.read(workgroupsProvider), deviceAddress);
    if (device == null) return;

    try {
      DeviceAction? action;
      for (DeviceAction a in DeviceAction.values) {
        if (a.name == portId) {
          action = a;
          break;
        }
      }

      if (action != null) {
        device.performAction(action, value);
        setState(() {});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Executed ${action.displayName} on ${device.description}'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      logError("Error executing device action: ${e.toString()}");
    }
  }

  void _processLogicComponent(CanvasItem item, String portId, dynamic value) {
    final type = item.properties['logic_type'] as String?;
    if (type == null || item.id == null) return;

    switch (type) {
      case 'AND':
        if (portId == 'in1' || portId == 'in2') {
          // Store the input
          _setPortValue(item.id!, portId, value);

          // Check if both inputs are available
          final in1 = _getPortValue(item.id!, 'in1');
          final in2 = _getPortValue(item.id!, 'in2');

          if (in1 != null && in2 != null) {
            // Perform AND logic and set output
            final result = (in1 as bool) && (in2 as bool);
            _setPortValue(item.id!, 'out', result);
          }
        }
        break;

      case 'OR':
        if (portId == 'in1' || portId == 'in2') {
          // Store the input
          _setPortValue(item.id!, portId, value);

          // Check if both inputs are available
          final in1 = _getPortValue(item.id!, 'in1');
          final in2 = _getPortValue(item.id!, 'in2');

          if (in1 != null && in2 != null) {
            // Perform OR logic and set output
            final result = (in1 as bool) || (in2 as bool);
            _setPortValue(item.id!, 'out', result);
          }
        }
        break;

      case 'IF':
        if (portId == 'in1') {
          // Store the current condition
          bool previousCondition =
              _getPortValue(item.id!, 'last_condition') ?? false;
          bool newCondition = value as bool;

          // Store the new condition
          _setPortValue(item.id!, 'in1', newCondition);

          // Check if condition changed - this is key to the "execute only on change" behavior
          if (previousCondition != newCondition) {
            // Store the last condition
            _setPortValue(item.id!, 'last_condition', newCondition);

            // Set the output value based on the condition
            // This will trigger downstream actions
            _setPortValue(item.id!, 'out', newCondition ? 1 : 0);
          }
        }
        break;

      case 'GreaterThan':
        if (portId == 'in1' || portId == 'in2') {
          _setPortValue(item.id!, portId, value);

          final in1 = _getPortValue(item.id!, 'in1');
          final in2 = _getPortValue(item.id!, 'in2');

          if (in1 != null && in2 != null) {
            final previousResult = _getPortValue(item.id!, 'out');

            final num1 = in1 as num;
            final num2 = in2 as num;
            final result = num1 > num2;

            if (previousResult != result) {
              _setPortValue(item.id!, 'out', result);
            }
          }
        }
        break;
    }
  }

  void _evaluateLinks({String? updatedItemId, String? updatedPortId}) {
    final linksToEvaluate = updatedItemId != null && updatedPortId != null
        ? widget.wiresheet.links.where((link) =>
            link.sourceItemId == updatedItemId &&
            link.sourcePortId == updatedPortId)
        : widget.wiresheet.links;

    for (final link in linksToEvaluate) {
      if (_evaluatingLinks.contains(link.id)) continue;

      try {
        _evaluatingLinks.add(link.id);
        final value = _getPortValue(link.sourceItemId, link.sourcePortId);
        if (value == null) continue;
        _executeAction(link.targetItemId, link.targetPortId, value);
        _setPortValue(link.targetItemId, link.targetPortId, value);
      } finally {
        _evaluatingLinks.remove(link.id);
      }
    }
  }

  void _copyItem(CanvasItem item) {
    final newPosition = Offset(item.position.dx + 20, item.position.dy + 20);
    final newItem = item.copyWith(
      id: const Uuid().v4(),
      position: newPosition,
      label: '${item.label} (Copy)',
    );

    ref.read(wiresheetsProvider.notifier).addWiresheetItem(
          widget.wiresheet.id,
          newItem,
        );

    setState(() {
      selectedItemIndex = widget.wiresheet.canvasItems.length - 1;
      isPanelExpanded = true;
    });

    updateCanvasSize(widget.wiresheet, ref);
  }

  void _editItem(BuildContext context, CanvasItem item, int index) {
    TextEditingController labelController =
        TextEditingController(text: item.label);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelController,
                decoration: const InputDecoration(
                  labelText: 'Label',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final updatedItem = item.copyWith(
                  label: labelController.text,
                );

                ref.read(wiresheetsProvider.notifier).updateWiresheetItem(
                      widget.wiresheet.id,
                      index,
                      updatedItem,
                    );

                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _deleteItem(int index) {
    final item = widget.wiresheet.canvasItems[index];

    final linksToDelete = widget.wiresheet.links
        .where((link) =>
            link.sourceItemId == item.id || link.targetItemId == item.id)
        .toList();

    for (var link in linksToDelete) {
      ref.read(wiresheetsProvider.notifier).removeLink(
            widget.wiresheet.id,
            link.id,
          );
    }

    ref.read(wiresheetsProvider.notifier).removeWiresheetItem(
          widget.wiresheet.id,
          index,
        );

    setState(() {
      selectedItemIndex = null;
      isPanelExpanded = false;
    });
  }

  String? _findLinkAtPosition(Offset position) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(position);

    bool isPointNearCurve(Offset point, Offset start, Offset end,
        Offset control1, Offset control2, double threshold) {
      for (int i = 0; i <= 20; i++) {
        final t = i / 20;
        final curvePoint = evaluateCubic(start, control1, control2, end, t);
        final distance = (curvePoint - point).distance;

        if (distance < threshold) {
          return true;
        }
      }
      return false;
    }

    for (final link in widget.wiresheet.links) {
      final sourceItem = widget.wiresheet.canvasItems
          .firstWhere((item) => item.id == link.sourceItemId);
      final targetItem = widget.wiresheet.canvasItems
          .firstWhere((item) => item.id == link.targetItemId);

      final sourcePort = sourceItem.getPort(link.sourcePortId);
      final targetPort = targetItem.getPort(link.targetPortId);

      if (sourcePort == null || targetPort == null) continue;

      final start = getPortPosition(sourceItem, sourcePort, false);
      final end = getPortPosition(targetItem, targetPort, true);

      final control1 = Offset(start.dx + (end.dx - start.dx) * 0.4, start.dy);
      final control2 = Offset(start.dx + (end.dx - start.dx) * 0.6, end.dy);

      if (isPointNearCurve(
          localPosition, start, end, control1, control2, 10.0)) {
        return link.id;
      }
    }

    return null;
  }

  String _getItemLabel(String itemId) {
    try {
      final item =
          widget.wiresheet.canvasItems.firstWhere((i) => i.id == itemId);
      return item.label ?? 'Untitled Item';
    } catch (e) {
      return 'Unknown Item';
    }
  }

  void _handleLinkSelected(String linkId) {
    final link = widget.wiresheet.links.firstWhere((l) => l.id == linkId);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Link Properties'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Source: ${_getItemLabel(link.sourceItemId)}'),
            Text('Target: ${_getItemLabel(link.targetItemId)}'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _deleteLink(link.id);
                  },
                  child:
                      const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _deleteLink(String linkId) {
    ref.read(wiresheetsProvider.notifier).removeLink(
          widget.wiresheet.id,
          linkId,
        );
    setState(() {
      selectedLinkId = null;
      hoveredLinkId = null;
    });
  }

  void _handlePortTap(String itemId, String portId, bool isInput) {
    if (selectedSourceItemId == null && !isInput) {
      setState(() {
        selectedSourceItemId = itemId;
        selectedSourcePortId = portId;
      });
      showSnackBarMsg(context, 'Now select a target port');
    } else if (selectedSourceItemId != null && isInput) {
      if (selectedSourceItemId == itemId && selectedSourcePortId == portId) {
        setState(() {
          selectedSourceItemId = null;
          selectedSourcePortId = null;
        });
        showSnackBarMsg(context, 'Cannot connect a port to itself');
      } else {
        _handlePortConnection(
          selectedSourceItemId!,
          selectedSourcePortId!,
          itemId,
          portId,
        );

        setState(() {
          selectedSourceItemId = null;
          selectedSourcePortId = null;
        });
      }
    } else if (selectedSourceItemId != null && !isInput) {
      setState(() {
        selectedSourceItemId = itemId;
        selectedSourcePortId = portId;
      });
      showSnackBarMsg(context, 'Changed source port, now select a target port');
    }
  }

  void _handlePortConnection(String sourceItemId, String sourcePortId,
      String targetItemId, String targetPortId) {
    final alreadyExists = widget.wiresheet.links.any((link) =>
        link.sourceItemId == sourceItemId &&
        link.sourcePortId == sourcePortId &&
        link.targetItemId == targetItemId &&
        link.targetPortId == targetPortId);

    if (alreadyExists) {
      showSnackBarMsg(context, 'This connection already exists');
      return;
    }
    final sourceItem =
        widget.wiresheet.canvasItems.firstWhere((i) => i.id == sourceItemId);
    final targetItem =
        widget.wiresheet.canvasItems.firstWhere((i) => i.id == targetItemId);

    final sourcePort = sourceItem.getPort(sourcePortId);
    final targetPort = targetItem.getPort(targetPortId);

    if (sourcePort == null || targetPort == null) {
      showSnackBarMsg(context, 'Invalid port');
      return;
    }

    bool isCompatible = sourcePort.type == targetPort.type ||
        sourcePort.type == PortType.any ||
        targetPort.type == PortType.any;

    if (!isCompatible) {
      showSnackBarMsg(context, 'Incompatible port types');
      return;
    }

    final newLink = Link(
      id: const Uuid().v4(),
      sourceItemId: sourceItemId,
      sourcePortId: sourcePortId,
      targetItemId: targetItemId,
      targetPortId: targetPortId,
      type: LinkType.dataFlow,
    );

    ref.read(wiresheetsProvider.notifier).addLink(
          widget.wiresheet.id,
          newLink,
        );

    final sourceValue = _getPortValue(sourceItemId, sourcePortId);
    if (sourceValue != null) {
      _setPortValue(targetItemId, targetPortId, sourceValue);
    }
  }

  Widget _buildPropertiesPanel() {
    if (selectedItemIndex == null ||
        selectedItemIndex! >= widget.wiresheet.canvasItems.length) {
      return const SizedBox();
    }

    final item = widget.wiresheet.canvasItems[selectedItemIndex!];
    if (item.category == ComponentCategory.ui) {
      final uiType = item.properties['ui_type'] as String?;

      if (uiType == 'Button') {
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
                  'Button Properties',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Divider(),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Label',
                    border: OutlineInputBorder(),
                  ),
                  controller: TextEditingController(
                    text: _getPortValue(item.id!, 'label') as String? ??
                        'Click Me',
                  ),
                  onChanged: (value) {
                    _setPortValue(item.id!, 'label', value);
                  },
                ),
                getPositionDetail(
                    item, widget.wiresheet.id, selectedItemIndex!, ref),
                const SizedBox(height: 24),

                // Testing section
                Text(
                  'Test',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _handleButtonClick(item),
                  child: const Text('Trigger Button Click'),
                ),

                // Standard delete button and other controls
                const Spacer(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete Item'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(40),
                  ),
                  onPressed: () {
                    _deleteItem(selectedItemIndex!);
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
    }

    // Add custom properties for util components
    else if (item.category == ComponentCategory.util) {
      final utilType = item.properties['util_type'] as String?;

      if (utilType == 'Ramp') {
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
                  'Ramp Properties',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Divider(),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Min Value',
                    border: OutlineInputBorder(),
                  ),
                  controller: TextEditingController(
                    text: (item.properties['min'] ?? 0).toString(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final numValue = double.tryParse(value);
                    if (numValue != null) {
                      item.properties['min'] = numValue;
                      _setPortValue(item.id!, 'min', numValue);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Max Value',
                    border: OutlineInputBorder(),
                  ),
                  controller: TextEditingController(
                    text: (item.properties['max'] ?? 100).toString(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final numValue = double.tryParse(value);
                    if (numValue != null) {
                      item.properties['max'] = numValue;
                      _setPortValue(item.id!, 'max', numValue);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Period (seconds)',
                    border: OutlineInputBorder(),
                  ),
                  controller: TextEditingController(
                    text: (item.properties['period'] ?? 10.0).toString(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final numValue = double.tryParse(value);
                    if (numValue != null) {
                      item.properties['period'] = numValue;
                      _setPortValue(item.id!, 'period', numValue);
                    }
                  },
                ),
                getPositionDetail(
                    item, widget.wiresheet.id, selectedItemIndex!, ref),

                // Standard delete button and other controls
                const Spacer(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete Item'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(40),
                  ),
                  onPressed: () {
                    _deleteItem(selectedItemIndex!);
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
    }
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
                labelText: 'Label',
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(text: item.label),
              onChanged: (value) {
                final updatedItem = item.copyWith(label: value);
                ref.read(wiresheetsProvider.notifier).updateWiresheetItem(
                      widget.wiresheet.id,
                      selectedItemIndex!,
                      updatedItem,
                    );
              },
            ),
            getPositionDetail(
                item, widget.wiresheet.id, selectedItemIndex!, ref),
            const SizedBox(height: 24),
            if (item.ports.isNotEmpty) ...[
              Text(
                'Ports',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: item.ports.length,
                  itemBuilder: (context, index) {
                    final port = item.ports[index];
                    return ListTile(
                      title: Text(port.name),
                      subtitle: Text(
                        '${port.isInput ? "Input" : "Output"} - ${port.type.toString().split('.').last}',
                      ),
                      leading: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: getPortColor(port.type),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
            ],
            ElevatedButton.icon(
              icon: const Icon(Icons.delete),
              label: const Text('Delete Item'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(40),
              ),
              onPressed: () {
                _deleteItem(selectedItemIndex!);
              },
            ),
            const Spacer(),
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

  void _processMathComponent(
      CanvasItem targetItem, String targetPortId, value) {}

  void _processPointComponent(
      CanvasItem targetItem, String targetPortId, value) {}
}
