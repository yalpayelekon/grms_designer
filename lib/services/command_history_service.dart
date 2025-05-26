import '../comm/models/command_models.dart';

class CommandHistoryService {
  final int maxHistorySize;
  final List<QueuedCommand> _history = [];

  CommandHistoryService({this.maxHistorySize = 100});

  void add(QueuedCommand command) {
    _history.insert(0, command);
    if (_history.length > maxHistorySize) {
      _history.removeLast();
    }
  }

  List<QueuedCommand> get all => List.unmodifiable(_history);

  void clear() => _history.clear();
}
