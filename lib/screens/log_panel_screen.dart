import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grms_designer/utils/ui_helpers.dart';
import '../services/log_service.dart';
import '../utils/file_dialog_helper.dart';
import '../utils/logger.dart';

class LogPanelScreen extends ConsumerStatefulWidget {
  const LogPanelScreen({super.key});

  @override
  LogPanelScreenState createState() => LogPanelScreenState();
}

class LogPanelScreenState extends ConsumerState<LogPanelScreen> {
  LogLevel? _selectedLevel;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<LogEntry> logs = ref.watch(logServiceProvider);

    if (_selectedLevel != null) {
      logs = logs.where((log) => log.level == _selectedLevel).toList();
    }

    if (_searchQuery.isNotEmpty) {
      logs = logs
          .where(
            (log) =>
                log.message.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                (log.tag?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
                    false),
          )
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear Logs',
            onPressed: () => ref.read(logServiceProvider.notifier).clear(),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export Logs',
            onPressed: _exportLogs,
          ),
          IconButton(
            icon: Icon(
              _autoScroll
                  ? Icons.vertical_align_bottom
                  : Icons.vertical_align_center,
            ),
            tooltip: _autoScroll ? 'Auto-scroll On' : 'Auto-scroll Off',
            onPressed: () {
              setState(() {
                _autoScroll = !_autoScroll;
                if (_autoScroll && logs.isNotEmpty) {
                  _scrollToBottom();
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: logs.isEmpty
                ? const Center(child: Text('No logs to display'))
                : _buildLogList(logs),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search logs...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<LogLevel?>(
            initialValue: _selectedLevel,
            tooltip: 'Filter by Level',
            icon: const Icon(Icons.filter_list),
            onSelected: (LogLevel? level) {
              setState(() {
                _selectedLevel = level;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('All Levels')),
              ...LogLevel.values.map(
                (level) => PopupMenuItem(
                  value: level,
                  child: Text(level.toString().split('.').last.toUpperCase()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _exportLogs() async {
    try {
      final logs = ref.read(logServiceProvider);
      if (logs.isEmpty) {
        showSnackBarMsg(context, 'No logs to export');
        return;
      }

      final now = DateTime.now();
      final fileName =
          'helvarnet_logs_${now.year}${now.month}${now.day}_${now.hour}${now.minute}.txt';

      final filePath = await FileDialogHelper.pickTextFileToSave(fileName);
      if (filePath == null) return;

      final file = File(filePath);
      final buffer = StringBuffer();

      for (final log in logs) {
        buffer.writeln(
          '${log.formattedTime} [${log.levelName}]${log.tag != null ? ' [${log.tag}]' : ''}: ${log.message}',
        );
        if (log.stackTrace != null) {
          buffer.writeln(log.stackTrace);
          buffer.writeln();
        }
      }

      await file.writeAsString(buffer.toString());

      if (mounted) {
        showSnackBarMsg(context, 'Logs exported to $filePath');
      }
    } catch (e) {
      if (mounted) {
        showSnackBarMsg(context, 'Error exporting logs: $e');
      }
      logError('Error exporting logs: $e', tag: 'LogPanel');
    }
  }

  Widget _buildLogList(List<LogEntry> logs) {
    if (_autoScroll && logs.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: Container(width: 8, height: 24, color: log.levelColor),
            title: Text(
              log.message,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            subtitle: Row(
              children: [
                Text(log.formattedTime, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: log.levelColor.withValues(alpha: 0.2 * 255),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    log.levelName,
                    style: TextStyle(
                      fontSize: 12,
                      color: log.levelColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (log.tag != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.2 * 255),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      log.tag!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            onTap: log.stackTrace != null ? () => _showStackTrace(log) : null,
          ),
        );
      },
    );
  }

  void _showStackTrace(LogEntry log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${log.levelName}: ${log.message}'),
        content: Container(
          width: double.maxFinite,
          height: 300,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            child: Text(
              log.stackTrace.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ),
        actions: [closeAction(context)],
      ),
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
}
