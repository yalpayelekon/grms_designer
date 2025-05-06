import 'canvas_item.dart';

enum WidgetType { text, button, image }

class WidgetData {
  final WidgetType type;
  final ComponentCategory category;
  final Map<String, dynamic> additionalData;

  WidgetData({
    required this.type,
    this.category = ComponentCategory.ui,
    this.additionalData = const {},
  });
}
