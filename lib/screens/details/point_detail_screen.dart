import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/helvar_models/helvar_device.dart';
import '../../models/helvar_models/helvar_router.dart';
import '../../models/helvar_models/workgroup.dart';
import '../../models/helvar_models/input_device.dart';
import '../../utils/general_ui.dart';
import '../../utils/logger.dart';

class PointDetailScreen extends ConsumerStatefulWidget {
  final Workgroup workgroup;
  final HelvarRouter router;
  final HelvarDevice device;
  final ButtonPoint point;

  const PointDetailScreen({
    super.key,
    required this.workgroup,
    required this.router,
    required this.device,
    required this.point,
  });

  @override
  PointDetailScreenState createState() => PointDetailScreenState();
}

class PointDetailScreenState extends ConsumerState<PointDetailScreen> {
  bool _isMonitoring = false;
  final List<String> _eventHistory = [];
  String? _lastEventTime;
  String? _currentValue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.router.description} - ${widget.point.name}'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isMonitoring ? Icons.stop : Icons.play_arrow),
            tooltip: _isMonitoring ? 'Stop Monitoring' : 'Start Monitoring',
            onPressed: _toggleMonitoring,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPointInfoCard(),
            const SizedBox(height: 16),
            _buildCurrentStatusCard(),
            const SizedBox(height: 16),
            _buildControlsCard(),
            const SizedBox(height: 16),
            _buildEventHistoryCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildPointInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getPointIcon(), size: 32, color: _getPointColor()),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.point.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        widget.point.function,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow('Point Name', widget.point.name),
            _buildInfoRow('Function', widget.point.function),
            _buildInfoRow('Button ID', widget.point.buttonId.toString()),
            _buildInfoRow(
              'Parent Device',
              widget.device.description.isEmpty
                  ? 'Device ${widget.device.deviceId}'
                  : widget.device.description,
            ),
            _buildInfoRow('Device Address', widget.device.address),
            _buildInfoRow('Point Type', _getPointTypeDescription()),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Status',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _isMonitoring ? Colors.green[100] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isMonitoring ? Colors.green : Colors.grey,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isMonitoring ? Icons.visibility : Icons.visibility_off,
                        size: 16,
                        color: _isMonitoring ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isMonitoring ? 'Monitoring' : 'Not Monitoring',
                        style: TextStyle(
                          color: _isMonitoring ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(),
            if (_currentValue != null)
              _buildInfoRow('Current Value', _currentValue!)
            else
              _buildInfoRow('Current Value', 'Unknown'),
            if (_lastEventTime != null)
              _buildInfoRow('Last Event', _lastEventTime!)
            else
              _buildInfoRow('Last Event', 'No events recorded'),
            _buildInfoRow('Event Count', _eventHistory.length.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Point Controls',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Divider(),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  icon: Icon(_isMonitoring ? Icons.stop : Icons.play_arrow),
                  label: Text(
                    _isMonitoring ? 'Stop Monitoring' : 'Start Monitoring',
                  ),
                  onPressed: _toggleMonitoring,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Query Current State'),
                  onPressed: _queryCurrentState,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear History'),
                  onPressed: _clearHistory,
                ),
                if (_isPointControllable())
                  ElevatedButton.icon(
                    icon: const Icon(Icons.touch_app),
                    label: const Text('Simulate Press'),
                    onPressed: _simulatePress,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventHistoryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Event History (${_eventHistory.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (_eventHistory.isNotEmpty)
                  TextButton(
                    onPressed: _clearHistory,
                    child: const Text('Clear All'),
                  ),
              ],
            ),
            const Divider(),
            if (_eventHistory.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(Icons.history, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('No events recorded yet'),
                      Text(
                        'Start monitoring to capture point events',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: _eventHistory.length,
                  itemBuilder: (context, index) {
                    final event =
                        _eventHistory[_eventHistory.length - 1 - index];
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.blue[100],
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                      title: Text(event),
                      dense: true,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  IconData _getPointIcon() {
    if (widget.point.function.contains('Status') ||
        widget.point.name.contains('Missing')) {
      return Icons.info_outline;
    } else if (widget.point.function.contains('IR')) {
      return Icons.settings_remote;
    } else if (widget.point.function.contains('Button')) {
      return Icons.touch_app;
    } else {
      return Icons.radio_button_unchecked;
    }
  }

  Color _getPointColor() {
    if (widget.point.function.contains('Status') ||
        widget.point.name.contains('Missing')) {
      return Colors.orange;
    } else if (widget.point.function.contains('IR')) {
      return Colors.purple;
    } else if (widget.point.function.contains('Button')) {
      return Colors.blue;
    } else {
      return Colors.grey;
    }
  }

  String _getPointTypeDescription() {
    if (widget.point.function.contains('Status') ||
        widget.point.name.contains('Missing')) {
      return 'Status Point';
    } else if (widget.point.function.contains('IR')) {
      return 'IR Receiver Point';
    } else if (widget.point.function.contains('Button')) {
      return 'Button Input Point';
    } else {
      return 'Generic Point';
    }
  }

  bool _isPointControllable() {
    // Only button points can be simulated/controlled
    return widget.point.function.contains('Button') &&
        !widget.point.function.contains('Status') &&
        !widget.point.name.contains('Missing');
  }

  void _toggleMonitoring() {
    setState(() {
      _isMonitoring = !_isMonitoring;
    });

    if (_isMonitoring) {
      _startMonitoring();
      showSnackBarMsg(context, 'Started monitoring ${widget.point.name}');
    } else {
      _stopMonitoring();
      showSnackBarMsg(context, 'Stopped monitoring ${widget.point.name}');
    }
  }

  void _startMonitoring() {
    // TODO: Implement actual monitoring using query commands
    // For now, simulate some events for demonstration
    _simulateMonitoringEvents();
  }

  void _stopMonitoring() {
    // TODO: Stop actual monitoring
    logInfo('Stopped monitoring point: ${widget.point.name}');
  }

  void _simulateMonitoringEvents() {
    if (!_isMonitoring) return;

    // Simulate periodic events
    Future.delayed(const Duration(seconds: 2), () {
      if (_isMonitoring && mounted) {
        _addEvent('Point activated');
        _simulateMonitoringEvents();
      }
    });
  }

  void _addEvent(String event) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    final eventWithTime = '$timestamp - $event';

    setState(() {
      _eventHistory.add(eventWithTime);
      _lastEventTime = timestamp;
      _currentValue = 'Active';

      // Keep only last 50 events
      if (_eventHistory.length > 50) {
        _eventHistory.removeAt(0);
      }
    });
  }

  void _queryCurrentState() {
    // TODO: Implement actual query using protocol commands
    showSnackBarMsg(context, 'Querying current state...');

    // Simulate query result
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _addEvent('State queried - Normal');
        showSnackBarMsg(context, 'State query completed');
      }
    });
  }

  void _clearHistory() {
    setState(() {
      _eventHistory.clear();
      _lastEventTime = null;
    });
    showSnackBarMsg(context, 'Event history cleared');
  }

  void _simulatePress() {
    if (!_isPointControllable()) return;

    _addEvent('Button press simulated');
    showSnackBarMsg(context, 'Simulated button press for ${widget.point.name}');
  }
}
