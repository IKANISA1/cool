import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/rating_model.dart';

/// Remote data source for ratings using Supabase
class RatingsRemoteDataSource {
  final SupabaseClient _supabase;

  RatingsRemoteDataSource(this._supabase);

  /// Get all ratings for a user with reviewer info
  Future<List<RatingModel>> getRatingsForUser(String userId) async {
    final response = await _supabase
        .from('ratings')
        .select('''
          *,
          from_user:profiles!ratings_from_user_id_fkey(name, avatar_url)
        ''')
        .eq('to_user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => RatingModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get rating stats for a user
  Future<Map<String, dynamic>> getUserRatingStats(String userId) async {
    final response = await _supabase
        .from('ratings')
        .select('rating')
        .eq('to_user_id', userId);

    final ratings = (response as List).map((r) => r['rating'] as int).toList();

    if (ratings.isEmpty) {
      return {'average': 0.0, 'count': 0};
    }

    final average = ratings.reduce((a, b) => a + b) / ratings.length;
    return {
      'average': double.parse(average.toStringAsFixed(2)),
      'count': ratings.length,
    };
  }

  /// Create a new rating
  Future<RatingModel> createRating({
    required String toUserId,
    required int rating,
    String? review,
    String? tripId,
  }) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final response = await _supabase
        .from('ratings')
        .insert({
          'from_user_id': currentUserId,
          'to_user_id': toUserId,
          'rating': rating,
          'review': review,
          'trip_id': tripId,
        })
        .select()
        .single();

    return RatingModel.fromJson(response);
  }

  /// Check if user has already rated
  Future<bool> hasRated({
    required String toUserId,
    String? tripId,
  }) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return false;

    var query = _supabase
        .from('ratings')
        .select('id')
        .eq('from_user_id', currentUserId)
        .eq('to_user_id', toUserId);

    if (tripId != null) {
      query = query.eq('trip_id', tripId);
    }

    final response = await query.maybeSingle();
    return response != null;
  }
}
