import 'package:equatable/equatable.dart';

enum AppThemeMode { system, light, dark }
enum ConnectivityStatus { active, offline, unknown }
enum LocationPermissionStatus { granted, denied, unknown, temporary }

class AppState extends Equatable {
  final AppThemeMode themeMode;
  final ConnectivityStatus connectivityStatus;
  final LocationPermissionStatus locationPermissionStatus;
  final bool isFirstRun;
  final String? activeTripId;

  const AppState({
    this.themeMode = AppThemeMode.system,
    this.connectivityStatus = ConnectivityStatus.unknown,
    this.locationPermissionStatus = LocationPermissionStatus.unknown,
    this.isFirstRun = false,
    this.activeTripId,
  });

  AppState copyWith({
    AppThemeMode? themeMode,
    ConnectivityStatus? connectivityStatus,
    LocationPermissionStatus? locationPermissionStatus,
    bool? isFirstRun,
    String? activeTripId,
  }) {
    return AppState(
      themeMode: themeMode ?? this.themeMode,
      connectivityStatus: connectivityStatus ?? this.connectivityStatus,
      locationPermissionStatus: locationPermissionStatus ?? this.locationPermissionStatus,
      isFirstRun: isFirstRun ?? this.isFirstRun,
      activeTripId: activeTripId ?? this.activeTripId,
    );
  }

  @override
  List<Object?> get props => [
        themeMode,
        connectivityStatus,
        locationPermissionStatus,
        isFirstRun,
        activeTripId,
      ];
}
