import '../../domain/entities/profile.dart';

/// Profile data model for Supabase serialization
class ProfileModel extends Profile {
  const ProfileModel({
    required super.id,
    required super.userId,
    required super.name,
    required super.role,
    required super.countryCode,
    super.languages = const [],
    super.vehicleCategory,
    super.avatarUrl,
    super.phoneNumber,
    super.isVerified = false,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Create from JSON (Supabase response)
  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    return ProfileModel(
      id: id,
      userId: id, // In schema, id IS the user_id (FK to auth.users)
      name: json['name'] as String? ?? '',
      role: UserRole.fromString(json['role'] as String? ?? 'passenger'),
      countryCode: json['country'] as String? ?? 'RWA',
      languages: (json['languages'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      vehicleCategory:
          VehicleCategory.fromString(json['vehicle_category'] as String?),
      avatarUrl: json['avatar_url'] as String?,
      phoneNumber: json['phone_number'] as String?,
      isVerified: json['verified'] as bool? ?? false,
      createdAt: DateTime.parse(
          json['created_at'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updated_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  /// Convert to JSON for Supabase insert/update
  Map<String, dynamic> toJson() {
    return {
      'id': id, // id is also the user_id in schema
      'name': name,
      'role': role.name,
      'country': countryCode,
      'languages': languages,
      'vehicle_category': vehicleCategory?.name,
      'avatar_url': avatarUrl,
      'phone_number': phoneNumber,
      'verified': isVerified,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convert to JSON for create (without created_at - use id as the auth user's id)
  Map<String, dynamic> toCreateJson() {
    return {
      'id': userId, // id = auth user id
      'name': name,
      'role': role.name,
      'country': countryCode,
      'languages': languages,
      'vehicle_category': vehicleCategory?.name,
      'avatar_url': avatarUrl,
      'phone_number': phoneNumber,
    };
  }

  /// Convert to JSON for update (only changed fields)
  static Map<String, dynamic> toUpdateJson({
    String? name,
    UserRole? role,
    String? countryCode,
    List<String>? languages,
    VehicleCategory? vehicleCategory,
    String? avatarUrl,
    String? phoneNumber,
  }) {
    final json = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (name != null) json['name'] = name;
    if (role != null) json['role'] = role.name;
    if (countryCode != null) json['country'] = countryCode;
    if (languages != null) json['languages'] = languages;
    if (vehicleCategory != null) json['vehicle_category'] = vehicleCategory.name;
    if (avatarUrl != null) json['avatar_url'] = avatarUrl;
    if (phoneNumber != null) json['phone_number'] = phoneNumber;

    return json;
  }

  /// Convert from entity to model
  factory ProfileModel.fromEntity(Profile profile) {
    return ProfileModel(
      id: profile.id,
      userId: profile.userId,
      name: profile.name,
      role: profile.role,
      countryCode: profile.countryCode,
      languages: profile.languages,
      vehicleCategory: profile.vehicleCategory,
      avatarUrl: profile.avatarUrl,
      phoneNumber: profile.phoneNumber,
      isVerified: profile.isVerified,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
    );
  }
}
