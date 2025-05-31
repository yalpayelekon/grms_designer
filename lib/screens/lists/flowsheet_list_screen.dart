// lib/screens/lists/flowsheet_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grms_designer/utils/dialog_utils.dart';
import '../../models/flowsheet.dart';
import '../../providers/flowsheet_provider.dart';
import '../../utils/file_dialog_helper.dart';
import '../../utils/general_ui.dart';
import '../project_screens/flow_screen.dart';

class FlowsheetListScreen extends ConsumerStatefulWidget {
  const FlowsheetListScreen({super.key});

  @override
  FlowsheetListScreenState createState() => FlowsheetListScreenState();
}

class FlowsheetListScreenState extends ConsumerState<FlowsheetListScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final flowsheets = ref.watch(flowsheetsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flowsheets'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create New Flowsheet',
            onPressed: () => _createNewFlowsheet(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Import Flowsheet',
            onPressed: () => _importFlowsheet(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : flowsheets.isEmpty
          ? _buildEmptyState()
          : _buildFlowsheetList(flowsheets),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.description_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No flowsheets found', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Create New Flowsheet'),
            onPressed: () => _createNewFlowsheet(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowsheetList(List<Flowsheet> flowsheets) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: flowsheets.length,
      itemBuilder: (context, index) {
        final flowsheet = flowsheets[index];
        return _buildFlowsheetCard(flowsheet);
      },
    );
  }

  Widget _buildFlowsheetCard(Flowsheet flowsheet) {
    final itemCount = flowsheet.components.length;
    final lastModified = flowsheet.modifiedAt;
    final formattedDate =
        '${lastModified.day}/${lastModified.month}/${lastModified.year} ${lastModified.hour}:${lastModified.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        children: [
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.green,
              child: Icon(Icons.account_tree, color: Colors.white),
            ),
            title: Text(
              flowsheet.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Components: $itemCount\nLast modified: $formattedDate',
            ),
            isThreeLine: true,
            onTap: () => _openFlowsheet(flowsheet),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Rename',
                  onPressed: () => _renameFlowsheet(flowsheet),
                ),
                IconButton(
                  icon: const Icon(Icons.content_copy),
                  tooltip: 'Duplicate',
                  onPressed: () => _duplicateFlowsheet(flowsheet),
                ),
                IconButton(
                  icon: const Icon(Icons.file_download),
                  tooltip: 'Export',
                  onPressed: () => _exportFlowsheet(flowsheet),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: 'Delete',
                  color: Colors.red,
                  onPressed: () => _confirmDeleteFlowsheet(flowsheet),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openFlowsheet(Flowsheet flowsheet) {
    final activeFlowsheetId = ref
        .read(flowsheetsProvider.notifier)
        .activeFlowsheetId;
    if (activeFlowsheetId != null && activeFlowsheetId != flowsheet.id) {
      ref.read(flowsheetsProvider.notifier).saveActiveFlowsheet();
    }

    ref.read(flowsheetsProvider.notifier).setActiveFlowsheet(flowsheet.id);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            FlowScreen(key: ValueKey(flowsheet.id), flowsheetId: flowsheet.id),
      ),
    );
  }

  void _createNewFlowsheet(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController(text: 'New Flowsheet');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Flowsheet'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Flowsheet Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          cancelAction(context),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  _isLoading = true;
                });

                final flowsheet = await ref
                    .read(flowsheetsProvider.notifier)
                    .createFlowsheet(name);

                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });

                  Navigator.of(context).pop();
                  _openFlowsheet(flowsheet);
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _renameFlowsheet(Flowsheet flowsheet) {
    final nameController = TextEditingController(text: flowsheet.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Flowsheet'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Flowsheet Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          cancelAction(context),
          TextButton(
            onPressed: () {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                ref
                    .read(flowsheetsProvider.notifier)
                    .renameFlowsheet(flowsheet.id, newName);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _duplicateFlowsheet(Flowsheet flowsheet) {
    final nameController = TextEditingController(
      text: '${flowsheet.name} (Copy)',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duplicate Flowsheet'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'New Flowsheet Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          cancelAction(context),
          TextButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                final duplicate = await ref
                    .read(flowsheetsProvider.notifier)
                    .duplicateFlowsheet(flowsheet.id, newName);

                if (duplicate != null && context.mounted) {
                  Navigator.of(context).pop();
                  showSnackBarMsg(context, 'Flowsheet "$newName" created');
                }
              }
            },
            child: const Text('Duplicate'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportFlowsheet(Flowsheet flowsheet) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final filePath = await FileDialogHelper.pickJsonFileToSave(
        'helvarnet_flowsheet.json',
      );
      if (filePath == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final storageService = ref.read(flowsheetStorageServiceProvider);
      final success = await storageService.exportFlowsheet(
        flowsheet.id,
        filePath,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showSnackBarMsg(
          context,
          success
              ? 'Flowsheet "${flowsheet.name}" exported successfully'
              : 'Failed to export flowsheet',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showSnackBarMsg(context, 'Error exporting flowsheet: $e');
      }
    }
  }

  Future<void> _importFlowsheet(BuildContext context) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final filePath = await FileDialogHelper.pickFileToOpen(
        allowedExtensions: ['json'],
        dialogTitle: 'Select flowsheet file to import',
      );

      if (filePath == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final storageService = ref.read(flowsheetStorageServiceProvider);
      final importedFlowsheet = await storageService.importFlowsheet(filePath);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (importedFlowsheet != null) {
          showSnackBarMsg(
            context,
            'Flowsheet "${importedFlowsheet.name}" imported successfully',
          );
        } else {
          showSnackBarMsg(context, 'Failed to import flowsheet');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showSnackBarMsg(context, 'Error importing flowsheet: $e');
      }
    }
  }

  void _confirmDeleteFlowsheet(Flowsheet flowsheet) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Flowsheet'),
        content: Text('Are you sure you want to delete "${flowsheet.name}"?'),
        actions: [
          cancelAction(context),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final success = await ref
          .read(flowsheetsProvider.notifier)
          .deleteFlowsheet(flowsheet.id);

      if (mounted) {
        showSnackBarMsg(
          context,
          success ? 'Flowsheet deleted' : 'Failed to delete flowsheet',
        );
      }
    }
  }
}
