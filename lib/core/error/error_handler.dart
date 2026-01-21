import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:ridelink/core/error/exceptions.dart';
import 'package:ridelink/core/error/failures.dart';

/// Centralized error handler for the application.
///
/// Logs errors, reports to crash analytics (when configured),
/// and provides user-friendly messages.
class ErrorHandler {
  ErrorHandler._();

  /// Log an exception with context
  static void logException(
    Object error, {
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? extras,
  }) {
    final message = _formatError(error, context);
    
    // Development logging
    if (kDebugMode) {
      developer.log(
        message,
        name: 'ErrorHandler',
        error: error,
        stackTrace: stackTrace,
      );
    }

    // TODO: Add Crashlytics/Sentry reporting
    // FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }

  /// Log a warning (non-critical)
  static void logWarning(String message, {String? context}) {
    if (kDebugMode) {
      developer.log(
        context != null ? '[$context] $message' : message,
        name: 'Warning',
      );
    }
  }

  /// Convert exception to user-friendly message
  static String getUserMessage(Object error) {
    if (error is AppException) {
      return error.message;
    } else if (error is Failure) {
      return error.message;
    } else if (error is ConfigurationException) {
      return 'App configuration error. Please contact support.';
    }
    
    // Generic fallback
    return 'Something went wrong. Please try again.';
  }

  /// Get error code for analytics
  static String? getErrorCode(Object error) {
    if (error is AppException) {
      return error.code;
    } else if (error is Failure) {
      return error.code;
    }
    return null;
  }

  /// Format error for logging
  static String _formatError(Object error, String? context) {
    final buffer = StringBuffer();
    
    if (context != null) {
      buffer.write('[$context] ');
    }
    
    if (error is AppException) {
      buffer.write('${error.code}: ${error.message}');
    } else if (error is Failure) {
      buffer.write('${error.code}: ${error.message}');
    } else {
      buffer.write(error.toString());
    }
    
    return buffer.toString();
  }

  /// Check if error is recoverable (user can retry)
  static bool isRecoverable(Object error) {
    if (error is NetworkException || error is NetworkFailure) {
      return true;
    }
    if (error is TimeoutException) {
      return true;
    }
    if (error is ServerException) {
      // 5xx errors are typically recoverable
      return error.statusCode != null && error.statusCode! >= 500;
    }
    return false;
  }
}
