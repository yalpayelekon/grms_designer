import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/flowsheet.dart';
import '../../providers/flowsheet_provider.dart';
import '../../widgets/wiresheet_flow_editor.dart';

class FlowScreen extends ConsumerWidget {
  const FlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFlowsheet = ref.watch(activeFlowsheetProvider);

    if (activeFlowsheet == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(activeFlowsheet.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Rename Flowsheet',
            onPressed: () => _renameFlowsheet(context, ref, activeFlowsheet),
          ),
          IconButton(
            icon: const Icon(Icons.content_copy),
            tooltip: 'Duplicate Flowsheet',
            onPressed: () => _duplicateFlowsheet(context, ref, activeFlowsheet),
          ),
        ],
      ),
      body: WiresheetFlowEditor(
        flowsheetId: activeFlowsheet.id,
      ),
    );
  }

  void _renameFlowsheet(
      BuildContext context, WidgetRef ref, Flowsheet flowsheet) {
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
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                ref.read(flowsheetsProvider.notifier).renameFlowsheet(
                      flowsheet.id,
                      newName,
                    );
                Navigator.of(context).pop();
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _duplicateFlowsheet(
      BuildContext context, WidgetRef ref, Flowsheet flowsheet) {
    final nameController =
        TextEditingController(text: '${flowsheet.name} (Copy)');

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
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                final duplicate = await ref
                    .read(flowsheetsProvider.notifier)
                    .duplicateFlowsheet(
                      flowsheet.id,
                      newName,
                    );

                if (duplicate != null && context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Flowsheet "${duplicate.name}" created')),
                  );
                }
              }
            },
            child: const Text('Duplicate'),
          ),
        ],
      ),
    );
  }
}
