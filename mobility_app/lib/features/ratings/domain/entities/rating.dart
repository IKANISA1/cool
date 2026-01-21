import 'package:equatable/equatable.dart';

/// Rating entity representing a user rating/review
class Rating extends Equatable {
  final String id;
  final String fromUserId;
  final String toUserId;
  final int rating;
  final String? review;
  final String? tripId;
  final DateTime createdAt;

  // Joined data (optional, for display)
  final String? fromUserName;
  final String? fromUserAvatar;

  const Rating({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.rating,
    this.review,
    this.tripId,
    required this.createdAt,
    this.fromUserName,
    this.fromUserAvatar,
  });

  @override
  List<Object?> get props => [
        id,
        fromUserId,
        toUserId,
        rating,
        review,
        tripId,
        createdAt,
      ];

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      id: json['id'] as String,
      fromUserId: json['from_user_id'] as String,
      toUserId: json['to_user_id'] as String,
      rating: json['rating'] as int,
      review: json['review'] as String?,
      tripId: json['trip_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      fromUserName: json['from_user']?['name'] as String?,
      fromUserAvatar: json['from_user']?['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from_user_id': fromUserId,
      'to_user_id': toUserId,
      'rating': rating,
      'review': review,
      'trip_id': tripId,
    };
  }
}
