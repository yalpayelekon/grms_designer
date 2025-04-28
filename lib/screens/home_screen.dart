import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_simple_treeview/flutter_simple_treeview.dart';
import 'settings_screen.dart';
import 'canvas_item.dart';
import 'widget_type.dart';
import 'grid_painter.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends ConsumerState<HomeScreen> {
  List<CanvasItem> canvasItems = [];
  int? selectedItemIndex;
  bool isPanelExpanded = false;
  Size canvasSize = const Size(2000, 2000); // Initial canvas size
  Offset canvasOffset = const Offset(0, 0); // Canvas position within the view

  double scale = 1.0;
  Offset viewportOffset = const Offset(0, 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HelvarNet Manager'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Row(
        children: [
          Container(
            width: 300,
            color: Colors.grey[300],
            child: TreeView(nodes: [
              TreeNode(
                content: const Text("Project"),
                children: [
                  TreeNode(content: const Text("Settings")),
                  TreeNode(
                    content: const Text("Files"),
                    children: [
                      TreeNode(content: const Text("Images")),
                      TreeNode(content: const Text("Icons")),
                    ],
                  ),
                ],
              ),
              TreeNode(
                content: const Text("Workgroups"),
                children: [
                  TreeNode(content: const Text("Groups")),
                  TreeNode(content: const Text("Routers")),
                  TreeNode(
                    content: ElevatedButton.icon(
                      label: const Text('Dynamic canvas'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const Text("Workgroups will be added")),
                        );
                      },
                    ),
                    children: [
                      TreeNode(
                        content: _buildDraggable(
                            'Text', Icons.text_fields, WidgetType.text),
                      ),
                    ],
                  ),
                ],
              ),
            ]),
          ),
          Expanded(
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
                  DragTarget<WidgetData>(
                    onAcceptWithDetails: (details) {
                      final widgetData = details.data;
                      final globalPosition = details.offset;
                      final RenderBox box =
                          context.findRenderObject() as RenderBox;
                      final localPosition = box.globalToLocal(globalPosition);

                      setState(() {
                        canvasItems.add(
                          CanvasItem(
                            type: widgetData.type, // Use data from details
                            position:
                                localPosition, // Use calculated local position
                            size: const Size(150, 100), // Default size
                          ),
                        );
                        selectedItemIndex = canvasItems.length - 1;
                        isPanelExpanded = true; // Show properties panel
                        _updateCanvasSize();
                      });
                    },
                    builder: (context, candidateData, rejectedData) {
                      return Stack(
                        children: [
                          // Background
                          Container(
                            width: canvasSize.width,
                            height: canvasSize.height,
                            color: Colors.grey[50],
                            child: Center(
                              child: Text(
                                canvasItems.isEmpty
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
                            width: canvasSize.width,
                            height: canvasSize.height,
                            child: CustomPaint(
                              painter: GridPainter(),
                              child: Container(),
                            ),
                          ),
                          ...canvasItems.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            return Positioned(
                              left: item.position.dx,
                              top: item.position.dy,
                              child: Text("selected widget:$index"),
                            );
                          }),
                        ],
                      );
                    },
                  ),
                  if (selectedItemIndex != null && isPanelExpanded)
                    const Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      width: 250,
                      child: Text("selected widget details"),
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
                            isPanelExpanded
                                ? Icons.arrow_forward
                                : Icons.arrow_back,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggable(String label, IconData icon, WidgetType type) {
    return Draggable<WidgetData>(
      data: WidgetData(type: type),
      feedback: Material(
        elevation: 4.0,
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [Icon(icon), const SizedBox(width: 8.0), Text(label)],
          ),
        ),
      ),
      childWhenDragging: Row(
        children: [
          Icon(icon, color: Colors.grey[600]),
          const SizedBox(width: 8.0),
          Text(label, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
      child: Row(
        children: [Icon(icon), const SizedBox(width: 8.0), Text(label)],
      ),
    );
  }

  void _updateCanvasSize() {
    if (canvasItems.isEmpty) return;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = 0;
    double maxY = 0;

    for (var item in canvasItems) {
      final rightEdge = item.position.dx + item.size.width;
      final bottomEdge = item.position.dy + item.size.height;

      minX = minX > item.position.dx ? item.position.dx : minX;
      minY = minY > item.position.dy ? item.position.dy : minY;
      maxX = maxX < rightEdge ? rightEdge : maxX;
      maxY = maxY < bottomEdge ? bottomEdge : maxY;
    }

    const padding = 100.0;

    bool needsUpdate = false;
    Size newCanvasSize = canvasSize;
    Offset newCanvasOffset = canvasOffset;

    if (minX < padding) {
      double extraWidth = padding - minX;
      newCanvasSize = Size(canvasSize.width + extraWidth, newCanvasSize.height);
      newCanvasOffset = Offset(
        canvasOffset.dx - extraWidth,
        newCanvasOffset.dy,
      );

      for (var item in canvasItems) {
        item.position = Offset(item.position.dx + extraWidth, item.position.dy);
      }

      needsUpdate = true;
    }

    if (minY < padding) {
      double extraHeight = padding - minY;
      newCanvasSize = Size(
        newCanvasSize.width,
        canvasSize.height + extraHeight,
      );
      newCanvasOffset = Offset(
        newCanvasOffset.dx,
        canvasOffset.dy - extraHeight,
      );

      for (var item in canvasItems) {
        item.position = Offset(
          item.position.dx,
          item.position.dy + extraHeight,
        );
      }

      needsUpdate = true;
    }

    if (maxX > canvasSize.width - padding) {
      double extraWidth = maxX - (canvasSize.width - padding);
      newCanvasSize = Size(canvasSize.width + extraWidth, newCanvasSize.height);
      needsUpdate = true;
    }

    if (maxY > canvasSize.height - padding) {
      double extraHeight = maxY - (canvasSize.height - padding);
      newCanvasSize = Size(
        newCanvasSize.width,
        canvasSize.height + extraHeight,
      );
      needsUpdate = true;
    }

    if (needsUpdate) {
      setState(() {
        canvasSize = newCanvasSize;
        canvasOffset = newCanvasOffset;
      });
    }
  }
}
