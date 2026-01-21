import 'package:equatable/equatable.dart';

/// Base failure class for domain-level errors
///
/// Failures represent domain logic errors that are expected
/// and can be handled by the application.
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [message, code];
}

// ═══════════════════════════════════════════════════════════
// GENERAL FAILURES
// ═══════════════════════════════════════════════════════════

/// Server-side error occurred
class ServerFailure extends Failure {
  const ServerFailure({
    super.message = 'A server error occurred. Please try again.',
    super.code,
  });
}

/// Network connectivity issue
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No internet connection. Please check your network.',
    super.code = 'NETWORK_ERROR',
  });
}

/// Local cache/storage error
class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Unable to access local data.',
    super.code = 'CACHE_ERROR',
  });
}

/// Unexpected error occurred
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({
    super.message = 'An unexpected error occurred. Please try again.',
    super.code = 'UNEXPECTED_ERROR',
  });
}

// ═══════════════════════════════════════════════════════════
// AUTH FAILURES
// ═══════════════════════════════════════════════════════════

/// Authentication failed
class AuthFailure extends Failure {
  const AuthFailure({
    super.message = 'Authentication failed. Please try again.',
    super.code = 'AUTH_ERROR',
  });
}

/// Invalid phone number format
class InvalidPhoneFailure extends Failure {
  const InvalidPhoneFailure({
    super.message = 'Please enter a valid phone number.',
    super.code = 'INVALID_PHONE',
  });
}

/// Invalid OTP code
class InvalidOtpFailure extends Failure {
  const InvalidOtpFailure({
    super.message = 'Invalid verification code. Please try again.',
    super.code = 'INVALID_OTP',
  });
}

/// OTP expired
class OtpExpiredFailure extends Failure {
  const OtpExpiredFailure({
    super.message = 'Verification code has expired. Please request a new one.',
    super.code = 'OTP_EXPIRED',
  });
}

/// User not found
class UserNotFoundFailure extends Failure {
  const UserNotFoundFailure({
    super.message = 'User not found.',
    super.code = 'USER_NOT_FOUND',
  });
}

// ═══════════════════════════════════════════════════════════
// LOCATION FAILURES
// ═══════════════════════════════════════════════════════════

/// Location permission denied
class LocationPermissionFailure extends Failure {
  const LocationPermissionFailure({
    super.message = 'Location permission is required to find nearby users.',
    super.code = 'LOCATION_PERMISSION_DENIED',
  });
}

/// Location services disabled
class LocationServiceFailure extends Failure {
  const LocationServiceFailure({
    super.message = 'Please enable location services to continue.',
    super.code = 'LOCATION_DISABLED',
  });
}

/// Unable to get current location
class LocationUnavailableFailure extends Failure {
  const LocationUnavailableFailure({
    super.message = 'Unable to determine your location. Please try again.',
    super.code = 'LOCATION_UNAVAILABLE',
  });
}

// ═══════════════════════════════════════════════════════════
// REQUEST FAILURES
// ═══════════════════════════════════════════════════════════

/// Ride request expired
class RequestExpiredFailure extends Failure {
  const RequestExpiredFailure({
    super.message = 'This request has expired.',
    super.code = 'REQUEST_EXPIRED',
  });
}

/// Request already handled
class RequestAlreadyHandledFailure extends Failure {
  const RequestAlreadyHandledFailure({
    super.message = 'This request has already been handled.',
    super.code = 'REQUEST_HANDLED',
  });
}

// ═══════════════════════════════════════════════════════════
// PERMISSION FAILURES
// ═══════════════════════════════════════════════════════════

/// Camera permission denied
class CameraPermissionFailure extends Failure {
  const CameraPermissionFailure({
    super.message = 'Camera permission is required for QR scanning.',
    super.code = 'CAMERA_PERMISSION_DENIED',
  });
}

/// NFC not available
class NfcUnavailableFailure extends Failure {
  const NfcUnavailableFailure({
    super.message = 'NFC is not available on this device.',
    super.code = 'NFC_UNAVAILABLE',
  });
}

// ═══════════════════════════════════════════════════════════
// VALIDATION FAILURES
// ═══════════════════════════════════════════════════════════

/// Input validation failed
class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.code = 'VALIDATION_ERROR',
  });
}
