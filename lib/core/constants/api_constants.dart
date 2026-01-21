/// API endpoint constants
class ApiConstants {
  ApiConstants._();

  // ═══════════════════════════════════════════════════════════
  // SUPABASE TABLES
  // ═══════════════════════════════════════════════════════════

  static const String usersTable = 'users';
  static const String profilesTable = 'profiles';
  static const String vehiclesTable = 'vehicles';
  static const String presenceTable = 'presence';
  static const String rideRequestsTable = 'ride_requests';
  static const String scheduledTripsTable = 'scheduled_trips';
  static const String blocksReportsTable = 'blocks_reports';
  static const String auditEventsTable = 'audit_events';

  // ═══════════════════════════════════════════════════════════
  // SUPABASE FUNCTIONS
  // ═══════════════════════════════════════════════════════════

  static const String nearbyUsersFunction = 'nearby_users';
  static const String expireRequestsFunction = 'expire_old_requests';

  // ═══════════════════════════════════════════════════════════
  // SUPABASE STORAGE BUCKETS
  // ═══════════════════════════════════════════════════════════

  static const String avatarsBucket = 'avatars';
  static const String vehicleImagesBucket = 'vehicle-images';
  static const String documentsBucket = 'documents';

  // ═══════════════════════════════════════════════════════════
  // REALTIME CHANNELS
  // ═══════════════════════════════════════════════════════════

  static const String presenceChannel = 'presence-channel';
  static const String requestsChannel = 'requests-channel';
  static const String tripsChannel = 'trips-channel';

  // ═══════════════════════════════════════════════════════════
  // REQUEST STATUSES
  // ═══════════════════════════════════════════════════════════

  static const String statusPending = 'pending';
  static const String statusAccepted = 'accepted';
  static const String statusDenied = 'denied';
  static const String statusExpired = 'expired';

  // ═══════════════════════════════════════════════════════════
  // TRIP TYPES
  // ═══════════════════════════════════════════════════════════

  static const String tripTypeOffer = 'offer';
  static const String tripTypeRequest = 'request';
}
