import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A unified row component for detail screens in Niagara style
/// Simple label-value pairs with optional editing and navigation
class DetailRow extends StatelessWidget {
  /// The label text displayed on the left
  final String label;

  /// The value text (used when not editable)
  final String? value;

  /// Whether this row is editable
  final bool isEditable;

  /// Controller for editable text field
  final TextEditingController? controller;

  /// Called when the value is submitted (for editable rows)
  final ValueChanged<String>? onSubmitted;

  /// Called when the row is tapped (for navigation)
  final VoidCallback? onTap;

  /// Input formatters for editable text field
  final List<TextInputFormatter>? inputFormatters;

  /// Keyboard type for editable text field
  final TextInputType? keyboardType;

  /// Custom widget to display instead of text value
  final Widget? customValue;

  /// Icon to show on the right (typically for navigation)
  final IconData? trailingIcon;

  /// Width of the label column (defaults to 180)
  final double labelWidth;

  /// Whether to show a divider below this row
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
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Label
          SizedBox(
            width: labelWidth,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),

          // Value area
          Expanded(child: _buildValueWidget()),

          // Trailing icon
          if (trailingIcon != null) ...[
            const SizedBox(width: 8),
            Icon(trailingIcon, size: 16, color: Colors.grey[600]),
          ],
        ],
      ),
    );

    // Wrap with InkWell if tappable
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
        style: const TextStyle(fontSize: 14),
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

    return Text(value ?? '', style: const TextStyle(fontSize: 14));
  }
}

/// A specialized DetailRow for navigation items
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

/// A specialized DetailRow for editable items
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

/// A specialized DetailRow for status display with colored indicators
class StatusDetailRow extends DetailRow {
  /// The status color
  final Color? statusColor;

  /// The status text
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

/// A widget that contains multiple DetailRows in a simple column layout
class DetailRowsList extends StatelessWidget {
  /// List of DetailRow widgets
  final List<Widget> children;

  /// Padding around the entire list
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
