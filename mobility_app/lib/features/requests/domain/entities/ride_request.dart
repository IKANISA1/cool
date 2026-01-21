import 'package:equatable/equatable.dart';

/// Domain entity representing a ride request
///
/// Ride requests expire after 60 seconds if not responded to.
/// Status transitions: pending -> accepted/denied/expired/cancelled
class RideRequest extends Equatable {
  /// Unique identifier
  final String id;

  /// ID of user who sent the request
  final String fromUserId;

  /// ID of user who received the request
  final String toUserId;

  /// Request payload with optional details
  final Map<String, dynamic> payload;

  /// Current status: 'pending', 'accepted', 'denied', 'expired', 'cancelled'
  final String status;

  /// When the request was created
  final DateTime createdAt;

  /// When the request expires
  final DateTime expiresAt;

  /// When the request was responded to (if any)
  final DateTime? respondedAt;

  /// Sender's profile info (populated when fetching)
  final RequestUserInfo? fromUser;

  /// Recipient's profile info (populated when fetching)
  final RequestUserInfo? toUser;

  const RideRequest({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.payload,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.respondedAt,
    this.fromUser,
    this.toUser,
  });

  /// Whether the request has expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Whether the request is still pending
  bool get isPending => status == 'pending' && !isExpired;

  /// Whether the request was accepted
  bool get isAccepted => status == 'accepted';

  /// Whether the request was denied
  bool get isDenied => status == 'denied';

  /// Whether the request was cancelled
  bool get isCancelled => status == 'cancelled';

  /// Seconds remaining until expiration (0 if expired)
  int get secondsRemaining {
    final diff = expiresAt.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  /// Progress from 0.0 to 1.0 based on time remaining
  double get progress {
    const totalSeconds = 60;
    return secondsRemaining / totalSeconds;
  }

  /// Optional note from the request payload
  String? get note => payload['note'] as String?;

  /// Copy with updated fields
  RideRequest copyWith({
    String? id,
    String? fromUserId,
    String? toUserId,
    Map<String, dynamic>? payload,
    String? status,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? respondedAt,
    RequestUserInfo? fromUser,
    RequestUserInfo? toUser,
  }) {
    return RideRequest(
      id: id ?? this.id,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      respondedAt: respondedAt ?? this.respondedAt,
      fromUser: fromUser ?? this.fromUser,
      toUser: toUser ?? this.toUser,
    );
  }

  @override
  List<Object?> get props => [
        id,
        fromUserId,
        toUserId,
        payload,
        status,
        createdAt,
        expiresAt,
        respondedAt,
        fromUser,
        toUser,
      ];
}

/// Basic user info attached to requests
class RequestUserInfo extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String? avatarUrl;
  final double rating;
  final String? vehicleCategory;

  const RequestUserInfo({
    required this.id,
    required this.name,
    required this.phone,
    this.avatarUrl,
    required this.rating,
    this.vehicleCategory,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}';
    }
    return name.isNotEmpty ? name[0] : '?';
  }

  @override
  List<Object?> get props => [id, name, phone, avatarUrl, rating, vehicleCategory];
}
