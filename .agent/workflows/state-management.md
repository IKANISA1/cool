---
description: 
---

/state-management

Implement complete Riverpod state management:

1. PROVIDERS SETUP
   Create providers for:
   
   a) authStateProvider
      - User authentication state
      - Profile completion status
      - User ID and phone
      - Sign in/out methods
   
   b) nearbyUsersProvider
      - List of nearby drivers/passengers
      - Auto-refresh every 30s
      - Filter by role
      - Distance sorting
   
   c) presenceProvider
      - Online/offline status
      - Location updates
      - Auto-update location
   
   d) activeRequestProvider
      - Current ride request
      - Countdown timer
      - Accept/deny methods
   
   e) scheduledTripsProvider
      - User's scheduled trips
      - Add/edit/delete methods
      - Fetch from Supabase
   
   f) Service Providers
      - supabaseServiceProvider
      - geminiServiceProvider
      - locationServiceProvider
      - qrServiceProvider
      - nfcServiceProvider
      - speechServiceProvider

2. STATE NOTIFIERS
   For each provider, create StateNotifier:
   - Immutable state classes
   - copyWith methods
   - State transitions
   - Error handling
   - Loading states

3. MODELS
   Create data models:
   - UserProfile
   - NearbyUser
   - RideRequest
   - ScheduledTrip
   - Vehicle
   
   Each with:
   - toJson/fromJson methods
   - Validation
   - Equality override
   - toString for debugging

4. REPOSITORIES
   Create repository pattern:
   - AuthRepository
   - UserRepository
   - RideRepository
   - ScheduleRepository
   
   Methods:
   - CRUD operations
   - Error handling
   - Type-safe responses

5. USE CASES
   Implement use cases:
   - SignInWithOtpUseCase
   - GetNearbyUsersUseCase
   - SendRideRequestUseCase
   - ScheduleTripUseCase

6. PERSISTENCE
   - Hive setup for offline data
   - Shared preferences for settings
   - Cache strategies

Testing:
- Unit tests for each provider
- Mock repositories
- State transition tests
- Integration tests

Artifacts:
- State management architecture diagram
- Provider dependency graph
- Testing coverage report