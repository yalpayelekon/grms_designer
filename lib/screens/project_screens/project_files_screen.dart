import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/app_directory_service.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../../utils/file_dialog_helper.dart';

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
    try {
      String? filePath;

      if (widget.directoryName == AppDirectoryService.imagesDir) {
        filePath = await FileDialogHelper.pickFileToOpen(
          type: FileType.image,
          dialogTitle: 'Select image to import',
        );
      } else if (widget.directoryName == AppDirectoryService.iconsDir) {
        filePath = await FileDialogHelper.pickFileToOpen(
          type: FileType.image,
          dialogTitle: 'Select icon to import',
        );
      } else if (widget.directoryName == AppDirectoryService.workgroupsDir) {
        filePath = await FileDialogHelper.pickFileToOpen(
          allowedExtensions: ['json'],
          dialogTitle: 'Select workgroup file to import',
        );
      } else if (widget.directoryName == AppDirectoryService.wiresheetsDir) {
        filePath = await FileDialogHelper.pickFileToOpen(
          allowedExtensions: ['json'],
          dialogTitle: 'Select wiresheet file to import',
        );
      } else {
        filePath = await FileDialogHelper.pickFileToOpen(
          type: FileType.any,
          dialogTitle: 'Select file to import',
        );
      }

      if (filePath != null) {
        setState(() {
          _isLoading = true;
        });

        final fileName = filePath.split(Platform.pathSeparator).last;
        String targetPath;
        switch (widget.directoryName) {
          case AppDirectoryService.workgroupsDir:
            targetPath = await _directoryService.getWorkgroupFilePath(fileName);
            break;
          case AppDirectoryService.wiresheetsDir:
            targetPath = await _directoryService.getWiresheetFilePath(fileName);
            break;
          case AppDirectoryService.imagesDir:
            targetPath = await _directoryService.getImageFilePath(fileName);
            break;
          case AppDirectoryService.iconsDir:
            targetPath = await _directoryService.getImageFilePath(fileName);
            break;
          default:
            targetPath = await _directoryService.getFilePath(
                widget.directoryName, fileName);
        }

        final sourceFile = File(filePath);
        final targetFile = File(targetPath);

        if (await targetFile.exists()) {
          if (!mounted) return;
          final shouldReplace = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('File Already Exists'),
              content: Text(
                  'A file named "$fileName" already exists. Do you want to replace it?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Replace'),
                ),
              ],
            ),
          );

          if (shouldReplace != true) {
            setState(() {
              _isLoading = false;
            });
            return;
          }
        }

        await sourceFile.copy(targetPath);
        await _loadFiles();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('File "$fileName" imported successfully')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing file: $e')),
        );
      }
      debugPrint('Error importing file: $e');
    }
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
