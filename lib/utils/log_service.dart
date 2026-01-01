import 'package:flutter/foundation.dart';

/// Centralized logging service for better debugging and monitoring
class LogService {
  static const _enableDebugLogs = kDebugMode;
  static const _enableInfoLogs = true;
  static const _enableErrorLogs = true;
  
  /// Log debug information (only in debug mode)
  static void debug(String tag, String message, [dynamic data]) {
    if (_enableDebugLogs) {
      debugPrint('🐛 [$tag] $message${data != null ? ' | Data: $data' : ''}');
    }
  }
  
  /// Log informational messages
  static void info(String tag, String message, [dynamic data]) {
    if (_enableInfoLogs) {
      debugPrint('ℹ️ [$tag] $message${data != null ? ' | Data: $data' : ''}');
    }
  }
  
  /// Log errors with optional error object and stack trace
  static void error(String tag, String message, [dynamic error, StackTrace? stackTrace]) {
    if (_enableErrorLogs) {
      debugPrint('❌ [$tag] $message');
      if (error != null) {
        debugPrint('   Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('   Stack trace: $stackTrace');
      }
    }
  }
  
  /// Log warnings
  static void warning(String tag, String message, [dynamic data]) {
    debugPrint('⚠️ [$tag] $message${data != null ? ' | Data: $data' : ''}');
  }
  
  /// Log success messages
  static void success(String tag, String message, [dynamic data]) {
    if (_enableInfoLogs) {
      debugPrint('✅ [$tag] $message${data != null ? ' | Data: $data' : ''}');
    }
  }
  
  /// Log performance metrics
  static void performance(String tag, String operation, Duration duration) {
    if (_enableDebugLogs) {
      debugPrint('⏱️ [$tag] $operation took ${duration.inMilliseconds}ms');
    }
  }
}
