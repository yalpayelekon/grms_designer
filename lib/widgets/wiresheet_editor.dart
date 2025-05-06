import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grms_designer/models/helvar_models/helvar_device.dart';
import 'package:uuid/uuid.dart';
import '../models/link.dart';
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
                      }
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
      ],
    );
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
    bool isPointNearCurve(Offset point, Offset start, Offset end,
        Offset control1, Offset control2, double threshold) {
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
      final sourceItem = widget.wiresheet.canvasItems
          .firstWhere((item) => item.id == link.sourceItemId);
      final targetItem = widget.wiresheet.canvasItems
          .firstWhere((item) => item.id == link.targetItemId);

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
            getPositionDetail(
                item, widget.wiresheet.id, selectedItemIndex!, ref),
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
}
