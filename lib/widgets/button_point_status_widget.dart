import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grms_designer/providers/button_point_status_provider.dart';

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
    try {
      final statusKey = '${deviceAddress}_$buttonId';

      return ref.watch(buttonPointStatusProvider(statusKey)) != null
          ? _buildStatusWidget(ref.watch(buttonPointStatusProvider(statusKey)))
          : _buildDefaultWidget();
    } catch (e) {
      return _buildErrorWidget();
    }
  }

  Widget _buildStatusWidget(status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(8),
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
            size: 12,
            color: _getIconColor(status),
          ),
          const SizedBox(width: 2),
          Text(
            label ?? 'B$buttonId',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: _getTextColor(status),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.black26,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.help_outline,
            size: 12,
            color: Colors.grey,
          ),
          const SizedBox(width: 2),
          Text(
            label ?? 'B$buttonId',
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: const Icon(
        Icons.error_outline,
        size: 12,
        color: Colors.red,
      ),
    );
  }

  Color _getStatusColor(dynamic status) {
    if (status == null) return Colors.grey[200]!;

    if (status.function.contains('Status') ||
        status.function.contains('Missing')) {
      return status.value ? Colors.red[100]! : Colors.green[100]!;
    } else {
      return status.value ? Colors.blue[100]! : Colors.grey[100]!;
    }
  }

  IconData _getStatusIcon(dynamic status) {
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

  Color _getIconColor(dynamic status) {
    if (status == null) return Colors.grey;

    if (status.function.contains('Status') ||
        status.function.contains('Missing')) {
      return status.value ? Colors.red : Colors.green;
    } else {
      return status.value ? Colors.blue : Colors.grey;
    }
  }

  Color _getTextColor(dynamic status) {
    if (status == null) return Colors.grey[600]!;

    if (status.function.contains('Status') ||
        status.function.contains('Missing')) {
      return status.value ? Colors.red[800]! : Colors.green[800]!;
    } else {
      return status.value ? Colors.blue[800]! : Colors.grey[600]!;
    }
  }
}
