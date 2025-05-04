import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/app_directory_service.dart';
import 'dart:io';

class ProjectFilesScreen extends ConsumerStatefulWidget {
  final String directoryName;

  const ProjectFilesScreen({
    super.key,
    required this.directoryName,
  });

  @override
  ProjectFilesScreenState createState() => ProjectFilesScreenState();
}

class ProjectFilesScreenState extends ConsumerState<ProjectFilesScreen> {
  final AppDirectoryService _directoryService = AppDirectoryService();
  List<FileSystemEntity> _files = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final files = await _directoryService.listFiles(widget.directoryName);
      setState(() {
        _files = files;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading files: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _importFile() async {
    // Implement file import
    // You can use your existing FileDialogHelper or other methods
  }

  Future<void> _deleteFile(FileSystemEntity file) async {
    try {
      final fileName = file.path.split(Platform.pathSeparator).last;
      await _directoryService.deleteFile(widget.directoryName, fileName);
      _loadFiles();
    } catch (e) {
      debugPrint('Error deleting file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.directoryName.toUpperCase()),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.folder_open,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No files found in this directory',
                          style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Import File'),
                        onPressed: _importFile,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _files.length,
                  itemBuilder: (context, index) {
                    final file = _files[index];
                    final fileName =
                        file.path.split(Platform.pathSeparator).last;

                    return ListTile(
                      leading: Icon(
                        file is Directory
                            ? Icons.folder
                            : Icons.insert_drive_file,
                        color: file is Directory ? Colors.amber : Colors.blue,
                      ),
                      title: Text(fileName),
                      subtitle: FutureBuilder<FileStat>(
                        future: file.stat(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            final stat = snapshot.data!;
                            final modified =
                                stat.modified.toString().split('.').first;
                            final size =
                                '${(stat.size / 1024).toStringAsFixed(2)} KB';
                            return Text('Modified: $modified\nSize: $size');
                          }
                          return const Text('Loading file info...');
                        },
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteFile(file),
                      ),
                      isThreeLine: true,
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _importFile,
        child: const Icon(Icons.add),
      ),
    );
  }
}
