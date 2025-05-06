import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grms_designer/models/dragging_link_painter.dart';
import 'package:grms_designer/models/link.dart';
import 'package:uuid/uuid.dart';
import '../models/helvar_models/helvar_device.dart';
import '../models/wiresheet.dart';
import '../models/canvas_item.dart';
import '../models/widget_type.dart';
import '../providers/wiresheets_provider.dart';
import '../utils/general_ui.dart';
import '../widgets/grid_painter.dart';
import 'link_painter.dart';
import 'port_widget.dart';

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

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerMove: _handlePointerMove,
      onPointerDown: _handlePointerDown,
      child: Stack(
        children: [
          InteractiveViewer(
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

                    if (data is WidgetData) {
                      final newItem = CanvasItem(
                        type: data.type,
                        position: localPosition,
                        size: const Size(150, 100),
                        label:
                            'New Item ${widget.wiresheet.canvasItems.length + 1}',
                      );

                      ref.read(wiresheetsProvider.notifier).addWiresheetItem(
                            widget.wiresheet.id,
                            newItem,
                          );

                      setState(() {
                        selectedItemIndex =
                            widget.wiresheet.canvasItems.length - 1;
                        isPanelExpanded = true;
                      });

                      _updateCanvasSize();
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
          CustomPaint(
            size: Size(widget.wiresheet.canvasSize.width,
                widget.wiresheet.canvasSize.height),
            painter: LinkPainter(
              links: widget.wiresheet.links,
              items: widget.wiresheet.canvasItems,
              onLinkSelected: _handleLinkSelected,
            ),
          ),
          ...widget.wiresheet.canvasItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Positioned(
              left: item.position.dx,
              top: item.position.dy,
              child: _buildCanvasItemWithPorts(item, index),
            );
          }),
          if (isDraggingLink &&
              selectedSourceItemId != null &&
              linkDragEndPoint != null)
            CustomPaint(
              size: Size(widget.wiresheet.canvasSize.width,
                  widget.wiresheet.canvasSize.height),
              painter: DraggingLinkPainter(
                startItem: widget.wiresheet.canvasItems
                    .firstWhere((item) => item.id == selectedSourceItemId),
                startPortId: selectedSourcePortId!,
                endPoint: linkDragEndPoint!,
              ),
            ),
          if (selectedItemIndex != null && isPanelExpanded)
            _buildPropertiesPanel(),
        ],
      ),
    );
  }

  String? _findLinkAtPosition(Offset position) {
    // A function to check if a point is close to a bezier curve
    bool isPointNearCurve(Offset point, Offset start, Offset end,
        Offset control1, Offset control2, double threshold) {
      // Check multiple points along the curve
      for (int i = 0; i <= 20; i++) {
        final t = i / 20;
        final curvePoint = _evaluateCubic(start, control1, control2, end, t);
        final distance = (curvePoint - point).distance;

        if (distance < threshold) {
          return true;
        }
      }
      return false;
    }

    for (final link in widget.wiresheet.links) {
      // Find source and target items
      final sourceItem = widget.wiresheet.canvasItems
          .firstWhere((item) => item.id == link.sourceItemId);
      final targetItem = widget.wiresheet.canvasItems
          .firstWhere((item) => item.id == link.targetItemId);

      // Get port positions
      final sourcePort = sourceItem.getPort(link.sourcePortId);
      final targetPort = targetItem.getPort(link.targetPortId);

      final start = getPortPosition(sourceItem, sourcePort!, false);
      final end = getPortPosition(targetItem, targetPort!, true);

      final control1 = Offset(start.dx + (end.dx - start.dx) * 0.4, start.dy);
      final control2 = Offset(start.dx + (end.dx - start.dx) * 0.6, end.dy);

      if (isPointNearCurve(position, start, end, control1, control2, 10.0)) {
        return link.id;
      }
    }

    return null;
  }

  Offset _evaluateCubic(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final u = 1 - t;
    final tt = t * t;
    final uu = u * u;
    final uuu = uu * u;
    final ttt = tt * t;

    var result = p0 * uuu;
    result += p1 * 3 * uu * t;
    result += p2 * 3 * u * tt;
    result += p3 * ttt;

    return result;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (isDraggingLink) {
      setState(() {
        linkDragEndPoint = event.localPosition;
      });
    } else {
      final hoveredLink = _findLinkAtPosition(event.localPosition);
      if (hoveredLink != hoveredLinkId) {
        setState(() {
          hoveredLinkId = hoveredLink;
        });
      }
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    final clickedLinkId = _findLinkAtPosition(event.localPosition);
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

  void _handleItemDrop(Object data, Offset position) {
    if (data is WidgetData) {
      CanvasItem newItem;

      switch (data.category) {
        case ComponentCategory.logic:
          final logicType =
              data.additionalData['logicType'] as String? ?? 'AND';
          newItem = CanvasItem.createLogicItem(logicType, position);
          break;

        case ComponentCategory.treeview:
          if (data.additionalData.containsKey('device')) {
            final device = data.additionalData['device'] as HelvarDevice;
            newItem = CanvasItem.createDeviceItem(device, position);
          } else {
            newItem = CanvasItem(
              type: data.type,
              position: position,
              size: const Size(150, 100),
              id: const Uuid().v4(),
              label: data.additionalData['label'] as String? ?? 'Treeview Item',
              category: ComponentCategory.treeview,
              ports: [],
            );
          }
          break;

        case ComponentCategory.ui:
        default:
          newItem = CanvasItem(
            type: data.type,
            position: position,
            size: const Size(150, 100),
            id: const Uuid().v4(),
            label: 'New ${data.type.toString().split('.').last}',
            category: ComponentCategory.ui,
            ports: _createPortsForUiComponent(data.type),
          );
      }

      ref.read(wiresheetsProvider.notifier).addWiresheetItem(
            widget.wiresheet.id,
            newItem,
          );

      setState(() {
        selectedItemIndex = widget.wiresheet.canvasItems.length - 1;
        isPanelExpanded = true;
      });

      _updateCanvasSize();
    }
  }

  List<Port> _createPortsForUiComponent(WidgetType type) {
    final ports = <Port>[];

    switch (type) {
      case WidgetType.button:
        ports.add(Port(
          id: 'onClick',
          type: PortType.boolean,
          name: 'On Click',
          isInput: false,
        ));
        ports.add(Port(
          id: 'enabled',
          type: PortType.boolean,
          name: 'Enabled',
          isInput: true,
        ));
        break;

      case WidgetType.image:
        ports.add(Port(
          id: 'source',
          type: PortType.string,
          name: 'Source',
          isInput: true,
        ));
        ports.add(Port(
          id: 'loaded',
          type: PortType.boolean,
          name: 'Loaded',
          isInput: false,
        ));
        break;

      case WidgetType.text:
      default:
        ports.add(Port(
          id: 'content',
          type: PortType.string,
          name: 'Content',
          isInput: true,
        ));
    }

    return ports;
  }

  CanvasItem _createCanvasItemFromWidgetData(WidgetData data, Offset position) {
    // Generate a unique ID
    final id = const Uuid().v4();

    // Default size for items
    final size = const Size(150, 100);

    // Determine the component category based on dragging source context
    // (we could add a parameter to this method if needed)
    ComponentCategory category = ComponentCategory.ui;

    // Create appropriate ports based on widget type
    final ports = <Port>[];

    switch (data.type) {
      case WidgetType.button:
        // Add appropriate ports for a button
        ports.add(Port(
          id: 'text',
          type: PortType.string,
          name: 'Text',
          isInput: true,
        ));
        ports.add(Port(
          id: 'clicked',
          type: PortType.boolean,
          name: 'Clicked',
          isInput: false,
        ));
        break;

      case WidgetType.image:
        // Add appropriate ports for an image
        ports.add(Port(
          id: 'source',
          type: PortType.string,
          name: 'Source',
          isInput: true,
        ));
        ports.add(Port(
          id: 'loaded',
          type: PortType.boolean,
          name: 'Loaded',
          isInput: false,
        ));
        break;

      case WidgetType.text:
      default:
        // Add appropriate ports for text
        ports.add(Port(
          id: 'content',
          type: PortType.string,
          name: 'Content',
          isInput: true,
        ));
    }

    return CanvasItem(
      type: data.type,
      position: position,
      size: size,
      id: id,
      label: 'New ${data.type.toString().split('.').last}',
      ports: ports,
      category: category,
    );
  }

  Widget _buildCanvasItemWithPorts(CanvasItem item, int index) {
    final connectedPorts = <String>{};
    for (final link in widget.wiresheet.links) {
      if (link.sourceItemId == item.id) {
        connectedPorts.add(link.sourcePortId);
      }
      if (link.targetItemId == item.id) {
        connectedPorts.add(link.targetPortId);
      }
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildDraggableCanvasItem(item, index),

        ...item.ports
            .where((port) => port.isInput)
            .toList()
            .asMap()
            .entries
            .map((entry) {
          final port = entry.value;
          final idx = entry.key;
          final verticalSpacing = item.size.height /
              (item.ports.where((p) => p.isInput).length + 1);
          final verticalPosition = verticalSpacing * (idx + 1);

          return Positioned(
            left: -6, // Half the port width to make it stick out
            top: verticalPosition - 6, // Center the port vertically
            child: PortWidget(
              port: port,
              isInput: true,
              isConnected: connectedPorts.contains(port.id),
              onTap: () => _handlePortTap(item.id!, port.id, true),
            ),
          );
        }),

        // Add output ports on the right side
        ...item.ports
            .where((port) => !port.isInput)
            .toList()
            .asMap()
            .entries
            .map((entry) {
          final port = entry.value;
          final idx = entry.key;
          final verticalSpacing = item.size.height /
              (item.ports.where((p) => !p.isInput).length + 1);
          final verticalPosition = verticalSpacing * (idx + 1);

          return Positioned(
            right: -6, // Half the port width to make it stick out
            top: verticalPosition - 6, // Center the port vertically
            child: PortWidget(
              port: port,
              isInput: false,
              isConnected: connectedPorts.contains(port.id),
              onTap: () => _handlePortTap(item.id!, port.id, false),
            ),
          );
        }),

        // Optional: Add port labels for better visibility
        if (selectedItemIndex == index) ...[
          // Input port labels on hover/selection
          ...item.ports
              .where((port) => port.isInput)
              .toList()
              .asMap()
              .entries
              .map((entry) {
            final port = entry.value;
            final idx = entry.key;
            final verticalSpacing = item.size.height /
                (item.ports.where((p) => p.isInput).length + 1);
            final verticalPosition = verticalSpacing * (idx + 1);

            return Positioned(
              left: 12, // Position just inside the item
              top: verticalPosition - 9, // Align with port
              child: Text(
                port.name,
                style: const TextStyle(fontSize: 10),
              ),
            );
          }),

          // Output port labels on hover/selection
          ...item.ports
              .where((port) => !port.isInput)
              .toList()
              .asMap()
              .entries
              .map((entry) {
            final port = entry.value;
            final idx = entry.key;
            final verticalSpacing = item.size.height /
                (item.ports.where((p) => !p.isInput).length + 1);
            final verticalPosition = verticalSpacing * (idx + 1);

            return Positioned(
              right: 12, // Position just inside the item
              top: verticalPosition - 9, // Align with port
              child: Text(
                port.name,
                style: const TextStyle(fontSize: 10),
                textAlign: TextAlign.right,
              ),
            );
          }),
        ],
      ],
    );
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

  String _getItemLabel(String itemId) {
    try {
      final item =
          widget.wiresheet.canvasItems.firstWhere((i) => i.id == itemId);
      return item.label ?? 'Untitled Item';
    } catch (e) {
      return 'Unknown Item';
    }
  }

  void _deleteLink(String linkId) {
    ref.read(wiresheetsProvider.notifier).removeLink(
          widget.wiresheet.id,
          linkId,
        );
  }

  void _handlePortTap(String itemId, String portId, bool isInput) {
    if (isInput) {
      if (isDraggingLink &&
          selectedSourceItemId != null &&
          selectedSourcePortId != null) {
        if (selectedSourceItemId == itemId) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Cannot connect a component to itself')),
          );
          return;
        }

        final alreadyExists = widget.wiresheet.links.any((link) =>
            link.sourceItemId == selectedSourceItemId &&
            link.sourcePortId == selectedSourcePortId &&
            link.targetItemId == itemId &&
            link.targetPortId == portId);

        if (alreadyExists) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This connection already exists')),
          );
          setState(() {
            isDraggingLink = false;
            selectedSourceItemId = null;
            selectedSourcePortId = null;
            linkDragEndPoint = null;
          });
          return;
        }

        final sourceItem = widget.wiresheet.canvasItems
            .firstWhere((i) => i.id == selectedSourceItemId);
        final sourcePort = sourceItem.getPort(selectedSourcePortId!);

        final targetItem =
            widget.wiresheet.canvasItems.firstWhere((i) => i.id == itemId);
        final targetPort = targetItem.getPort(portId);

        bool isCompatible = true;
        if (sourcePort != null && targetPort != null) {
          isCompatible = sourcePort.type == targetPort.type ||
              sourcePort.type == PortType.any ||
              targetPort.type == PortType.any;
        }

        if (!isCompatible) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Incompatible port types')),
          );
          return;
        }

        final newLink = Link(
          id: const Uuid().v4(),
          sourceItemId: selectedSourceItemId!,
          sourcePortId: selectedSourcePortId!,
          targetItemId: itemId,
          targetPortId: portId,
          type: LinkType.dataFlow,
        );

        ref.read(wiresheetsProvider.notifier).addLink(
              widget.wiresheet.id,
              newLink,
            );

        setState(() {
          isDraggingLink = false;
          selectedSourceItemId = null;
          selectedSourcePortId = null;
          linkDragEndPoint = null;
        });
      }
    } else {
      if (isDraggingLink) {
        setState(() {
          isDraggingLink = false;
          selectedSourceItemId = null;
          selectedSourcePortId = null;
          linkDragEndPoint = null;
        });

        setState(() {
          isDraggingLink = true;
          selectedSourceItemId = itemId;
          selectedSourcePortId = portId;

          final item =
              widget.wiresheet.canvasItems.firstWhere((i) => i.id == itemId);
          final ports = item.ports.where((p) => !p.isInput).toList();
          final portIndex = ports.indexWhere((p) => p.id == portId);
          final portCount = ports.length;

          final verticalSpacing = item.size.height / (portCount + 1);
          final verticalPosition =
              item.position.dy + verticalSpacing * (portIndex + 1);

          linkDragEndPoint =
              Offset(item.position.dx + item.size.width + 20, verticalPosition);
        });
      } else {
        setState(() {
          isDraggingLink = true;
          selectedSourceItemId = itemId;
          selectedSourcePortId = portId;

          final item =
              widget.wiresheet.canvasItems.firstWhere((i) => i.id == itemId);
          final ports = item.ports.where((p) => !p.isInput).toList();
          final portIndex = ports.indexWhere((p) => p.id == portId);
          final portCount = ports.length;

          final verticalSpacing = item.size.height / (portCount + 1);
          final verticalPosition =
              item.position.dy + verticalSpacing * (portIndex + 1);

          linkDragEndPoint =
              Offset(item.position.dx + item.size.width + 20, verticalPosition);
        });
      }
    }
  }

  Widget _buildDraggableCanvasItem(CanvasItem item, int index) {
    // Determine an icon based on the item type and category
    IconData itemIcon;
    Color itemColor;

    switch (item.category) {
      case ComponentCategory.logic:
        // Choose icon based on logic type
        if (item.properties.containsKey('logic_type')) {
          final logicType = item.properties['logic_type'] as String;
          switch (logicType) {
            case 'AND':
              itemIcon = Icons.call_merge;
              break;
            case 'OR':
              itemIcon = Icons.call_split;
              break;
            case 'IF':
              itemIcon = Icons.compare_arrows;
              break;
            case 'ADD':
              itemIcon = Icons.add;
              break;
            case 'SUBTRACT':
              itemIcon = Icons.remove;
              break;
            default:
              itemIcon = Icons.account_tree;
          }
        } else {
          itemIcon = Icons.account_tree;
        }
        itemColor = Colors.blue;
        break;

      case ComponentCategory.treeview:
        // Choose icon based on device type
        if (item.properties.containsKey('device_type')) {
          final deviceType = item.properties['device_type'] as String;
          switch (deviceType) {
            case 'input':
              itemIcon = Icons.input;
              break;
            case 'output':
              itemIcon = Icons.lightbulb;
              break;
            case 'emergency':
              itemIcon = Icons.emergency;
              break;
            default:
              itemIcon = Icons.devices;
          }
        } else {
          itemIcon = Icons.devices;
        }
        itemColor = Colors.green;
        break;

      case ComponentCategory.ui:
      default:
        // Choose icon based on widget type
        switch (item.type) {
          case WidgetType.button:
            itemIcon = Icons.smart_button;
            break;
          case WidgetType.image:
            itemIcon = Icons.image;
            break;
          case WidgetType.text:
          default:
            itemIcon = Icons.text_fields;
        }
        itemColor = Colors.orange;
    }

    return Draggable<int>(
      data: index, // Pass the index of the item for identification
      feedback: Material(
        elevation: 4,
        color: Colors.transparent,
        child: Container(
          width: item.size.width,
          height: item.size.height,
          decoration: BoxDecoration(
            color: itemColor.withOpacity(0.8),
            border: Border.all(
              color: itemColor,
              width: 2.0,
            ),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(itemIcon, color: Colors.white),
                const SizedBox(height: 4),
                Text(
                  item.label ?? "Item $index",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: Container(
          width: item.size.width,
          height: item.size.height,
          decoration: BoxDecoration(
            color: Colors.grey,
            border: Border.all(
              color: Colors.grey,
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),
      onDragEnd: (details) {
        if (details.wasAccepted) {
          final RenderBox box = context.findRenderObject() as RenderBox;
          final localOffset = box.globalToLocal(details.offset);
          final updatedItem = item.copyWith(
            position: localOffset,
          );

          ref.read(wiresheetsProvider.notifier).updateWiresheetItem(
                widget.wiresheet.id,
                index,
                updatedItem,
              );
        }
      },
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedItemIndex = index;
            isPanelExpanded = true;
          });
        },
        child: Container(
          width: item.size.width,
          height: item.size.height,
          decoration: BoxDecoration(
            color: itemColor.withOpacity(0.1),
            border: Border.all(
              color: selectedItemIndex == index ? itemColor : Colors.grey,
              width: selectedItemIndex == index ? 2.0 : 1.0,
            ),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(itemIcon, color: itemColor),
                    const SizedBox(height: 4),
                    Text(
                      item.label ?? "Item $index",
                      style: TextStyle(
                        fontWeight: selectedItemIndex == index
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: itemColor,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: selectedItemIndex == index ? itemColor : Colors.grey,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4.0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPropertiesPanel() {
    if (selectedItemIndex == null ||
        selectedItemIndex! >= widget.wiresheet.canvasItems.length) {
      return const SizedBox();
    }

    final item = widget.wiresheet.canvasItems[selectedItemIndex!];

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
            const SizedBox(height: 16),
            DropdownButtonFormField<WidgetType>(
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              value: item.type,
              onChanged: (WidgetType? newValue) {
                if (newValue != null) {
                  final updatedItem = item.copyWith(type: newValue);
                  ref.read(wiresheetsProvider.notifier).updateWiresheetItem(
                        widget.wiresheet.id,
                        selectedItemIndex!,
                        updatedItem,
                      );
                }
              },
              items: WidgetType.values
                  .map<DropdownMenuItem<WidgetType>>((WidgetType type) {
                return DropdownMenuItem<WidgetType>(
                  value: type,
                  child: Text(type.toString().split('.').last),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'X Position',
                      border: OutlineInputBorder(),
                    ),
                    controller: TextEditingController(
                      text: item.position.dx.toStringAsFixed(0),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final dx = double.tryParse(value) ?? item.position.dx;
                      final updatedItem = item.copyWith(
                        position: Offset(dx, item.position.dy),
                      );
                      ref.read(wiresheetsProvider.notifier).updateWiresheetItem(
                            widget.wiresheet.id,
                            selectedItemIndex!,
                            updatedItem,
                          );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Y Position',
                      border: OutlineInputBorder(),
                    ),
                    controller: TextEditingController(
                      text: item.position.dy.toStringAsFixed(0),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final dy = double.tryParse(value) ?? item.position.dy;
                      final updatedItem = item.copyWith(
                        position: Offset(item.position.dx, dy),
                      );
                      ref.read(wiresheetsProvider.notifier).updateWiresheetItem(
                            widget.wiresheet.id,
                            selectedItemIndex!,
                            updatedItem,
                          );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Width',
                      border: OutlineInputBorder(),
                    ),
                    controller: TextEditingController(
                      text: item.size.width.toStringAsFixed(0),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final width = double.tryParse(value) ?? item.size.width;
                      final updatedItem = item.copyWith(
                        size: Size(width, item.size.height),
                      );
                      ref.read(wiresheetsProvider.notifier).updateWiresheetItem(
                            widget.wiresheet.id,
                            selectedItemIndex!,
                            updatedItem,
                          );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Height',
                      border: OutlineInputBorder(),
                    ),
                    controller: TextEditingController(
                      text: item.size.height.toStringAsFixed(0),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final height = double.tryParse(value) ?? item.size.height;
                      final updatedItem = item.copyWith(
                        size: Size(item.size.width, height),
                      );
                      ref.read(wiresheetsProvider.notifier).updateWiresheetItem(
                            widget.wiresheet.id,
                            selectedItemIndex!,
                            updatedItem,
                          );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete),
              label: const Text('Delete Item'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(40),
              ),
              onPressed: () {
                ref.read(wiresheetsProvider.notifier).removeWiresheetItem(
                      widget.wiresheet.id,
                      selectedItemIndex!,
                    );
                setState(() {
                  selectedItemIndex = null;
                  isPanelExpanded = false;
                });
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

  void _updateCanvasSize() {
    if (widget.wiresheet.canvasItems.isEmpty) return;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = 0;
    double maxY = 0;

    for (var item in widget.wiresheet.canvasItems) {
      final rightEdge = item.position.dx + item.size.width;
      final bottomEdge = item.position.dy + item.size.height;

      minX = minX > item.position.dx ? item.position.dx : minX;
      minY = minY > item.position.dy ? item.position.dy : minY;
      maxX = maxX < rightEdge ? rightEdge : maxX;
      maxY = maxY < bottomEdge ? bottomEdge : maxY;
    }

    const padding = 100.0;

    bool needsUpdate = false;
    Size newCanvasSize = widget.wiresheet.canvasSize;

    if (maxX > widget.wiresheet.canvasSize.width - padding) {
      double extraWidth = maxX - (widget.wiresheet.canvasSize.width - padding);
      newCanvasSize = Size(
          widget.wiresheet.canvasSize.width + extraWidth, newCanvasSize.height);
      needsUpdate = true;
    }

    if (maxY > widget.wiresheet.canvasSize.height - padding) {
      double extraHeight =
          maxY - (widget.wiresheet.canvasSize.height - padding);
      newCanvasSize = Size(
        newCanvasSize.width,
        widget.wiresheet.canvasSize.height + extraHeight,
      );
      needsUpdate = true;
    }

    if (needsUpdate) {
      ref.read(wiresheetsProvider.notifier).updateCanvasSize(
            widget.wiresheet.id,
            newCanvasSize,
          );
    }
  }
}
