import 'package:flutter/material.dart';
import '../models/workgroup.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Placeholder list of workgroups
  List<Workgroup> workgroups = [
    Workgroup(
      id: '1',
      description: 'Main Office Network',
      networkInterface: 'eth0',
    ),
    Workgroup(
      id: '2',
      description: 'Warehouse Lighting',
      networkInterface: 'eth1',
    ),
  ];

  void _addWorkgroup() {
    // TODO: Implement workgroup addition logic
    print('Add Workgroup clicked');
  }

  void _editWorkgroup(Workgroup workgroup) {
    // TODO: Implement workgroup editing logic
    print('Edit Workgroup: ${workgroup.description}');
  }

  void _deleteWorkgroup(Workgroup workgroup) {
    setState(() {
      workgroups.remove(workgroup);
    });
  }

  void _navigateToWorkgroupDetail(Workgroup workgroup) {
    // TODO: Implement navigation to workgroup detail page
    print('Navigate to Workgroup: ${workgroup.description}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HelvarNet Manager'), centerTitle: true),
      body: ListView.builder(
        itemCount: workgroups.length,
        itemBuilder: (context, index) {
          final workgroup = workgroups[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(
                workgroup.description,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Network: ${workgroup.networkInterface}'),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _editWorkgroup(workgroup);
                      break;
                    case 'delete':
                      _deleteWorkgroup(workgroup);
                      break;
                  }
                },
                itemBuilder:
                    (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Edit'),
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
              ),
              onTap: () => _navigateToWorkgroupDetail(workgroup),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addWorkgroup,
        tooltip: 'Add Workgroup',
        child: const Icon(Icons.add),
      ),
    );
  }
}
