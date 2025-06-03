import 'package:intl/intl.dart';

String formatDateTime(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inMinutes < 1) {
    return 'Just now';
  } else if (difference.inHours < 1) {
    return '${difference.inMinutes}m ago';
  } else if (difference.inDays < 1) {
    return '${difference.inHours}h ago';
  } else {
    return '${difference.inDays}d ago';
  }
}

String getLastUpdateTime({DateTime? dateTime}) {
  final dt = dateTime ?? DateTime.now();
  return DateFormat('dd/MM/yyyy HH:mm:ss').format(dt);
}
