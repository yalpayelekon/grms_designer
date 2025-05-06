import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/wiresheet.dart';
import '../../providers/wiresheets_provider.dart';
import '../../utils/file_dialog_helper.dart';
import '../dialogs/wiresheet_actions.dart';
import '../project_screens/wiresheet_screen.dart';

class WiresheetListScreen extends ConsumerStatefulWidget {
  const WiresheetListScreen({super.key});

  @override
  WiresheetListScreenState createState() => WiresheetListScreenState();
}

class WiresheetListScreenState extends ConsumerState<WiresheetListScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final wiresheets = ref.watch(wiresheetsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wiresheets'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create New Wiresheet',
            onPressed: () => createNewWiresheet(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Import Wiresheet',
            onPressed: () => _importWiresheet(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : wiresheets.isEmpty
              ? _buildEmptyState()
              : _buildWiresheetList(wiresheets),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.description_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No wiresheets found',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Create New Wiresheet'),
            onPressed: () => createNewWiresheet(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildWiresheetList(List<Wiresheet> wiresheets) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: wiresheets.length,
      itemBuilder: (context, index) {
        final wiresheet = wiresheets[index];
        return _buildWiresheetCard(wiresheet);
      },
    );
  }

  Widget _buildWiresheetCard(Wiresheet wiresheet) {
    final itemCount = wiresheet.canvasItems.length;
    final lastModified = wiresheet.modifiedAt;
    final formattedDate =
        '${lastModified.day}/${lastModified.month}/${lastModified.year} ${lastModified.hour}:${lastModified.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        children: [
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(
                Icons.article,
                color: Colors.white,
              ),
            ),
            title: Text(
              wiresheet.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Items: $itemCount\nLast modified: $formattedDate',
            ),
            isThreeLine: true,
            onTap: () => _openWiresheet(wiresheet),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Rename',
                  onPressed: () => _renameWiresheet(wiresheet),
                ),
                IconButton(
                  icon: const Icon(Icons.content_copy),
                  tooltip: 'Duplicate',
                  onPressed: () => _duplicateWiresheet(wiresheet),
                ),
                IconButton(
                  icon: const Icon(Icons.file_download),
                  tooltip: 'Export',
                  onPressed: () => _exportWiresheet(wiresheet),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: 'Delete',
                  color: Colors.red,
                  onPressed: () => _confirmDeleteWiresheet(wiresheet),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openWiresheet(Wiresheet wiresheet) {
    ref.read(wiresheetsProvider.notifier).setActiveWiresheet(wiresheet.id);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WiresheetScreen(
          wiresheetId: wiresheet.id,
        ),
      ),
    );
  }

  void _renameWiresheet(Wiresheet wiresheet) {
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

  void _duplicateWiresheet(Wiresheet wiresheet) {
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Wiresheet "$newName" created')),
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

  Future<void> _exportWiresheet(Wiresheet wiresheet) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final filePath =
          await FileDialogHelper.pickJsonFileToSave('helvarnet_wiresheet.json');
      if (filePath == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final storageService = ref.read(wiresheetStorageServiceProvider);
      final success = await storageService.exportWiresheet(
        wiresheet.id,
        filePath,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Wiresheet "${wiresheet.name}" exported successfully'
                  : 'Failed to export wiresheet',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting wiresheet: $e')),
        );
      }
    }
  }

  Future<void> _importWiresheet(BuildContext context) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final filePath = await FileDialogHelper.pickFileToOpen(
        allowedExtensions: ['json'],
        dialogTitle: 'Select wiresheet file to import',
      );

      if (filePath == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final storageService = ref.read(wiresheetStorageServiceProvider);
      final importedWiresheet = await storageService.importWiresheet(filePath);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (importedWiresheet != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Wiresheet "${importedWiresheet.name}" imported successfully'),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to import wiresheet')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing wiresheet: $e')),
        );
      }
    }
  }

  void _confirmDeleteWiresheet(Wiresheet wiresheet) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Wiresheet'),
        content: Text('Are you sure you want to delete "${wiresheet.name}"?'),
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

    if (result == true && mounted) {
      final success = await ref
          .read(wiresheetsProvider.notifier)
          .deleteWiresheet(wiresheet.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Wiresheet deleted' : 'Failed to delete wiresheet',
            ),
          ),
        );
      }
    }
  }
}
