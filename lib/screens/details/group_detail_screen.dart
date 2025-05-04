import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/helvar_models/helvar_group.dart';
import '../../models/helvar_models/workgroup.dart';

class GroupDetailScreen extends ConsumerWidget {
  final HelvarGroup group;
  final Workgroup workgroup;

  const GroupDetailScreen({
    super.key,
    required this.group,
    required this.workgroup,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          group.description.isEmpty
              ? 'Group ${group.groupId}'
              : group.description,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(context),
            const SizedBox(height: 24),
            _buildDevicesSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.layers, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Group Details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(),
            _buildDetailRow('ID', group.groupId),
            _buildDetailRow('Description', group.description),
            _buildDetailRow('Type', group.type),
            if (group.lsig != null)
              _buildDetailRow('LSIG', group.lsig.toString()),
            for (int i = 0; i < group.blockValues.length; i++)
              _buildDetailRow('Block${i + 1}', group.blockValues[i].toString()),
            _buildDetailRow('Power Consumption', '${group.powerConsumption} W'),
            _buildDetailRow(
                'Power Polling', '${group.powerPollingMinutes} minutes'),
            _buildDetailRow('Gateway Router', group.gatewayRouterIpAddress),
            _buildDetailRow('Refresh Props After Action',
                group.refreshPropsAfterAction.toString()),
            if (group.actionResult.isNotEmpty)
              _buildDetailRow('Action Result', group.actionResult),
            if (group.lastMessage.isNotEmpty)
              _buildDetailRow('Last Message', group.lastMessage),
            if (group.lastMessageTime != null)
              _buildDetailRow(
                  'Message Time',
                  DateFormat('MMM d, yyyy h:mm:ss a')
                      .format(group.lastMessageTime!)),
            _buildDetailRow('Workgroup', workgroup.description),
          ],
        ),
      ),
    );
  }

  Widget _buildDevicesSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.devices, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Devices in this Group',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: Text(
                  'No devices information available for this group',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
