// lib/widgets/button_point_status_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/button_point_status_provider.dart';
import '../services/button_point_status_service.dart';

class ButtonPointStatusWidget extends ConsumerWidget {
  final String deviceAddress;
  final int buttonId;
  final String? label;

  const ButtonPointStatusWidget({
    super.key,
    required this.deviceAddress,
    required this.buttonId,
    this.label,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusKey = '${deviceAddress}_$buttonId';
    final status = ref.watch(buttonPointStatusProvider(statusKey));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.black26,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(status),
            size: 16,
            color: _getIconColor(status),
          ),
          const SizedBox(width: 4),
          Text(
            label ?? 'B$buttonId',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _getTextColor(status),
            ),
          ),
          if (status != null) ...[
            const SizedBox(width: 4),
            Text(
              status.value ? 'ON' : 'OFF',
              style: TextStyle(
                fontSize: 10,
                color: _getTextColor(status),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(ButtonPointStatus? status) {
    if (status == null) return Colors.grey[200]!;

    if (status.function.contains('Status') ||
        status.function.contains('Missing')) {
      // Missing status: red if missing, green if present
      return status.value ? Colors.red[100]! : Colors.green[100]!;
    } else {
      // Button status: blue if pressed, grey if not
      return status.value ? Colors.blue[100]! : Colors.grey[100]!;
    }
  }

  IconData _getStatusIcon(ButtonPointStatus? status) {
    if (status == null) return Icons.help_outline;

    if (status.function.contains('Status') ||
        status.function.contains('Missing')) {
      return status.value ? Icons.error : Icons.check_circle;
    } else if (status.function.contains('IR')) {
      return Icons.settings_remote;
    } else {
      return Icons.touch_app;
    }
  }

  Color _getIconColor(ButtonPointStatus? status) {
    if (status == null) return Colors.grey;

    if (status.function.contains('Status') ||
        status.function.contains('Missing')) {
      return status.value ? Colors.red : Colors.green;
    } else {
      return status.value ? Colors.blue : Colors.grey;
    }
  }

  Color _getTextColor(ButtonPointStatus? status) {
    if (status == null) return Colors.grey[600]!;

    if (status.function.contains('Status') ||
        status.function.contains('Missing')) {
      return status.value ? Colors.red[800]! : Colors.green[800]!;
    } else {
      return status.value ? Colors.blue[800]! : Colors.grey[600]!;
    }
  }
}
