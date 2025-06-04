// lib/services/log_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum LogLevel { verbose, debug, info, warning, error }

class LogEntry {
  final String message;
  final LogLevel level;
  final DateTime timestamp;
  final String? tag;
  final StackTrace? stackTrace;

  LogEntry({
    required this.message,
    required this.level,
    required this.timestamp,
    this.tag,
    this.stackTrace,
  });

  String get formattedTime =>
      '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}.${timestamp.millisecond.toString().padLeft(3, '0')}';

  Color get levelColor {
    switch (level) {
      case LogLevel.verbose:
        return Colors.grey;
      case LogLevel.debug:
        return Colors.blue;
      case LogLevel.info:
        return Colors.green;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
    }
  }

  String get levelName => level.toString().split('.').last.toUpperCase();
}

class LogService extends StateNotifier<List<LogEntry>> {
  LogService() : super([]);

  static const int _maxLogEntries = 1000;

  void log(
    String message, {
    LogLevel level = LogLevel.info,
    String? tag,
    StackTrace? stackTrace,
  }) {
    final entry = LogEntry(
      message: message,
      level: level,
      timestamp: DateTime.now(),
      tag: tag,
      stackTrace: stackTrace,
    );
    if (kDebugMode) {
      switch (level) {
        case LogLevel.error:
          debugPrint(
            '❌ ${entry.formattedTime} - ${entry.levelName}: ${entry.message}',
          );
          break;
        case LogLevel.warning:
          debugPrint(
            '⚠️ ${entry.formattedTime} - ${entry.levelName}: ${entry.message}',
          );
          break;
        default:
          debugPrint(
            '${entry.formattedTime} - ${entry.levelName}: ${entry.message}',
          );
      }
    }
    state = [entry, ...state];
    if (state.length > _maxLogEntries) {
      state = state.sublist(0, _maxLogEntries);
    }
  }

  void verbose(String message, {String? tag, StackTrace? stackTrace}) {
    log(message, level: LogLevel.verbose, tag: tag, stackTrace: stackTrace);
  }

  void debug(String message, {String? tag, StackTrace? stackTrace}) {
    log(message, level: LogLevel.debug, tag: tag, stackTrace: stackTrace);
  }

  void info(String message, {String? tag, StackTrace? stackTrace}) {
    log(message, level: LogLevel.info, tag: tag, stackTrace: stackTrace);
  }

  void warning(String message, {String? tag, StackTrace? stackTrace}) {
    log(message, level: LogLevel.warning, tag: tag, stackTrace: stackTrace);
  }

  void error(String message, {String? tag, StackTrace? stackTrace}) {
    log(message, level: LogLevel.error, tag: tag, stackTrace: stackTrace);
  }

  void clear() {
    state = [];
  }

  List<LogEntry> getLogsByLevel(LogLevel level) {
    return state.where((entry) => entry.level == level).toList();
  }

  List<LogEntry> getLogsByTag(String tag) {
    return state.where((entry) => entry.tag == tag).toList();
  }

  List<LogEntry> searchLogs(String query) {
    final lowercaseQuery = query.toLowerCase();
    return state
        .where(
          (entry) =>
              entry.message.toLowerCase().contains(lowercaseQuery) ||
              (entry.tag?.toLowerCase().contains(lowercaseQuery) ?? false),
        )
        .toList();
  }
}

final logServiceProvider = StateNotifierProvider<LogService, List<LogEntry>>((
  ref,
) {
  return LogService();
});
