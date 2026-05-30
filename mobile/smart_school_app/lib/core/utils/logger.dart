import 'dart:developer' as developer;

/// A simple logger utility for the application
class Logger {
  final String _tag;

  Logger(this._tag);

  void info(String message) {
    developer.log('INFO: $message', name: _tag);
  }

  void error(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log('ERROR: $message', name: _tag, error: error ?? message, stackTrace: stackTrace);
  }

  void warning(String message) {
    developer.log('WARNING: $message', name: _tag);
  }

  void debug(String message) {
    developer.log('DEBUG: $message', name: _tag);
  }
} 