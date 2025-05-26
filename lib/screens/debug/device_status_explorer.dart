import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/helvar_models/helvar_device.dart';
import '../../protocol/query_commands.dart';
import '../../providers/router_connection_provider.dart';
import '../../utils/general_ui.dart';
import '../../utils/logger.dart';

class DeviceStatusExplorer extends ConsumerStatefulWidget {
  final HelvarDevice device;
  final String routerIpAddress;

  const DeviceStatusExplorer({
    super.key,
    required this.device,
    required this.routerIpAddress,
  });

  @override
  DeviceStatusExplorerState createState() => DeviceStatusExplorerState();
}

class DeviceStatusExplorerState extends ConsumerState<DeviceStatusExplorer> {
  final List<QueryResult> _queryResults = [];
  bool _isQuerying = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Device Status Explorer - ${widget.device.address}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _queryResults.clear();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildControlPanel(),
          const Divider(),
          Expanded(
            child: _buildResultsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Device: ${widget.device.description} (${widget.device.address})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            'Router: ${widget.routerIpAddress}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              ElevatedButton(
                onPressed: _isQuerying ? null : () => _queryDeviceState(),
                child: const Text('Device State'),
              ),
              ElevatedButton(
                onPressed: _isQuerying ? null : () => _queryDeviceMissing(),
                child: const Text('Missing Status'),
              ),
              ElevatedButton(
                onPressed: _isQuerying ? null : () => _queryDeviceFaulty(),
                child: const Text('Faulty Status'),
              ),
              ElevatedButton(
                onPressed: _isQuerying ? null : () => _queryDeviceDisabled(),
                child: const Text('Disabled Status'),
              ),
              ElevatedButton(
                onPressed: _isQuerying ? null : () => _queryInputs(),
                child: const Text('Inputs'),
              ),
              ElevatedButton(
                onPressed: _isQuerying ? null : () => _queryMeasurement(),
                child: const Text('Measurement'),
              ),
              ElevatedButton(
                onPressed: _isQuerying ? null : () => _queryDeviceType(),
                child: const Text('Device Type'),
              ),
              ElevatedButton(
                onPressed: _isQuerying ? null : () => _queryDescription(),
                child: const Text('Description'),
              ),
              ElevatedButton(
                onPressed: _isQuerying ? null : () => _querySceneInfo(),
                child: const Text('Scene Info'),
              ),
              ElevatedButton(
                onPressed: _isQuerying ? null : () => _queryAllCommands(),
                child: const Text('Query All'),
              ),
            ],
          ),
          if (_isQuerying)
            const Padding(
              padding: EdgeInsets.only(top: 16.0),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    if (_queryResults.isEmpty) {
      return const Center(
        child: Text(
            'No queries executed yet. Click buttons above to start exploring.'),
      );
    }

    return ListView.builder(
      itemCount: _queryResults.length,
      itemBuilder: (context, index) {
        final result = _queryResults[
            _queryResults.length - 1 - index]; // Show newest first
        return _buildQueryResultCard(result);
      },
    );
  }

  Widget _buildQueryResultCard(QueryResult result) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        leading: Icon(
          result.success ? Icons.check_circle : Icons.error,
          color: result.success ? Colors.green : Colors.red,
        ),
        title: Text(result.queryName),
        subtitle: Text('${result.timestamp.toLocal()}'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Command', result.command),
                const SizedBox(height: 8),
                _buildInfoRow('Success', result.success.toString()),
                const SizedBox(height: 8),
                if (result.response != null) ...[
                  _buildInfoRow('Response', result.response!),
                  const SizedBox(height: 8),
                ],
                if (result.errorMessage != null) ...[
                  _buildInfoRow('Error', result.errorMessage!, isError: true),
                  const SizedBox(height: 8),
                ],
                _buildInfoRow(
                    'Duration', '${result.duration.inMilliseconds}ms'),
                if (result.parsedData != null) ...[
                  const SizedBox(height: 8),
                  const Text('Parsed Data:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      result.parsedData.toString(),
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isError = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: TextStyle(
              color: isError ? Colors.red : null,
              fontFamily: value.length > 50 ? 'monospace' : null,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _queryDeviceState() async {
    await _executeQuery(
      'Device State',
      HelvarNetCommands.queryDeviceState(widget.device.address),
    );
  }

  Future<void> _queryDeviceMissing() async {
    await _executeQuery(
      'Device Missing',
      HelvarNetCommands.queryDeviceIsMissing(widget.device.address),
    );
  }

  Future<void> _queryDeviceFaulty() async {
    await _executeQuery(
      'Device Faulty',
      HelvarNetCommands.queryDeviceIsFaulty(widget.device.address),
    );
  }

  Future<void> _queryDeviceDisabled() async {
    await _executeQuery(
      'Device Disabled',
      HelvarNetCommands.queryDeviceIsDisabled(widget.device.address),
    );
  }

  Future<void> _queryInputs() async {
    await _executeQuery(
      'Device Inputs',
      HelvarNetCommands.queryInputsForDevice(widget.device.address),
    );
  }

  Future<void> _queryMeasurement() async {
    await _executeQuery(
      'Device Measurement',
      HelvarNetCommands.queryMeasurement(widget.device.address),
    );
  }

  Future<void> _queryDeviceType() async {
    await _executeQuery(
      'Device Type',
      HelvarNetCommands.queryDeviceType(widget.device.address),
    );
  }

  Future<void> _queryDescription() async {
    await _executeQuery(
      'Device Description',
      HelvarNetCommands.queryDescriptionDevice(widget.device.address),
    );
  }

  Future<void> _querySceneInfo() async {
    await _executeQuery(
      'Scene Info',
      HelvarNetCommands.querySceneInfoForDevice(widget.device.address),
    );
  }

  Future<void> _queryAllCommands() async {
    setState(() {
      _isQuerying = true;
    });

    final queries = [
      (
        'Device State',
        HelvarNetCommands.queryDeviceState(widget.device.address)
      ),
      (
        'Device Missing',
        HelvarNetCommands.queryDeviceIsMissing(widget.device.address)
      ),
      (
        'Device Faulty',
        HelvarNetCommands.queryDeviceIsFaulty(widget.device.address)
      ),
      (
        'Device Disabled',
        HelvarNetCommands.queryDeviceIsDisabled(widget.device.address)
      ),
      ('Device Type', HelvarNetCommands.queryDeviceType(widget.device.address)),
      (
        'Description',
        HelvarNetCommands.queryDescriptionDevice(widget.device.address)
      ),
      ('Inputs', HelvarNetCommands.queryInputsForDevice(widget.device.address)),
      (
        'Measurement',
        HelvarNetCommands.queryMeasurement(widget.device.address)
      ),
      (
        'Scene Info',
        HelvarNetCommands.querySceneInfoForDevice(widget.device.address)
      ),
    ];

    for (final (name, command) in queries) {
      await _executeQuery(name, command, showProgress: false);
      // Small delay between queries to avoid overwhelming the device
      await Future.delayed(const Duration(milliseconds: 500));
    }

    setState(() {
      _isQuerying = false;
    });

    if (mounted) {
      showSnackBarMsg(context, 'All queries completed!');
    }
  }

  Future<void> _executeQuery(String queryName, String command,
      {bool showProgress = true}) async {
    if (showProgress) {
      setState(() {
        _isQuerying = true;
      });
    }

    final startTime = DateTime.now();

    try {
      final commandService = ref.read(routerCommandServiceProvider);
      final result = await commandService.sendCommand(
        widget.routerIpAddress,
        command,
        timeout: const Duration(seconds: 5),
      );

      final duration = DateTime.now().difference(startTime);

      // Try to parse the response
      Map<String, dynamic>? parsedData;
      if (result.success && result.response != null) {
        try {
          parsedData = _parseResponse(result.response!);
        } catch (e) {
          logError('Error parsing response: $e');
        }
      }

      final queryResult = QueryResult(
        queryName: queryName,
        command: command,
        success: result.success,
        response: result.response,
        errorMessage: result.errorMessage,
        timestamp: startTime,
        duration: duration,
        parsedData: parsedData,
      );

      setState(() {
        _queryResults.add(queryResult);
        if (showProgress) {
          _isQuerying = false;
        }
      });

      logInfo('Query "$queryName" completed: ${result.success}');
      if (result.response != null) {
        logInfo('Response: ${result.response}');
      }
      if (parsedData != null) {
        logInfo('Parsed data: $parsedData');
      }
    } catch (e) {
      final duration = DateTime.now().difference(startTime);

      final queryResult = QueryResult(
        queryName: queryName,
        command: command,
        success: false,
        response: null,
        errorMessage: e.toString(),
        timestamp: startTime,
        duration: duration,
        parsedData: null,
      );

      setState(() {
        _queryResults.add(queryResult);
        if (showProgress) {
          _isQuerying = false;
        }
      });

      logError('Query "$queryName" failed: $e');
    }
  }

  Map<String, dynamic>? _parseResponse(String response) {
    try {
      final Map<String, dynamic> result = {};

      result['raw'] = response;
      result['isSuccess'] = response.startsWith('?');
      result['isError'] = response.startsWith('!');

      if (response.contains('=')) {
        final parts = response.split('=');
        if (parts.length > 1) {
          result['value'] = parts[1].replaceAll('#', '');
        }
      }

      final commandMatch = RegExp(r'C:(\d+)').firstMatch(response);
      if (commandMatch != null) {
        result['commandCode'] = int.tryParse(commandMatch.group(1)!);
      }

      final versionMatch = RegExp(r'V:(\d+)').firstMatch(response);
      if (versionMatch != null) {
        result['version'] = int.tryParse(versionMatch.group(1)!);
      }

      final addressMatch = RegExp(r'@([\d.]+)').firstMatch(response);
      if (addressMatch != null) {
        result['address'] = addressMatch.group(1);
      }

      return result;
    } catch (e) {
      return {'error': 'Failed to parse: $e'};
    }
  }
}

class QueryResult {
  final String queryName;
  final String command;
  final bool success;
  final String? response;
  final String? errorMessage;
  final DateTime timestamp;
  final Duration duration;
  final Map<String, dynamic>? parsedData;

  QueryResult({
    required this.queryName,
    required this.command,
    required this.success,
    this.response,
    this.errorMessage,
    required this.timestamp,
    required this.duration,
    this.parsedData,
  });
}
