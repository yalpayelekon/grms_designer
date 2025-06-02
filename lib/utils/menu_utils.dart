import 'package:flutter/material.dart';
import '../niagara/controllers/clipboard_manager.dart';

List<PopupMenuEntry<String>> canvasMenuOptions(
  ClipboardManager clipboardManager,
) {
  return [
    PopupMenuItem(
      value: 'paste',
      enabled: !clipboardManager.isEmpty,
      child: Row(
        children: [
          Icon(
            Icons.content_paste,
            size: 18,
            color: !clipboardManager.isEmpty ? null : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            'Paste',
            style: TextStyle(
              color: !clipboardManager.isEmpty ? null : Colors.grey,
            ),
          ),
        ],
      ),
    ),
    PopupMenuItem(
      value: 'paste-special',
      enabled: !clipboardManager.isEmpty,
      child: Row(
        children: [
          Icon(
            Icons.copy_all,
            size: 18,
            color: !clipboardManager.isEmpty ? null : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            'Paste Special...',
            style: TextStyle(
              color: !clipboardManager.isEmpty ? null : Colors.grey,
            ),
          ),
        ],
      ),
    ),
    const PopupMenuItem(
      value: 'add-component',
      child: Row(
        children: [
          Icon(Icons.add_box, size: 18),
          SizedBox(width: 8),
          Text('Add New Component...'),
        ],
      ),
    ),
    const PopupMenuItem(
      value: 'select-all',
      child: Row(
        children: [
          Icon(Icons.select_all, size: 18),
          SizedBox(width: 8),
          Text('Select All'),
        ],
      ),
    ),
  ];
}

List<PopupMenuEntry<String>> componentContextMenuOptions(
  ClipboardManager clipboardManager,
) {
  return [
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
  ];
}

PopupMenuItem<T> createMenuItemWithIcon<T>({
  required T value,
  required IconData icon,
  required String text,
  bool enabled = true,
  Color? iconColor,
  Color? textColor,
}) {
  return PopupMenuItem<T>(
    value: value,
    enabled: enabled,
    child: Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: enabled ? (iconColor ?? Colors.black87) : Colors.grey,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: enabled ? (textColor ?? Colors.black87) : Colors.grey,
          ),
        ),
      ],
    ),
  );
}

PopupMenuDivider createMenuDivider() {
  return const PopupMenuDivider();
}
