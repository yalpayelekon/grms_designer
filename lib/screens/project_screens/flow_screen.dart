// lib/screens/project_screens/flow_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/flowsheet.dart';
import '../../providers/flowsheet_provider.dart';
import '../../widgets/wiresheet_flow_editor.dart';
import '../../utils/logger.dart';

class FlowScreen extends ConsumerWidget {
  final String flowsheetId;

  const FlowScreen({
    super.key,
    required this.flowsheetId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flowsheets = ref.watch(flowsheetsProvider);
    final flowsheet = flowsheets.firstWhere(
      (sheet) => sheet.id == flowsheetId,
      orElse: () => throw Exception('Flowsheet not found'),
    );

    ref.read(flowsheetsProvider.notifier).setActiveFlowsheet(flowsheetId);

    return Scaffold(
      appBar: AppBar(
        title: Text(flowsheet.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Rename Flowsheet',
            onPressed: () => _renameFlowsheet(context, ref, flowsheet),
          ),
          IconButton(
            icon: const Icon(Icons.content_copy),
            tooltip: 'Duplicate Flowsheet',
            onPressed: () => _duplicateFlowsheet(context, ref, flowsheet),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: WiresheetFlowEditor(
        key: ValueKey(flowsheet.id),
        flowsheet: flowsheet,
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
                  logInfo("Flowsheet created: $newName");
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
