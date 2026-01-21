import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/nearby_user.dart';

/// Parameters for fetching nearby users
class NearbyUsersParams {
  /// User's current latitude
  final double latitude;

  /// User's current longitude
  final double longitude;

  /// Search radius in kilometers
  final double radiusKm;

  /// Filter by role: 'driver', 'passenger', or null for all
  final String? role;

  /// Filter by vehicle categories
  final List<String>? vehicleCategories;

  /// Search query for semantic search
  final String? searchQuery;

  /// Page number for pagination
  final int page;

  /// Number of results per page
  final int pageSize;

  /// ID of current user to exclude from results
  final String? excludeUserId;

  const NearbyUsersParams({
    required this.latitude,
    required this.longitude,
    this.radiusKm = 10.0,
    this.role,
    this.vehicleCategories,
    this.searchQuery,
    this.page = 1,
    this.pageSize = 20,
    this.excludeUserId,
  });

  NearbyUsersParams copyWith({
    double? latitude,
    double? longitude,
    double? radiusKm,
    String? role,
    List<String>? vehicleCategories,
    String? searchQuery,
    int? page,
    int? pageSize,
    String? excludeUserId,
  }) {
    return NearbyUsersParams(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusKm: radiusKm ?? this.radiusKm,
      role: role ?? this.role,
      vehicleCategories: vehicleCategories ?? this.vehicleCategories,
      searchQuery: searchQuery ?? this.searchQuery,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      excludeUserId: excludeUserId ?? this.excludeUserId,
    );
  }
}

/// Result of fetching nearby users with pagination info
class NearbyUsersResult {
  final List<NearbyUser> users;
  final bool hasMore;
  final int totalCount;

  const NearbyUsersResult({
    required this.users,
    required this.hasMore,
    this.totalCount = 0,
  });
}

/// Abstract repository interface for discovery operations
abstract class DiscoveryRepository {
  /// Fetch nearby users based on location and filters
  Future<Either<Failure, NearbyUsersResult>> getNearbyUsers(
    NearbyUsersParams params,
  );

  /// Subscribe to realtime updates for nearby users
  /// Returns a stream of user updates
  Stream<Either<Failure, List<NearbyUser>>> watchNearbyUsers(
    NearbyUsersParams params,
  );

  /// Toggle the current user's online status
  Future<Either<Failure, bool>> toggleOnlineStatus(bool isOnline);

  /// Update the current user's location
  Future<Either<Failure, void>> updateLocation({
    required double latitude,
    required double longitude,
    double? accuracy,
    double? heading,
    double? speed,
  });

  /// Get the current user's online status
  Future<Either<Failure, bool>> getOnlineStatus();

  /// Search users by name or other criteria
  Future<Either<Failure, List<NearbyUser>>> searchUsers(String query);
}
