import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../config/env_config.dart';
import '../network/network_info.dart';
import '../../shared/services/gemini_service.dart';
import '../services/location_service.dart';
import '../services/permission_service.dart';
import '../services/supabase_service.dart';
import '../services/connectivity_service.dart';
import '../services/presence_service.dart';
import '../services/speech_service.dart';
import '../bloc/app/app_bloc.dart';

// Auth feature imports
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/get_current_user.dart';
import '../../features/auth/domain/usecases/sign_out.dart';
import '../../features/auth/domain/usecases/sign_in_anonymously.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

// Profile feature imports
import '../../features/profile/data/datasources/profile_remote_datasource.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/domain/usecases/create_profile.dart';
import '../../features/profile/domain/usecases/get_profile.dart';
import '../../features/profile/domain/usecases/update_profile.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';

// Discovery feature imports
import '../../features/discovery/data/datasources/discovery_remote_datasource.dart';
import '../../features/discovery/data/repositories/discovery_repository_impl.dart';
import '../../features/discovery/domain/repositories/discovery_repository.dart';
import '../../features/discovery/domain/usecases/get_nearby_users.dart';
import '../../features/discovery/domain/usecases/toggle_online_status.dart';
import '../../features/discovery/domain/usecases/update_user_location.dart';
import '../../features/discovery/presentation/bloc/discovery_bloc.dart';

// Requests feature imports
import '../../features/requests/data/datasources/request_remote_datasource.dart';
import '../../features/requests/data/repositories/request_repository_impl.dart';
import '../../features/requests/domain/repositories/request_repository.dart';
import '../../features/requests/domain/usecases/get_pending_requests.dart';
import '../../features/requests/domain/usecases/respond_to_request.dart';
import '../../features/requests/domain/usecases/send_ride_request.dart';
import '../../features/requests/presentation/bloc/request_bloc.dart';

// Scheduling feature imports
import '../../features/scheduling/data/datasources/scheduling_remote_datasource.dart';
import '../../features/scheduling/data/repositories/scheduling_repository_impl.dart';
import '../../features/scheduling/domain/repositories/scheduling_repository.dart';
import '../../features/scheduling/domain/usecases/create_scheduled_trip.dart';
import '../../features/scheduling/domain/usecases/get_scheduled_trips.dart';
import '../../features/scheduling/domain/usecases/manage_scheduled_trip.dart';
import '../../features/scheduling/presentation/bloc/scheduling_bloc.dart';

// AI Assistant feature imports
import '../../features/ai_assistant/data/datasources/ai_assistant_remote_datasource.dart';
import '../../features/ai_assistant/data/repositories/ai_assistant_repository_impl.dart';
import '../../features/ai_assistant/domain/repositories/ai_assistant_repository.dart';
import '../../features/ai_assistant/domain/usecases/generate_trip_suggestions.dart';
import '../../features/ai_assistant/domain/usecases/parse_trip_intent.dart';

import '../../features/ai_assistant/presentation/bloc/ai_assistant_bloc.dart';

// Payment feature imports
import '../../features/payment/data/datasources/payment_remote_datasource.dart';
import '../../features/payment/data/repositories/payment_repository_impl.dart';
import '../../features/payment/domain/repositories/payment_repository.dart';
import '../../features/payment/domain/usecases/process_payment.dart';
import '../../features/payment/presentation/bloc/payment_bloc.dart';

// NFC & Haptics imports
import '../../features/nfc/data/services/nfc_service.dart';
import '../../features/nfc/presentation/bloc/nfc_bloc.dart';
import '../../features/haptics/data/services/haptics_service.dart';
import '../../features/haptics/presentation/bloc/haptics_cubit.dart';

// Ratings feature imports
import '../../features/ratings/data/datasources/ratings_remote_data_source.dart';
import '../../features/ratings/data/repositories/ratings_repository_impl.dart';
import '../../features/ratings/domain/repositories/ratings_repository.dart';
import '../../features/ratings/presentation/bloc/ratings_bloc.dart';

// Mobile Money feature imports
import '../../features/utilities/mobile_money/domain/mobile_money_repository.dart';
import '../../features/utilities/mobile_money/data/mobile_money_repository_impl.dart';

// Station Locator feature imports
import '../../features/station_locator/data/datasources/station_remote_datasource.dart';
import '../../features/station_locator/data/repositories/station_repository_impl.dart';
import '../../features/station_locator/domain/repositories/station_repository.dart';
import '../../features/station_locator/presentation/bloc/station_locator_bloc.dart';

/// Global service locator instance
final GetIt getIt = GetIt.instance;



/// Initialize all dependencies
///
/// Call this before runApp() after loading environment config.
@InjectableInit()
Future<void> configureDependencies() async {
  // ═══════════════════════════════════════════════════════════
  // CORE SERVICES (Singletons)
  // ═══════════════════════════════════════════════════════════

  // Connectivity (External)
  getIt.registerLazySingleton<Connectivity>(() => Connectivity());

  // Network info
  getIt.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(getIt<Connectivity>()),
  );

  // Supabase service
  await _initSupabase();
  getIt.registerLazySingleton<SupabaseService>(
    () => SupabaseService(getIt<SupabaseClient>()),
  );

  // Gemini AI service
  getIt.registerLazySingleton<GeminiService>(
    () => GeminiService(),
  );

  // Location service
  getIt.registerLazySingleton<LocationService>(
    () => LocationServiceImpl(),
  );

  // Permission service
  getIt.registerLazySingleton<PermissionService>(
    () => PermissionServiceImpl(),
  );

  // Connectivity service
  getIt.registerLazySingleton<ConnectivityService>(
    () => ConnectivityService(),
  );

  // Presence service
  getIt.registerLazySingleton<PresenceService>(
    () => PresenceService(
      client: getIt<SupabaseClient>(),
      locationService: getIt<LocationService>(),
    ),
  );

  // Speech service
  getIt.registerLazySingleton<SpeechService>(
    () => SpeechService(),
  );

  // ═══════════════════════════════════════════════════════════
  // FEATURE-SPECIFIC DEPENDENCIES
  // ═══════════════════════════════════════════════════════════

  // Auth Feature
  _registerAuthDependencies();

  // Profile Feature
  _registerProfileDependencies();

  // Discovery Feature
  _registerDiscoveryDependencies();

  // Requests Feature
  _registerRequestDependencies();

  // Scheduling Feature
  _registerSchedulingDependencies();

  // AI Assistant Feature
  _registerAIAssistantDependencies();

  // Payment Feature
  _registerPaymentDependencies();

  // NFC & Haptics Feature
  _registerNFCAndHapticsDependencies();

  // Ratings Feature
  _registerRatingsDependencies();

  // Mobile Money Feature (for countries)
  _registerMobileMoneyDependencies();

  // Station Locator Feature
  _registerStationLocatorDependencies();
}

/// Register Auth feature dependencies
void _registerAuthDependencies() {
  // Data sources
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(getIt<SupabaseClient>()),
  );

  // Repository
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: getIt<AuthRemoteDataSource>(),
      networkInfo: getIt<NetworkInfo>(),
    ),
  );

  // Use cases
  getIt.registerLazySingleton(() => SignOutUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => GetCurrentUserUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => SignInAnonymouslyUseCase(getIt<AuthRepository>()));

  // Bloc
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(
      signOut: getIt<SignOutUseCase>(),
      getCurrentUser: getIt<GetCurrentUserUseCase>(),
      signInAnonymously: getIt<SignInAnonymouslyUseCase>(),
      authRepository: getIt<AuthRepository>(),
    ),
  );
}

/// Register Profile feature dependencies
void _registerProfileDependencies() {
  // Data sources
  getIt.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(getIt<SupabaseClient>()),
  );

  // Repository
  getIt.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(
      remoteDataSource: getIt<ProfileRemoteDataSource>(),
      networkInfo: getIt<NetworkInfo>(),
    ),
  );

  // Use cases
  getIt.registerLazySingleton(() => CreateProfile(getIt<ProfileRepository>()));
  getIt.registerLazySingleton(() => GetProfile(getIt<ProfileRepository>()));
  getIt.registerLazySingleton(() => UpdateProfile(getIt<ProfileRepository>()));

  // Bloc (Factory - new instance each time)
  getIt.registerFactory<ProfileBloc>(
    () => ProfileBloc(
      getProfile: getIt<GetProfile>(),
      createProfile: getIt<CreateProfile>(),
      updateProfile: getIt<UpdateProfile>(),
      repository: getIt<ProfileRepository>(),
    ),
  );
}

/// Register Discovery feature dependencies
void _registerDiscoveryDependencies() {
  // Data sources
  getIt.registerLazySingleton<DiscoveryRemoteDataSource>(
    () => DiscoveryRemoteDataSourceImpl(getIt<SupabaseClient>()),
  );

  // Repository
  getIt.registerLazySingleton<DiscoveryRepository>(
    () => DiscoveryRepositoryImpl(
      remoteDataSource: getIt<DiscoveryRemoteDataSource>(),
    ),
  );

  // Use cases
  getIt.registerLazySingleton(() => GetNearbyUsers(getIt<DiscoveryRepository>()));
  getIt.registerLazySingleton(() => ToggleOnlineStatus(getIt<DiscoveryRepository>()));
  getIt.registerLazySingleton(() => UpdateUserLocation(getIt<DiscoveryRepository>()));

  // Bloc (Factory - new instance each time)
  getIt.registerFactory<DiscoveryBloc>(
    () => DiscoveryBloc(
      getNearbyUsers: getIt<GetNearbyUsers>(),
      toggleOnlineStatus: getIt<ToggleOnlineStatus>(),
      updateUserLocation: getIt<UpdateUserLocation>(),
    ),
  );
}

/// Register Requests feature dependencies
void _registerRequestDependencies() {
  // Data sources
  getIt.registerLazySingleton<RequestRemoteDataSource>(
    () => RequestRemoteDataSourceImpl(getIt<SupabaseClient>()),
  );

  // Repository
  getIt.registerLazySingleton<RequestRepository>(
    () => RequestRepositoryImpl(
      remoteDataSource: getIt<RequestRemoteDataSource>(),
    ),
  );

  // Use cases
  getIt.registerLazySingleton(() => SendRideRequest(getIt<RequestRepository>()));
  getIt.registerLazySingleton(() => RespondToRequest(getIt<RequestRepository>()));
  getIt.registerLazySingleton(() => GetPendingRequests(getIt<RequestRepository>()));

  // Bloc (Factory - new instance each time)
  getIt.registerFactory<RequestBloc>(
    () => RequestBloc(
      sendRideRequest: getIt<SendRideRequest>(),
      respondToRequest: getIt<RespondToRequest>(),
      getPendingRequests: getIt<GetPendingRequests>(),
    ),
  );
}

/// Register Scheduling feature dependencies
void _registerSchedulingDependencies() {
  // Data sources
  getIt.registerLazySingleton<SchedulingRemoteDataSource>(
    () => SchedulingRemoteDataSourceImpl(getIt<SupabaseClient>()),
  );

  // Repository
  getIt.registerLazySingleton<SchedulingRepository>(
    () => SchedulingRepositoryImpl(
      remoteDataSource: getIt<SchedulingRemoteDataSource>(),
    ),
  );

  // Use cases
  getIt.registerLazySingleton(() => CreateScheduledTrip(getIt<SchedulingRepository>()));
  getIt.registerLazySingleton(() => GetScheduledTrips(getIt<SchedulingRepository>()));
  getIt.registerLazySingleton(() => ManageScheduledTrip(getIt<SchedulingRepository>()));

  // Bloc (Factory - new instance each time)
  getIt.registerFactory<SchedulingBloc>(
    () => SchedulingBloc(
      createScheduledTrip: getIt<CreateScheduledTrip>(),
      getScheduledTrips: getIt<GetScheduledTrips>(),
      manageScheduledTrip: getIt<ManageScheduledTrip>(),
    ),
  );
}

/// Register AI Assistant feature dependencies
void _registerAIAssistantDependencies() {
  // Data sources
  getIt.registerLazySingleton<AIAssistantRemoteDataSource>(
    () => AIAssistantRemoteDataSourceImpl(
      getIt<GeminiService>().model,
    ),
  );

  // Repository
  getIt.registerLazySingleton<AIAssistantRepository>(
    () => AIAssistantRepositoryImpl(
      remoteDataSource: getIt<AIAssistantRemoteDataSource>(),
    ),
  );

  // Use cases
  getIt.registerLazySingleton(() => ParseTripIntent(getIt<AIAssistantRepository>()));
  getIt.registerLazySingleton(() => GenerateTripSuggestions(getIt<AIAssistantRepository>()));

  // Bloc (Factory - new instance each time)
  getIt.registerFactory<AIAssistantBloc>(
    () => AIAssistantBloc(
      parseTripIntent: getIt<ParseTripIntent>(),
      generateTripSuggestions: getIt<GenerateTripSuggestions>(),
      speechService: getIt<SpeechService>(),
    ),
  );

  // App global bloc
  getIt.registerFactory<AppBloc>(
    () => AppBloc(getIt<ConnectivityService>()),
  );
}

/// Register Payment feature dependencies
void _registerPaymentDependencies() {
  // Data sources - flutter_paystack_plus handles initialization internally
  getIt.registerLazySingleton<PaymentRemoteDataSource>(
    () => PaymentRemoteDataSourceImpl(),
  );

  // Repository
  getIt.registerLazySingleton<PaymentRepository>(
    () => PaymentRepositoryImpl(remoteDataSource: getIt<PaymentRemoteDataSource>()),
  );

  // Use cases
  getIt.registerLazySingleton(() => ProcessPayment(getIt<PaymentRepository>()));

  // Bloc
  getIt.registerFactory<PaymentBloc>(
    () => PaymentBloc(
      paymentRepository: getIt<PaymentRepository>(),
      processPayment: getIt<ProcessPayment>(),
    ),
  );
}



/// Register NFC & Haptics dependencies
void _registerNFCAndHapticsDependencies() {
  // Services
  getIt.registerLazySingleton<NFCService>(() => NFCService());
  getIt.registerLazySingleton<HapticsService>(() => HapticsService());

  // Blocs
  getIt.registerFactory<NFCBloc>(() => NFCBloc(getIt<NFCService>()));
  getIt.registerFactory<HapticsCubit>(() => HapticsCubit(getIt<HapticsService>()));
}

/// Register Ratings feature dependencies
void _registerRatingsDependencies() {
  // Data sources
  getIt.registerLazySingleton<RatingsRemoteDataSource>(
    () => RatingsRemoteDataSource(getIt<SupabaseClient>()),
  );

  // Repository
  getIt.registerLazySingleton<RatingsRepository>(
    () => RatingsRepositoryImpl(getIt<RatingsRemoteDataSource>()),
  );

  // Bloc (Factory - new instance each time)
  getIt.registerFactory<RatingsBloc>(
    () => RatingsBloc(getIt<RatingsRepository>()),
  );
}

/// Initialize Supabase client
Future<void> _initSupabase() async {
  await Supabase.initialize(
    url: EnvConfig.supabaseUrl,
    anonKey: EnvConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
    realtimeClientOptions: const RealtimeClientOptions(
      eventsPerSecond: 10,
    ),
  );

  getIt.registerSingleton<SupabaseClient>(Supabase.instance.client);
}

/// Register Mobile Money feature dependencies (for countries)
void _registerMobileMoneyDependencies() {
  getIt.registerLazySingleton<MobileMoneyRepository>(
    () => MobileMoneyRepositoryImpl(getIt<SupabaseClient>()),
  );
}

/// Register Station Locator feature dependencies
void _registerStationLocatorDependencies() {
  // Data sources
  getIt.registerLazySingleton<StationRemoteDataSource>(
    () => StationRemoteDataSource(getIt<SupabaseClient>()),
  );

  // Repository
  getIt.registerLazySingleton<StationRepository>(
    () => StationRepositoryImpl(getIt<StationRemoteDataSource>()),
  );

  // Bloc (Factory - new instance each time)
  getIt.registerFactory<StationLocatorBloc>(
    () => StationLocatorBloc(
      locationService: getIt<LocationService>(),
      repository: getIt<StationRepository>(),
    ),
  );
}


/// Reset dependencies (useful for testing)
Future<void> resetDependencies() async {
  await getIt.reset();
}
