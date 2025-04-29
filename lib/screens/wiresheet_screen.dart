import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wiresheet.dart';
import '../providers/wiresheets_provider.dart';
import '../widgets/wiresheet_editor.dart';

class WiresheetScreen extends ConsumerWidget {
  final String wiresheetId;
  final bool showBackButton;

  const WiresheetScreen({
    super.key,
    required this.wiresheetId,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wiresheets = ref.watch(wiresheetsProvider);
    final wiresheet = wiresheets.firstWhere(
      (sheet) => sheet.id == wiresheetId,
      orElse: () => null as Wiresheet, // This will throw if not found
    );
    ref.read(wiresheetsProvider.notifier).setActiveWiresheet(wiresheetId);

    return Scaffold(
      appBar: AppBar(
        title: Text(wiresheet.name),
        leading: showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Rename Wiresheet',
            onPressed: () => _renameWiresheet(context, ref, wiresheet),
          ),
          IconButton(
            icon: const Icon(Icons.content_copy),
            tooltip: 'Duplicate Wiresheet',
            onPressed: () => _duplicateWiresheet(context, ref, wiresheet),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: WiresheetEditor(wiresheet: wiresheet),
    );
  }

  void _renameWiresheet(
      BuildContext context, WidgetRef ref, Wiresheet wiresheet) {
    final nameController = TextEditingController(text: wiresheet.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Wiresheet'),
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
            onPressed: () {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                ref.read(wiresheetsProvider.notifier).renameWiresheet(
                      wiresheet.id,
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

  void _duplicateWiresheet(
      BuildContext context, WidgetRef ref, Wiresheet wiresheet) {
    final nameController =
        TextEditingController(text: '${wiresheet.name} (Copy)');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duplicate Wiresheet'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'New Wiresheet Name',
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
                    .read(wiresheetsProvider.notifier)
                    .duplicateWiresheet(
                      wiresheet.id,
                      newName,
                    );

                if (duplicate != null && context.mounted) {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => WiresheetScreen(
                        wiresheetId: duplicate.id,
                        showBackButton: true,
                      ),
                    ),
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
