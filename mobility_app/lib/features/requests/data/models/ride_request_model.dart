import '../../domain/entities/ride_request.dart';

/// Data model for ride request with JSON serialization
class RideRequestModel extends RideRequest {
  const RideRequestModel({
    required super.id,
    required super.fromUserId,
    required super.toUserId,
    required super.payload,
    required super.status,
    required super.createdAt,
    required super.expiresAt,
    super.respondedAt,
    super.fromUser,
    super.toUser,
  });

  /// Create from Supabase row response
  factory RideRequestModel.fromSupabaseRow(Map<String, dynamic> row) {
    return RideRequestModel(
      id: row['id'] as String,
      fromUserId: row['from_user'] as String,
      toUserId: row['to_user'] as String,
      payload: (row['payload'] as Map<String, dynamic>?) ?? {},
      status: row['status'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      expiresAt: DateTime.parse(row['expires_at'] as String),
      respondedAt: row['responded_at'] != null
          ? DateTime.parse(row['responded_at'] as String)
          : null,
      fromUser: row['from_profile'] != null
          ? RequestUserInfoModel.fromMap(row['from_profile'] as Map<String, dynamic>)
          : null,
      toUser: row['to_profile'] != null
          ? RequestUserInfoModel.fromMap(row['to_profile'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convert to JSON for caching
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from_user': fromUserId,
      'to_user': toUserId,
      'payload': payload,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'responded_at': respondedAt?.toIso8601String(),
    };
  }

  /// Create from JSON (cached data)
  factory RideRequestModel.fromJson(Map<String, dynamic> json) {
    return RideRequestModel(
      id: json['id'] as String,
      fromUserId: json['from_user'] as String,
      toUserId: json['to_user'] as String,
      payload: (json['payload'] as Map<String, dynamic>?) ?? {},
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      respondedAt: json['responded_at'] != null
          ? DateTime.parse(json['responded_at'] as String)
          : null,
    );
  }
}

/// Data model for user info in requests
class RequestUserInfoModel extends RequestUserInfo {
  const RequestUserInfoModel({
    required super.id,
    required super.name,
    required super.phone,
    super.avatarUrl,
    required super.rating,
    super.vehicleCategory,
  });

  factory RequestUserInfoModel.fromMap(Map<String, dynamic> map) {
    return RequestUserInfoModel(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'Unknown',
      phone: map['phone'] as String? ?? '',
      avatarUrl: map['avatar_url'] as String?,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      vehicleCategory: map['vehicle_category'] as String?,
    );
  }
}
