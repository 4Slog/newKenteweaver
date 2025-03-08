import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

class LoggingService {
  static final LoggingService _instance = LoggingService._internal();
  factory LoggingService() => _instance;
  
  LoggingService._internal();
  
  final List<LogEntry> _logs = [];
  LogLevel _minLevel = kDebugMode ? LogLevel.debug : LogLevel.info;
  bool _persistLogs = true;
  
  // Initialize the logging service
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _persistLogs = prefs.getBool('persist_logs') ?? true;
      
      // Load any saved logs
      if (_persistLogs) {
        final savedLogs = prefs.getStringList('app_logs') ?? [];
        for (final logStr in savedLogs) {
          try {
            _logs.add(LogEntry.fromString(logStr));
          } catch (e) {
            debugPrint('Error parsing saved log: $e');
          }
        }
        
        // Trim logs if too many
        if (_logs.length > 1000) {
          _logs.removeRange(0, _logs.length - 1000);
        }
      }
      
      // Log initialization success
      info('Logging service initialized', tag: 'LoggingService');
    } catch (e) {
      debugPrint('Error initializing logging service: $e');
    }
  }
  
  // Log a message
  void log(
    String message, {
    LogLevel level = LogLevel.info,
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level.index < _minLevel.index) return;
    
    final entry = LogEntry(
      timestamp: DateTime.now(),
      message: message,
      level: level,
      tag: tag,
      error: error?.toString(),
      stackTrace: stackTrace?.toString(),
    );
    
    _logs.add(entry);
    
    // Print to console in debug mode
    if (kDebugMode) {
      final prefix = '[${entry.level.name.toUpperCase()}]${tag != null ? '[$tag]' : ''}';
      debugPrint('$prefix ${entry.message}');
      if (error != null) debugPrint('Error: $error');
      if (stackTrace != null) debugPrint('StackTrace: $stackTrace');
    }
    
    // Persist logs if enabled
    if (_persistLogs) {
      _saveLogs();
    }
  }
  
  // Helper methods for different log levels
  void debug(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    log(message, level: LogLevel.debug, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  void info(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    log(message, level: LogLevel.info, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  void warning(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    log(message, level: LogLevel.warning, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    log(message, level: LogLevel.error, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  void critical(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    log(message, level: LogLevel.critical, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  // Get all logs
  List<LogEntry> getLogs({LogLevel? minLevel}) {
    if (minLevel == null) return List.unmodifiable(_logs);
    return _logs.where((log) => log.level.index >= minLevel.index).toList();
  }
  
  // Clear logs
  Future<void> clearLogs() async {
    _logs.clear();
    
    if (_persistLogs) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('app_logs');
      } catch (e) {
        debugPrint('Error clearing logs: $e');
      }
    }
  }
  
  // Save logs to persistent storage
  Future<void> _saveLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Only keep the last 1000 logs to avoid excessive storage use
      final logsToSave = _logs.length <= 1000 
          ? _logs 
          : _logs.sublist(_logs.length - 1000);
      
      final logStrings = logsToSave.map((log) => log.toString()).toList();
      await prefs.setStringList('app_logs', logStrings);
    } catch (e) {
      debugPrint('Error saving logs: $e');
    }
  }
  
  // Set minimum log level
  void setMinLogLevel(LogLevel level) {
    _minLevel = level;
  }
  
  // Enable/disable log persistence
  Future<void> setPersistLogs(bool persist) async {
    _persistLogs = persist;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('persist_logs', persist);
    } catch (e) {
      debugPrint('Error setting persist logs: $e');
    }
  }
}

class LogEntry {
  final DateTime timestamp;
  final String message;
  final LogLevel level;
  final String? tag;
  final String? error;
  final String? stackTrace;
  
  LogEntry({
    required this.timestamp,
    required this.message,
    required this.level,
    this.tag,
    this.error,
    this.stackTrace,
  });
  
  // Convert to string for storage
  @override
  String toString() {
    return '$timestamp|${level.index}|$message|${tag ?? ''}|${error ?? ''}|${stackTrace ?? ''}';
  }
  
  // Create from string
  factory LogEntry.fromString(String str) {
    final parts = str.split('|');
    if (parts.length < 3) throw FormatException('Invalid log format');
    
    return LogEntry(
      timestamp: DateTime.parse(parts[0]),
      level: LogLevel.values[int.parse(parts[1])],
      message: parts[2],
      tag: parts.length > 3 ? (parts[3].isEmpty ? null : parts[3]) : null,
      error: parts.length > 4 ? (parts[4].isEmpty ? null : parts[4]) : null,
      stackTrace: parts.length > 5 ? (parts[5].isEmpty ? null : parts[5]) : null,
    );
  }
}
