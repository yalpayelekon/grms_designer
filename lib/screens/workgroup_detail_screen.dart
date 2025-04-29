import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workgroup.dart';
import '../models/helvar_router.dart';
import 'router_detail_screen.dart';

class WorkgroupDetailScreen extends ConsumerWidget {
  final Workgroup workgroup;

  const WorkgroupDetailScreen({
    super.key,
    required this.workgroup,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(workgroup.description),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(context),
            const SizedBox(height: 24),
            const Text(
              'Routers',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildRoutersList(context),
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
                const Icon(Icons.group_work, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Workgroup Details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(),
            _buildDetailRow('ID', workgroup.id),
            _buildDetailRow('Description', workgroup.description),
            _buildDetailRow('Network Interface', workgroup.networkInterface),
            _buildDetailRow(
                'Number of Routers', workgroup.routers.length.toString()),
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

  Widget _buildRoutersList(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: workgroup.routers.length,
      itemBuilder: (context, index) {
        final router = workgroup.routers[index];
        return _buildRouterCard(context, router);
      },
    );
  }

  Widget _buildRouterCard(BuildContext context, HelvarRouter router) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          ListTile(
            title: Text(
              router.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('IP Address: ${router.ipAddress}'),
                Text('Address: ${router.address}'),
                Text('Description: ${router.description}'),
                Text('Devices: ${router.devices.length}'),
              ],
            ),
            isThreeLine: true,
            leading: const CircleAvatar(
              child: Icon(Icons.router),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RouterDetailScreen(
                    workgroup: workgroup,
                    router: router,
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.devices),
                  label: const Text('Manage Devices'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RouterDetailScreen(
                          workgroup: workgroup,
                          router: router,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
