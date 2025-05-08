import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/helvar_models/helvar_device.dart';
import '../models/link.dart';
import '../models/widget_type.dart';
import '../models/wiresheet.dart';
import '../models/canvas_item.dart';
import '../providers/wiresheets_provider.dart';
import '../utils/general_ui.dart';
import '../widgets/grid_painter.dart';
import 'link_painter.dart';
import '../models/dragging_link_painter.dart';

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
                        if (data.category! == ComponentCategory.logic) {
                          newItem = CanvasItem.createLogicItem(
                              additionalData["label"]!, localPosition);
                        } else if (data.category! == ComponentCategory.math) {
                          newItem = CanvasItem.createMathItem(
                              additionalData["label"]!, localPosition);
                        } else if (data.category! == ComponentCategory.point) {
                          newItem = CanvasItem.createPointItem(
                              additionalData["label"]!, localPosition);
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
    setState(() {
      selectedLinkId = null;
      hoveredLinkId = null;
    });
  }

  void _handlePortTap(String itemId, String portId, bool isInput) {
    //
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

  Widget _buildDraggableCanvasItem(CanvasItem item, int index) {
    final isSelected = selectedItemIndex == index;

    // Get the ports for display
    final inputPorts = item.ports.where((p) => p.isInput).toList();
    final outputPorts = item.ports.where((p) => !p.isInput).toList();

    return Stack(
      children: [
        Draggable<int>(
          data: index,
          feedback: Material(
            elevation: 4,
            color: Colors.transparent,
            child: Container(
              width: item.size.width,
              height: item.size.height,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.8),
                border: Border.all(
                  color: Colors.blue,
                  width: 2.0,
                ),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: _buildItemContents(item, inputPorts, outputPorts, true),
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
            onSecondaryTap: () {
              _showContextMenu(context, item, index);
            },
            child: Container(
              width: item.size.width + 33,
              height: item.size.height + 53,
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue.shade100 : Colors.white,
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey,
                  width: isSelected ? 2.0 : 1.0,
                ),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: _buildItemContents(item, inputPorts, outputPorts, false),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemContents(CanvasItem item, List<Port> inputPorts,
      List<Port> outputPorts, bool isFeedback) {
    const double headerHeight = 24.0;
    const double rowHeight = 22.0;

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

        // Divider between header and ports
        const Divider(height: 1, thickness: 1),

        // Ports section
        Expanded(
          child: Row(
            children: [
              // Input ports (left side)
              if (inputPorts.isNotEmpty)
                Container(
                  width: item.size.width * 0.5 - 1,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                  ),
                  child: ListView.builder(
                    itemCount: inputPorts.length,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, i) {
                      return _buildPortRow(
                        item,
                        inputPorts[i],
                        true,
                        rowHeight,
                        isFeedback,
                      );
                    },
                  ),
                ),

              // Vertical divider between input and output ports
              Container(
                width: 2,
                color: Colors.grey.withOpacity(0.3),
              ),

              // Output ports (right side)
              if (outputPorts.isNotEmpty)
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.05),
                    ),
                    child: ListView.builder(
                      itemCount: outputPorts.length,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, i) {
                        return _buildPortRow(
                          item,
                          outputPorts[i],
                          false,
                          rowHeight,
                          isFeedback,
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),

        Positioned(
          right: 0,
          bottom: 0,
          child: GestureDetector(
            onPanUpdate: (details) {
              if (isFeedback) return;

              final newWidth = item.size.width + details.delta.dx;
              final newHeight = item.size.height + details.delta.dy;
              if (newWidth >= 80 && newHeight >= 60) {
                final updatedItem = item.copyWith(
                  size: Size(newWidth, newHeight),
                );
                ref.read(wiresheetsProvider.notifier).updateWiresheetItem(
                      widget.wiresheet.id,
                      selectedItemIndex!,
                      updatedItem,
                    );
              }
            },
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: isFeedback
                    ? Colors.blue.withOpacity(0.5)
                    : Colors.grey.shade300,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4.0),
                ),
              ),
              child: const Icon(
                Icons.drag_handle,
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
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
  }

  void _copyItem(CanvasItem item) {
    final newItem = item.copyWith(
      id: const Uuid().v4(),
      position: Offset(item.position.dx + 20, item.position.dy + 20),
      label: '${item.label} (Copy)',
    );

    ref.read(wiresheetsProvider.notifier).addWiresheetItem(
          widget.wiresheet.id,
          newItem,
        );

    updateCanvasSize(widget.wiresheet, ref);
  }

  void _editItem(CanvasItem item, int index) {
    TextEditingController labelController =
        TextEditingController(text: item.label);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: labelController,
                  decoration: const InputDecoration(
                    labelText: 'Label',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
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

  Widget _buildPortRow(CanvasItem item, Port port, bool isInput, double height,
      bool isFeedback) {
    return DragTarget<Map<String, dynamic>>(
      onAccept: (data) {
        if (isInput && !isFeedback) {
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
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: getPortColor(port.type),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showContextMenu(BuildContext context, CanvasItem item, int index) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;

    final buttonPosition = button.localToGlobal(
      Offset(item.position.dx + item.size.width / 2, item.position.dy),
      ancestor: overlay,
    );

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        buttonPosition.dx,
        buttonPosition.dy,
        buttonPosition.dx + 1,
        buttonPosition.dy + 1,
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
          _copyItem(item);
          break;
        case 'edit':
          _editItem(item, index);
          break;
        case 'delete':
          _deleteItem(index);
          break;
      }
    });
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
}
