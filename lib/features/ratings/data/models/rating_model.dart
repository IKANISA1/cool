import '../../domain/entities/rating.dart';

/// Rating model for data layer with JSON serialization
class RatingModel extends Rating {
  const RatingModel({
    required super.id,
    required super.fromUserId,
    required super.toUserId,
    required super.rating,
    super.review,
    super.tripId,
    required super.createdAt,
    super.fromUserName,
    super.fromUserAvatar,
  });

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    final fromUser = json['from_user'] as Map<String, dynamic>?;
    
    return RatingModel(
      id: json['id'] as String,
      fromUserId: json['from_user_id'] as String,
      toUserId: json['to_user_id'] as String,
      rating: json['rating'] as int,
      review: json['review'] as String?,
      tripId: json['trip_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      fromUserName: fromUser?['name'] as String?,
      fromUserAvatar: fromUser?['avatar_url'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from_user_id': fromUserId,
      'to_user_id': toUserId,
      'rating': rating,
      'review': review,
      'trip_id': tripId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Rating toEntity() => Rating(
        id: id,
        fromUserId: fromUserId,
        toUserId: toUserId,
        rating: rating,
        review: review,
        tripId: tripId,
        createdAt: createdAt,
        fromUserName: fromUserName,
        fromUserAvatar: fromUserAvatar,
      );
}
