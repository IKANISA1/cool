/// Base exception class for data-layer errors
///
/// Exceptions represent unexpected errors at the data layer
/// that need to be caught and converted to Failures.
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'AppException($code): $message';
}

// ═══════════════════════════════════════════════════════════
// SERVER EXCEPTIONS
// ═══════════════════════════════════════════════════════════

/// Server returned an error
class ServerException extends AppException {
  final int? statusCode;

  const ServerException({
    super.message = 'Server error occurred',
    super.code,
    super.originalError,
    this.statusCode,
  });

  factory ServerException.fromStatusCode(int statusCode, [String? message]) {
    switch (statusCode) {
      case 400:
        return ServerException(
          message: message ?? 'Bad request',
          code: 'BAD_REQUEST',
          statusCode: statusCode,
        );
      case 401:
        return ServerException(
          message: message ?? 'Unauthorized',
          code: 'UNAUTHORIZED',
          statusCode: statusCode,
        );
      case 403:
        return ServerException(
          message: message ?? 'Forbidden',
          code: 'FORBIDDEN',
          statusCode: statusCode,
        );
      case 404:
        return ServerException(
          message: message ?? 'Not found',
          code: 'NOT_FOUND',
          statusCode: statusCode,
        );
      case 409:
        return ServerException(
          message: message ?? 'Conflict',
          code: 'CONFLICT',
          statusCode: statusCode,
        );
      case 429:
        return ServerException(
          message: message ?? 'Too many requests',
          code: 'RATE_LIMITED',
          statusCode: statusCode,
        );
      case 500:
        return ServerException(
          message: message ?? 'Internal server error',
          code: 'INTERNAL_ERROR',
          statusCode: statusCode,
        );
      case 502:
      case 503:
      case 504:
        return ServerException(
          message: message ?? 'Service unavailable',
          code: 'SERVICE_UNAVAILABLE',
          statusCode: statusCode,
        );
      default:
        return ServerException(
          message: message ?? 'Server error',
          code: 'SERVER_ERROR',
          statusCode: statusCode,
        );
    }
  }
}

// ═══════════════════════════════════════════════════════════
// NETWORK EXCEPTIONS
// ═══════════════════════════════════════════════════════════

/// No network connection
class NetworkException extends AppException {
  const NetworkException({
    super.message = 'No internet connection',
    super.code = 'NO_NETWORK',
    super.originalError,
  });
}

/// Request timeout
class TimeoutException extends AppException {
  const TimeoutException({
    super.message = 'Request timed out',
    super.code = 'TIMEOUT',
    super.originalError,
  });
}

// ═══════════════════════════════════════════════════════════
// CACHE EXCEPTIONS
// ═══════════════════════════════════════════════════════════

/// Cache read/write error
class CacheException extends AppException {
  const CacheException({
    super.message = 'Cache error',
    super.code = 'CACHE_ERROR',
    super.originalError,
  });
}

/// No cached data available
class NoCacheDataException extends AppException {
  const NoCacheDataException({
    super.message = 'No cached data available',
    super.code = 'NO_CACHE_DATA',
    super.originalError,
  });
}

// ═══════════════════════════════════════════════════════════
// AUTH EXCEPTIONS
// ═══════════════════════════════════════════════════════════

/// Authentication exception
class AuthException extends AppException {
  const AuthException({
    super.message = 'Authentication error',
    super.code = 'AUTH_ERROR',
    super.originalError,
  });
}

/// Session expired
class SessionExpiredException extends AppException {
  const SessionExpiredException({
    super.message = 'Session expired. Please sign in again.',
    super.code = 'SESSION_EXPIRED',
    super.originalError,
  });
}

/// Rate limited
class RateLimitException extends AppException {
  final int? retryAfter;

  const RateLimitException({
    super.message = 'Too many attempts. Please try again later.',
    super.code = 'RATE_LIMITED',
    super.originalError,
    this.retryAfter,
  });
}

/// Invalid OTP code
class InvalidOtpException extends AppException {
  final int? attemptsRemaining;

  const InvalidOtpException({
    super.message = 'Invalid verification code.',
    super.code = 'INVALID_OTP',
    super.originalError,
    this.attemptsRemaining,
  });
}

/// OTP expired
class OtpExpiredException extends AppException {
  const OtpExpiredException({
    super.message = 'Verification code has expired. Please request a new one.',
    super.code = 'OTP_EXPIRED',
    super.originalError,
  });
}

// ═══════════════════════════════════════════════════════════
// PERMISSION EXCEPTIONS
// ═══════════════════════════════════════════════════════════

/// Permission denied
class PermissionDeniedException extends AppException {
  const PermissionDeniedException({
    super.message = 'Permission denied',
    super.code = 'PERMISSION_DENIED',
    super.originalError,
  });
}

// ═══════════════════════════════════════════════════════════
// PARSE EXCEPTIONS
// ═══════════════════════════════════════════════════════════

/// Failed to parse data
class ParseException extends AppException {
  const ParseException({
    super.message = 'Failed to parse data',
    super.code = 'PARSE_ERROR',
    super.originalError,
  });
}

// ═══════════════════════════════════════════════════════════
// DEVICE EXCEPTIONS
// ═══════════════════════════════════════════════════════════

/// NFC not supported
class NfcNotSupportedException extends AppException {
  const NfcNotSupportedException({
    super.message = 'NFC is not supported on this device',
    super.code = 'NFC_NOT_SUPPORTED',
    super.originalError,
  });
}

/// Location services disabled
class LocationDisabledException extends AppException {
  const LocationDisabledException({
    super.message = 'Location services are disabled',
    super.code = 'LOCATION_DISABLED',
    super.originalError,
  });
}

/// Geocoding error (address <-> coordinates)
class GeocodingException extends AppException {
  const GeocodingException({
    super.message = 'Geocoding failed',
    super.code = 'GEOCODING_ERROR',
    super.originalError,
  });
}
