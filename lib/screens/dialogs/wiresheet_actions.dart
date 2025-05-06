import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/wiresheets_provider.dart';

void createNewWiresheet(BuildContext context, WidgetRef ref) {
  final nameController = TextEditingController(text: 'New Wiresheet');

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Create New Wiresheet'),
      content: TextField(
        controller: nameController,
        decoration: const InputDecoration(
          labelText: 'Wiresheet Name',
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
            final name = nameController.text.trim();
            if (name.isNotEmpty) {
              await ref.read(wiresheetsProvider.notifier).createWiresheet(name);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Create'),
        ),
      ],
    ),
  );
}

Future<bool> confirmDeleteWiresheet(BuildContext context, String wiresheetId,
    String name, WidgetRef ref) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Wiresheet'),
      content: Text('Are you sure you want to delete "$name"?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (result == true) {
    await ref.read(wiresheetsProvider.notifier).deleteWiresheet(wiresheetId);
    return true;
  }
  return false;
}
