import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grms_designer/utils/dialog_utils.dart';
import '../../providers/flowsheet_provider.dart';

void createNewFlowsheet(BuildContext context, WidgetRef ref) {
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
              final flowsheet = await ref
                  .read(flowsheetsProvider.notifier)
                  .createFlowsheet(name);

              await ref
                  .read(flowsheetsProvider.notifier)
                  .saveFlowsheet(flowsheet.id);

              Navigator.of(context).pop();
            }
          },
          child: const Text('Create'),
        ),
      ],
    ),
  );
}

Future<bool> confirmDeleteFlowsheet(
  BuildContext context,
  String flowsheetId,
  String name,
  WidgetRef ref,
) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Flowsheet'),
      content: Text('Are you sure you want to delete "$name"?'),
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

  if (result == true) {
    final success = await ref
        .read(flowsheetsProvider.notifier)
        .deleteFlowsheet(flowsheetId);
    return success;
  }
  return false;
}
