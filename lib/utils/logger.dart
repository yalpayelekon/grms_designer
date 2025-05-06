import '../services/log_service.dart';

LogService? _logService;

void initLogger(LogService service) {
  _logService = service;
}

void logVerbose(String message, {String? tag, StackTrace? stackTrace}) {
  _logService?.verbose(message, tag: tag, stackTrace: stackTrace);
}

void logDebug(String message, {String? tag, StackTrace? stackTrace}) {
  _logService?.debug(message, tag: tag, stackTrace: stackTrace);
}

void logInfo(String message, {String? tag, StackTrace? stackTrace}) {
  _logService?.info(message, tag: tag, stackTrace: stackTrace);
}

void logWarning(String message, {String? tag, StackTrace? stackTrace}) {
  _logService?.warning(message, tag: tag, stackTrace: stackTrace);
}

void logError(String message, {String? tag, StackTrace? stackTrace}) {
  _logService?.error(message, tag: tag, stackTrace: stackTrace);
}
