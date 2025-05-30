import 'package:grms_designer/niagara/models/port.dart';

mixin ComponentMixin {
  List<Property> get properties;
  List<ActionSlot> get actions;
  List<Topic> get topics;

  Property? getPropertyByIndex(int index) {
    try {
      return properties.firstWhere((prop) => prop.index == index);
    } catch (e) {
      return null;
    }
  }

  ActionSlot? getActionByIndex(int index) {
    try {
      return actions.firstWhere((action) => action.index == index);
    } catch (e) {
      return null;
    }
  }

  Topic? getTopicByIndex(int index) {
    try {
      return topics.firstWhere((topic) => topic.index == index);
    } catch (e) {
      return null;
    }
  }

  Slot? getSlotByIndex(int index) {
    return getPropertyByIndex(index) ??
        getActionByIndex(index) ??
        getTopicByIndex(index);
  }
}
