import 'package:equatable/equatable.dart';

/// User role in the mobility platform
enum UserRole {
  driver,
  passenger,
  both;

  String get displayName {
    switch (this) {
      case UserRole.driver:
        return 'Driver';
      case UserRole.passenger:
        return 'Passenger';
      case UserRole.both:
        return 'Both';
    }
  }

  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'driver':
        return UserRole.driver;
      case 'passenger':
        return UserRole.passenger;
      case 'both':
        return UserRole.both;
      default:
        return UserRole.passenger;
    }
  }
}

/// Vehicle category for drivers
enum VehicleCategory {
  moto,
  cab,
  liffan,
  truck,
  rent,
  other;

  String get displayName {
    switch (this) {
      case VehicleCategory.moto:
        return 'Moto Taxi';
      case VehicleCategory.cab:
        return 'Cab';
      case VehicleCategory.liffan:
        return 'Liffan';
      case VehicleCategory.truck:
        return 'Truck';
      case VehicleCategory.rent:
        return 'Rent';
      case VehicleCategory.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case VehicleCategory.moto:
        return '🏍️';
      case VehicleCategory.cab:
        return '🚗';
      case VehicleCategory.liffan:
        return '🛺';
      case VehicleCategory.truck:
        return '🚛';
      case VehicleCategory.rent:
        return '🚙';
      case VehicleCategory.other:
        return '🚐';
    }
  }

  static VehicleCategory? fromString(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase()) {
      case 'moto':
        return VehicleCategory.moto;
      case 'cab':
        return VehicleCategory.cab;
      case 'liffan':
        return VehicleCategory.liffan;
      case 'truck':
        return VehicleCategory.truck;
      case 'rent':
        return VehicleCategory.rent;
      case 'other':
        return VehicleCategory.other;
      default:
        return null;
    }
  }
}

/// User profile entity
class Profile extends Equatable {
  final String id;
  final String userId;
  final String name;
  final UserRole role;
  final String countryCode;
  final List<String> languages;
  final VehicleCategory? vehicleCategory;
  final String? avatarUrl;
  final String? phoneNumber;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Profile({
    required this.id,
    required this.userId,
    required this.name,
    required this.role,
    required this.countryCode,
    this.languages = const [],
    this.vehicleCategory,
    this.avatarUrl,
    this.phoneNumber,
    this.isVerified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if user can drive (is a driver or both)
  bool get canDrive => role == UserRole.driver || role == UserRole.both;

  /// Check if user needs a vehicle selection
  bool get needsVehicle => canDrive && vehicleCategory == null;

  /// Check if profile is complete
  bool get isComplete =>
      name.isNotEmpty &&
      countryCode.isNotEmpty &&
      (!canDrive || vehicleCategory != null);

  Profile copyWith({
    String? id,
    String? userId,
    String? name,
    UserRole? role,
    String? countryCode,
    List<String>? languages,
    VehicleCategory? vehicleCategory,
    String? avatarUrl,
    String? phoneNumber,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      role: role ?? this.role,
      countryCode: countryCode ?? this.countryCode,
      languages: languages ?? this.languages,
      vehicleCategory: vehicleCategory ?? this.vehicleCategory,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        role,
        countryCode,
        languages,
        vehicleCategory,
        avatarUrl,
        phoneNumber,
        isVerified,
        createdAt,
        updatedAt,
      ];
}
