import 'package:flutter/material.dart';
import 'package:grms_designer/widgets/common/detail_card.dart';

class ExpandableListItem extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final Color? leadingIconColor;
  final List<Widget> detailRows;
  final List<Widget> children;
  final bool initiallyExpanded;
  final bool showDelete;
  final bool showAdd;
  final VoidCallback? onDelete;
  final VoidCallback? onAdd;
  final VoidCallback? onTap;
  final List<Widget>? customTrailingActions;
  final int indentLevel;

  const ExpandableListItem({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.leadingIconColor,
    this.detailRows = const [],
    this.children = const [],
    this.initiallyExpanded = false,
    this.showDelete = false,
    this.showAdd = false,
    this.onDelete,
    this.onAdd,
    this.onTap,
    this.customTrailingActions,
    this.indentLevel = 0,
  });

  @override
  ExpandableListItemState createState() => ExpandableListItemState();
}

class ExpandableListItemState extends State<ExpandableListItem>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    if (_isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasExpandableContent =
        widget.detailRows.isNotEmpty || widget.children.isNotEmpty;
    final leftPadding = widget.indentLevel * 20.0;

    return Column(
      children: [
        InkWell(
          onTap: hasExpandableContent ? _toggleExpanded : widget.onTap,
          child: Padding(
            padding: EdgeInsets.only(
              left: leftPadding + 16.0,
              right: 8.0,
              top: 12.0,
              bottom: 12.0,
            ),
            child: Row(
              children: [
                if (hasExpandableContent) ...[
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                ],
                if (widget.leadingIcon != null) ...[
                  Icon(
                    widget.leadingIcon,
                    size: 20,
                    color: widget.leadingIconColor ?? Colors.blue,
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.customTrailingActions != null)
                  ...widget.customTrailingActions!,
                if (widget.showAdd) ...[
                  IconButton(
                    icon: const Icon(Icons.add, size: 18),
                    onPressed: widget.onAdd,
                    tooltip: 'Add',
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                if (widget.showDelete) ...[
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18),
                    onPressed: widget.onDelete,
                    tooltip: 'Delete',
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    color: Colors.red[600],
                  ),
                ],
              ],
            ),
          ),
        ),
        if (hasExpandableContent)
          SizeTransition(
            sizeFactor: _animation,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.only(left: leftPadding + 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.detailRows.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(children: widget.detailRows),
                    ),
                  ],
                  if (widget.children.isNotEmpty) ...[
                    if (widget.detailRows.isNotEmpty) const SizedBox(height: 8),
                    ...widget.children,
                  ],
                ],
              ),
            ),
          ),
        if (!_isExpanded) Divider(height: 1, indent: leftPadding + 16.0),
      ],
    );
  }
}

class SimpleExpandableItem extends ExpandableListItem {
  SimpleExpandableItem({
    super.key,
    required super.title,
    super.subtitle,
    super.leadingIcon,
    super.leadingIconColor,
    required List<InfoItem> infoItems,
    super.children,
    super.initiallyExpanded,
    super.showDelete,
    super.showAdd,
    super.onDelete,
    super.onAdd,
    super.onTap,
    super.indentLevel,
  }) : super(
         detailRows: infoItems
             .map(
               (item) => DetailRow(
                 label: item.label,
                 value: item.value,
                 customValue: item.valueWidget,
                 labelWidth: 120,
                 showDivider: true,
               ),
             )
             .toList(),
       );
}

class InfoItem {
  final String label;
  final String? value;
  final Widget? valueWidget;

  const InfoItem({required this.label, this.value, this.valueWidget})
    : assert(
        value != null || valueWidget != null,
        'Either value or valueWidget must be provided',
      );

  InfoItem.text({required this.label, required String this.value})
    : valueWidget = null;

  InfoItem.widget({required this.label, required Widget this.valueWidget})
    : value = null;
}

class ExpandableListView extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final bool addSeparators;

  const ExpandableListView({
    super.key,
    required this.children,
    this.padding,
    this.addSeparators = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: padding,
      children: addSeparators ? _addSeparators(children) : children,
    );
  }

  List<Widget> _addSeparators(List<Widget> children) {
    if (children.isEmpty) return children;

    final result = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      result.add(children[i]);
      if (i < children.length - 1) {
        result.add(const Divider(height: 8));
      }
    }
    return result;
  }
}
