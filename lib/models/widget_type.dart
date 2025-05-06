import 'canvas_item.dart';

enum WidgetType { text, button, image, treenode }

class WidgetData {
  final WidgetType type;
  final ComponentCategory? category;
  final Map<String, dynamic> additionalData;

  WidgetData({
    required this.type,
    this.category,
    this.additionalData = const {},
  });
}
