import 'package:flutter/material.dart';
import '../comm/models/command_models.dart';

Color getStatusColor(CommandStatus status) {
  switch (status) {
    case CommandStatus.queued:
      return Colors.grey;
    case CommandStatus.executing:
      return Colors.blue;
    case CommandStatus.completed:
      return Colors.green;
    case CommandStatus.failed:
      return Colors.red;
    case CommandStatus.cancelled:
      return Colors.orange;
    case CommandStatus.timedOut:
      return Colors.black38;
  }
}

IconData getStatusIcon(CommandStatus status) {
  switch (status) {
    case CommandStatus.queued:
      return Icons.hourglass_empty;
    case CommandStatus.executing:
      return Icons.pending;
    case CommandStatus.completed:
      return Icons.check_circle;
    case CommandStatus.failed:
      return Icons.error;
    case CommandStatus.cancelled:
      return Icons.cancel;
    case CommandStatus.timedOut:
      return Icons.timer_off;
  }
}

String getStatusDisplayName(CommandStatus status) {
  switch (status) {
    case CommandStatus.queued:
      return 'Queued';
    case CommandStatus.executing:
      return 'Executing';
    case CommandStatus.completed:
      return 'Completed';
    case CommandStatus.failed:
      return 'Failed';
    case CommandStatus.cancelled:
      return 'Cancelled';
    case CommandStatus.timedOut:
      return 'Timed Out';
  }
}
