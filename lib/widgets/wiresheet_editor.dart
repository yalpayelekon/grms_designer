import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grms_designer/models/dragging_link_painter.dart';
import 'package:grms_designer/models/link.dart';
import 'package:uuid/uuid.dart';
import '../models/wiresheet.dart';
import '../models/canvas_item.dart';
import '../models/widget_type.dart';
import '../providers/wiresheets_provider.dart';
import '../widgets/grid_painter.dart';
import 'link_painter.dart';

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

  @override
  Widget build(BuildContext context) {
    return Stack(
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
                  final RenderBox box = context.findRenderObject() as RenderBox;
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
        CustomPaint(
          painter: LinkPainter(
            links: widget.wiresheet.links,
            items: widget.wiresheet.canvasItems,
            onLinkSelected: _handleLinkSelected,
          ),
          child: Container(),
        ),
        if (isDraggingLink &&
            selectedSourceItemId != null &&
            linkDragEndPoint != null)
          CustomPaint(
            painter: DraggingLinkPainter(
              startItem: widget.wiresheet.canvasItems
                  .firstWhere((item) => item.id == selectedSourceItemId),
              startPortId: selectedSourcePortId!,
              endPoint: linkDragEndPoint!,
            ),
            child: Container(),
          ),
      ],
    );
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (isDraggingLink) {
      setState(() {
        linkDragEndPoint = event.localPosition;
      });
    }
  }

  void _handleLinkSelected(String linkId) {
    // Show link properties panel or context menu
    final link = widget.wiresheet.links.firstWhere((l) => l.id == linkId);

    // You could show a dialog or update a properties panel here
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
      setState(() {
        isDraggingLink = true;
        selectedSourceItemId = itemId;
        selectedSourcePortId = portId;

        final item =
            widget.wiresheet.canvasItems.firstWhere((i) => i.id == itemId);
        final port = item.getPort(portId);
        if (port != null) {
          // This will need the _getPortPosition implementation
          // linkDragEndPoint = _getPortPosition(item, port, false);

          // For now, just set it to somewhere near the item
          linkDragEndPoint = Offset(item.position.dx + item.size.width + 10,
              item.position.dy + item.size.height / 2);
        }
      });
    }
  }

  Widget _buildDraggableCanvasItem(CanvasItem item, int index) {
    return Draggable<int>(
      data: index, // Pass the index of the item for identification
      feedback: Material(
        elevation: 4,
        color: Colors.transparent,
        child: Container(
          width: item.size.width,
          height: item.size.height,
          decoration: BoxDecoration(
            color: Colors.blue,
            border: Border.all(
              color: Colors.blue,
              width: 2.0,
            ),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Center(
            child: Text(
              item.label ?? "Item $index",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
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
            color: Colors.blue,
            border: Border.all(
              color: selectedItemIndex == index ? Colors.blue : Colors.grey,
              width: selectedItemIndex == index ? 2.0 : 1.0,
            ),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  item.label ?? "Item $index",
                  style: TextStyle(
                    fontWeight: selectedItemIndex == index
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color:
                        selectedItemIndex == index ? Colors.blue : Colors.grey,
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
    Offset newCanvasOffset = widget.wiresheet.canvasOffset;

    if (minX < padding) {
      double extraWidth = padding - minX;
      newCanvasSize = Size(
          widget.wiresheet.canvasSize.width + extraWidth, newCanvasSize.height);
      newCanvasOffset = Offset(
        widget.wiresheet.canvasOffset.dx - extraWidth,
        newCanvasOffset.dy,
      );
      final updatedItems = List<CanvasItem>.from(widget.wiresheet.canvasItems);
      for (int i = 0; i < updatedItems.length; i++) {
        final item = updatedItems[i];
        final updatedItem = item.copyWith(
          position: Offset(item.position.dx + extraWidth, item.position.dy),
        );
        ref.read(wiresheetsProvider.notifier).updateWiresheetItem(
              widget.wiresheet.id,
              i,
              updatedItem,
            );
      }

      needsUpdate = true;
    }

    if (minY < padding) {
      double extraHeight = padding - minY;
      newCanvasSize = Size(
        newCanvasSize.width,
        widget.wiresheet.canvasSize.height + extraHeight,
      );
      newCanvasOffset = Offset(
        newCanvasOffset.dx,
        widget.wiresheet.canvasOffset.dy - extraHeight,
      );
      final updatedItems = List<CanvasItem>.from(widget.wiresheet.canvasItems);
      for (int i = 0; i < updatedItems.length; i++) {
        final item = updatedItems[i];
        final updatedItem = item.copyWith(
          position: Offset(item.position.dx, item.position.dy + extraHeight),
        );
        ref.read(wiresheetsProvider.notifier).updateWiresheetItem(
              widget.wiresheet.id,
              i,
              updatedItem,
            );
      }

      needsUpdate = true;
    }

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

      ref.read(wiresheetsProvider.notifier).updateCanvasOffset(
            widget.wiresheet.id,
            newCanvasOffset,
          );
    }
  }
}
