import '../../domain/entities/user_entity.dart';

/// User model for data layer
///
/// This model handles JSON serialization/deserialization
/// and maps to/from the domain entity.
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.phone,
    super.name,
    super.avatarUrl,
    super.role,
    super.rating,
    super.verified,
    super.isAnonymous,
    required super.createdAt,
  });

  /// Create from Supabase user + profile data
  factory UserModel.fromSupabase({
    required Map<String, dynamic> user,
    Map<String, dynamic>? profile,
  }) {
    return UserModel(
      id: user['id'] as String,
      phone: user['phone'] as String? ?? '',
      name: profile?['name'] as String?,
      avatarUrl: profile?['avatar_url'] as String?,
      role: profile?['role'] as String? ?? 'passenger',
      rating: (profile?['rating'] as num?)?.toDouble() ?? 0.0,
      verified: profile?['verified'] as bool? ?? false,
      isAnonymous: user['is_anonymous'] as bool? ?? false,
      createdAt: user['created_at'] != null
          ? DateTime.parse(user['created_at'] as String)
          : DateTime.now(),
    );
  }

  /// Create from JSON map
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      phone: json['phone'] as String? ?? '',
      name: (json['name'] ?? json['display_name']) as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String? ?? 'passenger',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      verified: json['verified'] as bool? ?? false,
      isAnonymous: json['is_anonymous'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'name': name,
      'avatar_url': avatarUrl,
      'role': role,
      'rating': rating,
      'verified': verified,
      'is_anonymous': isAnonymous,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create from domain entity
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      phone: entity.phone,
      name: entity.name,
      avatarUrl: entity.avatarUrl,
      role: entity.role,
      rating: entity.rating,
      verified: entity.verified,
      isAnonymous: entity.isAnonymous,
      createdAt: entity.createdAt,
    );
  }

  /// Copy with new values
  UserModel copyWith({
    String? id,
    String? phone,
    String? name,
    String? avatarUrl,
    String? role,
    double? rating,
    bool? verified,
    bool? isAnonymous,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      rating: rating ?? this.rating,
      verified: verified ?? this.verified,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
