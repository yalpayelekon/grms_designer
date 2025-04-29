import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wiresheet.dart';
import '../models/canvas_item.dart';
import '../models/widget_type.dart';
import '../providers/wiresheets_provider.dart';
import '../widgets/grid_painter.dart';

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
              DragTarget<WidgetData>(
                onAcceptWithDetails: (details) {
                  final widgetData = details.data;
                  final globalPosition = details.offset;
                  final RenderBox box = context.findRenderObject() as RenderBox;
                  final localPosition = box.globalToLocal(globalPosition);

                  final newItem = CanvasItem(
                    type: widgetData.type,
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
                    selectedItemIndex = widget.wiresheet.canvasItems.length - 1;
                    isPanelExpanded = true;
                  });

                  _updateCanvasSize();
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
                                color: Colors.blue.withOpacity(0.2),
                                border: Border.all(
                                  color: selectedItemIndex == index
                                      ? Colors.blue
                                      : Colors.grey,
                                  width: selectedItemIndex == index ? 2.0 : 1.0,
                                ),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: Center(
                                child: Text(
                                  item.label ?? "Item $index",
                                  style: TextStyle(
                                    fontWeight: selectedItemIndex == index
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ),
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

            // Label
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

            // Type
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

            // Position
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

            // Size
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

            // Delete button
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

            // Spacer to push content to the top
            const Spacer(),

            // Close panel button
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

      // Update all items' positions
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

      // Update all items' positions
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
