import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/helvar_models/workgroup.dart';
import '../../models/helvar_models/helvar_router.dart';
import '../lists/groups_list_screen.dart';
import '../details/router_detail_screen.dart';

class WorkgroupDetailScreen extends ConsumerStatefulWidget {
  final Workgroup workgroup;

  const WorkgroupDetailScreen({
    super.key,
    required this.workgroup,
  });

  @override
  WorkgroupDetailScreenState createState() => WorkgroupDetailScreenState();
}

class WorkgroupDetailScreenState extends ConsumerState<WorkgroupDetailScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workgroup.description),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.group_work),
            tooltip: 'View Groups',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupsListScreen(
                    workgroup: widget.workgroup,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(context),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Groups',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.navigate_next),
                        label: const Text('View All Groups'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GroupsListScreen(
                                workgroup: widget.workgroup,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
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
            _buildDetailRow('ID', widget.workgroup.id),
            _buildDetailRow('Description', widget.workgroup.description),
            _buildDetailRow(
                'Network Interface', widget.workgroup.networkInterface),
            _buildDetailRow('Number of Routers',
                widget.workgroup.routers.length.toString()),
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
      itemCount: widget.workgroup.routers.length,
      itemBuilder: (context, index) {
        final router = widget.workgroup.routers[index];
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
              router.description,
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
                    workgroup: widget.workgroup,
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
                          workgroup: widget.workgroup,
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
