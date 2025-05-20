import 'package:flutter/material.dart';
import '../models/component.dart';
import '../models/port.dart';
import '../models/port_type.dart';
import 'utils.dart';

class SlotDragInfo {
  final String componentId;
  final int slotIndex;

  SlotDragInfo(this.componentId, this.slotIndex);
}

class ComponentWidget extends StatefulWidget {
  final Component component;
  final GlobalKey widgetKey;
  final Offset position;
  final bool isSelected;
  final double width;
  final double height;
  final Function(String, int, dynamic) onValueChanged;
  final Function(SlotDragInfo) onSlotDragStarted;
  final Function(SlotDragInfo) onSlotDragAccepted;
  final Function(String, double) onWidthChanged;

  const ComponentWidget({
    super.key,
    required this.component,
    required this.isSelected,
    required this.widgetKey,
    required this.position,
    required this.width,
    required this.height,
    required this.onValueChanged,
    required this.onSlotDragStarted,
    required this.onSlotDragAccepted,
    required this.onWidthChanged,
  });

  @override
  State<ComponentWidget> createState() => _ComponentWidgetState();
}

class _ComponentWidgetState extends State<ComponentWidget> {
  static const double itemExternalPadding = 4.0;
  static const double itemTitleSectionHeight = 22.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: widget.widgetKey,
      padding: const EdgeInsets.all(itemExternalPadding),
      decoration: BoxDecoration(
        color: getComponentColor(widget.component),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 3,
            offset: const Offset(1, 2),
          ),
        ],
        border: Border.all(
          color: widget.isSelected ? Colors.indigo : Colors.transparent,
          width: widget.isSelected ? 1.5 : 0.3,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleSection(),
          const SizedBox(height: 1),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: widget.width,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black.withOpacity(0.25)),
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.component.properties.isNotEmpty)
                      ..._buildSectionHeader("Properties"),
                    ...widget.component.properties
                        .map((property) => _buildPropertyRow(property)),
                    if (widget.component.actions.isNotEmpty)
                      ..._buildSectionHeader("Actions"),
                    ...widget.component.actions
                        .map((action) => _buildActionRow(action)),
                    if (widget.component.topics.isNotEmpty)
                      ..._buildSectionHeader("Topics"),
                    ...widget.component.topics
                        .map((topic) => _buildTopicRow(topic)),
                  ],
                ),
              ),
              _buildResizeHandle(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return SizedBox(
      height: itemTitleSectionHeight,
      width: widget.width,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              widget.component.id,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            margin: const EdgeInsets.only(left: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Colors.black45, width: 0.5),
            ),
            child: Text(
              getComponentSymbol(widget.component),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: getComponentTextColor(widget.component),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResizeHandle() {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        double newWidth = widget.width + details.delta.dx;
        if (newWidth >= 80.0) {
          widget.onWidthChanged(widget.component.id, newWidth);
        }
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeLeftRight,
        child: Container(
          width: 6.0,
          height: widget.height,
          color: Colors.transparent,
          child: Center(
            child: Container(
              width: 2.0,
              height: 16.0,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.7),
                borderRadius: BorderRadius.circular(1.0),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSectionHeader(String title) {
    return [
      Container(
        color: Colors.grey.shade200,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 9,
            color: Colors.grey.shade800,
          ),
        ),
      ),
    ];
  }

  Widget _buildPropertyRow(Property property) {
    final isInput = property.isInput;
    final label = property.name;

    return DragTarget<SlotDragInfo>(
      onAcceptWithDetails: (DragTargetDetails<SlotDragInfo> details) {
        widget.onSlotDragAccepted(
            SlotDragInfo(widget.component.id, property.index));
      },
      builder: (context, candidateData, rejectedData) {
        return LongPressDraggable<SlotDragInfo>(
          data: SlotDragInfo(widget.component.id, property.index),
          feedback: Material(
            elevation: 3.0,
            color: Colors.transparent,
            child: Container(
              height: rowHeight,
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.2),
                border: Border.all(
                  color: Colors.indigo,
                  width: 1.0,
                ),
                borderRadius: BorderRadius.circular(2.0),
              ),
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.indigo,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          onDragStarted: () {
            widget.onSlotDragStarted(
                SlotDragInfo(widget.component.id, property.index));
          },
          child: Container(
            height: rowHeight,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            decoration: BoxDecoration(
              color: (candidateData.isNotEmpty)
                  ? Colors.lightBlue.withOpacity(0.3)
                  : null,
              border: Border(
                bottom: BorderSide(
                  color: Colors.black.withOpacity(0.15),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isInput ? Icons.arrow_back : Icons.arrow_forward,
                      size: 12,
                      color: Colors.indigo.withOpacity(0.6),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.black.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(width: 3),
                    buildTypeIndicator(property.type),
                  ],
                ),
                _buildPropertyValueDisplay(property),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionRow(ActionSlot action) {
    final label = action.name;

    return DragTarget<SlotDragInfo>(
      onAcceptWithDetails: (DragTargetDetails<SlotDragInfo> details) {
        widget.onSlotDragAccepted(
            SlotDragInfo(widget.component.id, action.index));
      },
      builder: (context, candidateData, rejectedData) {
        return LongPressDraggable<SlotDragInfo>(
          data: SlotDragInfo(widget.component.id, action.index),
          feedback: Material(
            elevation: 3.0,
            color: Colors.transparent,
            child: Container(
              height: rowHeight,
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                border: Border.all(
                  color: Colors.amber.shade800,
                  width: 1.0,
                ),
                borderRadius: BorderRadius.circular(2.0),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.amber.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          onDragStarted: () {
            widget.onSlotDragStarted(
                SlotDragInfo(widget.component.id, action.index));
          },
          child: Container(
            height: rowHeight,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            decoration: BoxDecoration(
              color: (candidateData.isNotEmpty)
                  ? Colors.amber.withOpacity(0.2)
                  : null,
              border: Border(
                bottom: BorderSide(
                  color: Colors.black.withOpacity(0.15),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.flash_on,
                      size: 12,
                      color: Colors.amber.shade800,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.black.withOpacity(0.8),
                      ),
                    ),
                    if (action.parameterType != null) ...[
                      const SizedBox(width: 3),
                      buildTypeIndicator(action.parameterType!),
                    ],
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.play_arrow,
                      size: 12, color: Colors.amber.shade800),
                  constraints:
                      const BoxConstraints.tightFor(width: 20, height: 20),
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    widget.onValueChanged(
                        widget.component.id, action.index, null);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopicRow(Topic topic) {
    final label = topic.name;

    return DragTarget<SlotDragInfo>(
      onAcceptWithDetails: (DragTargetDetails<SlotDragInfo> details) {
        widget
            .onSlotDragAccepted(SlotDragInfo(widget.component.id, topic.index));
      },
      builder: (context, candidateData, rejectedData) {
        return LongPressDraggable<SlotDragInfo>(
          data: SlotDragInfo(widget.component.id, topic.index),
          feedback: Material(
            elevation: 3.0,
            color: Colors.transparent,
            child: Container(
              height: rowHeight,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                border: Border.all(
                  color: Colors.green.shade800,
                  width: 1.0,
                ),
                borderRadius: BorderRadius.circular(2.0),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          onDragStarted: () {
            widget.onSlotDragStarted(
                SlotDragInfo(widget.component.id, topic.index));
          },
          child: Container(
            height: rowHeight,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            decoration: BoxDecoration(
              color: (candidateData.isNotEmpty)
                  ? Colors.green.withOpacity(0.2)
                  : null,
              border: Border(
                bottom: BorderSide(
                  color: Colors.black.withOpacity(0.15),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.volume_up,
                      size: 12,
                      color: Colors.green.shade800,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.black.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(width: 3),
                    buildTypeIndicator(topic.eventType),
                  ],
                ),
                if (topic.lastEvent != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: Text(
                      _formatEventValue(topic.lastEvent),
                      style: TextStyle(
                        fontSize: 8,
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatEventValue(dynamic value) {
    if (value == null) return "null";
    if (value is bool) return value ? "T" : "F";
    if (value is num) return value.toStringAsFixed(1);
    if (value is String) {
      return '"${value.length > 4 ? '${value.substring(0, 4)}...' : value}"';
    }
    return value.toString();
  }

  Widget _buildPropertyValueDisplay(Property property) {
    Component component = widget.component;
    bool canEdit =
        !property.isInput && component.inputConnections[property.index] == null;

    switch (property.type.type) {
      case PortType.BOOLEAN:
        return GestureDetector(
          onTap: canEdit
              ? () {
                  widget.onValueChanged(widget.component.id, property.index,
                      !(property.value as bool));
                }
              : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 14,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  color:
                      property.value as bool ? Colors.green : Colors.red[300],
                  border: Border.all(
                    color: Colors.black45,
                    width: 0.5,
                  ),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 150),
                  alignment: property.value as bool
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: Colors.black45,
                        width: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 3),
              Text(
                property.value as bool ? 'T' : 'F',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: property.value as bool
                      ? Colors.green[800]
                      : Colors.red[800],
                ),
              ),
            ],
          ),
        );

      case PortType.NUMERIC:
        return Padding(
          padding: const EdgeInsets.only(right: 6.0),
          child: Text(
            (property.value as num).toStringAsFixed(1),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.teal[800],
            ),
          ),
        );

      case PortType.STRING:
        return Container(
          width: 50,
          padding: const EdgeInsets.only(right: 6.0),
          child: Tooltip(
            message: property.value as String,
            child: Text(
              '"${(property.value as String).length > 4 ? '${(property.value as String).substring(0, 4)}...' : property.value as String}"',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.orange[800],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        );

      case PortType.ANY:
        if (property.value is bool) {
          return Text(
            property.value as bool ? 'true' : 'false',
            style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: Colors.purple[800]),
          );
        } else if (property.value is num) {
          return Text(
            (property.value as num).toStringAsFixed(1),
            style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: Colors.purple[800]),
          );
        } else if (property.value is String) {
          return Text(
            '"${(property.value as String).length > 6 ? '${(property.value as String).substring(0, 6)}...' : property.value as String}"',
            style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: Colors.purple[800]),
          );
        } else {
          return Text(
            "null",
            style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: Colors.purple[800]),
          );
        }
    }
    return const SizedBox();
  }
}
