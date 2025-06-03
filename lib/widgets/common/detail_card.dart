import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DetailRow extends StatelessWidget {
  final String label;
  final String? value;
  final bool isEditable;
  final TextEditingController? controller;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType? keyboardType;
  final Widget? customValue;
  final IconData? trailingIcon;
  final double labelWidth;
  final bool showDivider;

  const DetailRow({
    super.key,
    required this.label,
    this.value,
    this.isEditable = false,
    this.controller,
    this.onSubmitted,
    this.onTap,
    this.inputFormatters,
    this.keyboardType,
    this.customValue,
    this.trailingIcon,
    this.labelWidth = 180,
    this.showDivider = false,
  }) : assert(
         (!isEditable && (value != null || customValue != null)) ||
             (isEditable && controller != null),
         'Either provide value/customValue for non-editable row, or controller for editable row',
       );

  @override
  Widget build(BuildContext context) {
    Widget rowContent = Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
            ),
          ),
          Expanded(child: _buildValueWidget()),
          if (trailingIcon != null) ...[
            const SizedBox(width: 8),
            Icon(trailingIcon, size: 13, color: Colors.grey[600]),
          ],
        ],
      ),
    );
    if (onTap != null) {
      rowContent = InkWell(onTap: onTap, child: rowContent);
    }

    return Column(
      children: [rowContent, if (showDivider) const Divider(height: 1)],
    );
  }

  Widget _buildValueWidget() {
    if (isEditable && controller != null) {
      return TextFormField(
        controller: controller,
        onFieldSubmitted: onSubmitted,
        inputFormatters: inputFormatters,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 12),
        decoration: const InputDecoration(
          isDense: true,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
      );
    }

    if (customValue != null) {
      return customValue!;
    }

    return Text(value ?? '', style: const TextStyle(fontSize: 12));
  }
}

class NavigationDetailRow extends DetailRow {
  const NavigationDetailRow({
    super.key,
    required super.label,
    required super.value,
    required super.onTap,
    super.labelWidth,
    super.showDivider,
  }) : super(trailingIcon: Icons.arrow_forward_ios);
}

class EditableDetailRow extends DetailRow {
  const EditableDetailRow({
    super.key,
    required super.label,
    required super.controller,
    super.onSubmitted,
    super.inputFormatters,
    super.keyboardType,
    super.labelWidth,
    super.showDivider,
  }) : super(isEditable: true);
}

class StatusDetailRow extends DetailRow {
  final Color? statusColor;
  final String statusText;

  StatusDetailRow({
    super.key,
    required super.label,
    required this.statusText,
    this.statusColor,
    super.labelWidth,
    super.showDivider,
  }) : super(
         customValue: Container(
           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
           decoration: BoxDecoration(
             color: statusColor?.withValues(alpha: 0.1 * 255),
             borderRadius: BorderRadius.circular(12),
             border: statusColor != null
                 ? Border.all(color: statusColor.withValues(alpha: 0.3 * 255))
                 : null,
           ),
           child: Text(
             statusText,
             style: TextStyle(
               fontSize: 12,
               fontWeight: FontWeight.w500,
               color: statusColor,
             ),
           ),
         ),
       );
}

class DetailRowsList extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  const DetailRowsList({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
