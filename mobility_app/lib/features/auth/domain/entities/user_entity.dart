import 'package:equatable/equatable.dart';

/// User entity representing an authenticated user
///
/// This is the domain layer representation of a user.
/// It contains the core user data without any framework dependencies.
class UserEntity extends Equatable {
  final String id;
  final String phone;
  final String? name;
  final String? avatarUrl;
  final String role; // 'driver', 'passenger', 'both'
  final double rating;
  final bool verified;
  final bool isAnonymous;
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.phone,
    this.name,
    this.avatarUrl,
    this.role = 'passenger',
    this.rating = 0.0,
    this.verified = false,
    this.isAnonymous = false,
    required this.createdAt,
  });

  /// Check if user has completed profile setup
  bool get hasCompletedProfile => name != null && name!.isNotEmpty;

  /// Check if user is a driver
  bool get isDriver => role == 'driver' || role == 'both';

  /// Check if user is a passenger
  bool get isPassenger => role == 'passenger' || role == 'both';

  /// Create an empty user (for initial state)
  factory UserEntity.empty() => UserEntity(
        id: '',
        phone: '',
        isAnonymous: false,
        createdAt: DateTime.now(),
      );

  /// Check if user is empty/not authenticated
  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => !isEmpty;

  @override
  List<Object?> get props => [
        id,
        phone,
        name,
        avatarUrl,
        role,
        rating,
        verified,
        isAnonymous,
        createdAt,
      ];
}
