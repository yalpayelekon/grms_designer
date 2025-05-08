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
    const rowHeight = 20.0; // Fixed height for each row

    return Stack(
      children: [
        // fill in here or modify
      ],
    );
  }

  void _showContextMenu(
      BuildContext context, Offset position, CanvasItem item, int index) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(position, position + const Offset(1, 1)),
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

  void _copyItem(CanvasItem item) {
    // Create a copy of the item with a new position and ID
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
  }

  void _editItem(BuildContext context, CanvasItem item, int index) {
    TextEditingController labelController =
        TextEditingController(text: item.label);
    TextEditingController rowCountController =
        TextEditingController(text: item.rowCount.toString());

    // Don't allow editing row count for certain item types
    final bool isRowCountEditable = !((item.properties.containsKey(
            'device_type')) || // HelvarDevice items have fixed row count
        (item.category == ComponentCategory.logic &&
            item.properties.containsKey('logic_type')) ||
        (item.category == ComponentCategory.math &&
            item.properties.containsKey('operation')));

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
              if (isRowCountEditable) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: rowCountController,
                  decoration: const InputDecoration(
                    labelText: 'Number of Rows',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
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
                  rowCount: isRowCountEditable
                      ? int.tryParse(rowCountController.text) ?? item.rowCount
                      : item.rowCount,
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
    final itemId = widget.wiresheet.canvasItems[index].id;
    final affectedLinks = widget.wiresheet.links
        .where((link) =>
            link.sourceItemId == itemId || link.targetItemId == itemId)
        .toList();

    for (final link in affectedLinks) {
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
