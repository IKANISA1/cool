import 'package:equatable/equatable.dart';

/// Domain entity representing a station review
class StationReview extends Equatable {
  /// Unique identifier
  final String id;

  /// User ID who submitted the review
  final String userId;

  /// Station type (battery_swap or ev_charging)
  final String stationType;

  /// Station ID being reviewed
  final String stationId;

  /// Overall rating (1-5)
  final int rating;

  /// Review comment
  final String? comment;

  /// Service quality rating (1-5)
  final int? serviceQuality;

  /// Wait time in minutes
  final int? waitTimeMinutes;

  /// Price rating (1-5)
  final int? priceRating;

  /// Number of users who found this review helpful
  final int helpfulCount;

  /// Created timestamp
  final DateTime createdAt;

  /// Updated timestamp
  final DateTime? updatedAt;

  /// User name (for display)
  final String? userName;

  /// User avatar URL (for display)
  final String? userAvatarUrl;

  const StationReview({
    required this.id,
    required this.userId,
    required this.stationType,
    required this.stationId,
    required this.rating,
    this.comment,
    this.serviceQuality,
    this.waitTimeMinutes,
    this.priceRating,
    this.helpfulCount = 0,
    required this.createdAt,
    this.updatedAt,
    this.userName,
    this.userAvatarUrl,
  });

  /// Get relative time since review was posted
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        stationType,
        stationId,
        rating,
        comment,
        serviceQuality,
        waitTimeMinutes,
        priceRating,
        helpfulCount,
        createdAt,
        updatedAt,
        userName,
        userAvatarUrl,
      ];

  StationReview copyWith({
    String? id,
    String? userId,
    String? stationType,
    String? stationId,
    int? rating,
    String? comment,
    int? serviceQuality,
    int? waitTimeMinutes,
    int? priceRating,
    int? helpfulCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userName,
    String? userAvatarUrl,
  }) {
    return StationReview(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      stationType: stationType ?? this.stationType,
      stationId: stationId ?? this.stationId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      serviceQuality: serviceQuality ?? this.serviceQuality,
      waitTimeMinutes: waitTimeMinutes ?? this.waitTimeMinutes,
      priceRating: priceRating ?? this.priceRating,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
    );
  }
}
