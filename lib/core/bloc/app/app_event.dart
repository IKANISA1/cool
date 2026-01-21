import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';
import 'app_state.dart';

abstract class AppEvent extends Equatable {
  const AppEvent();

  @override
  List<Object?> get props => [];
}

/// App started event
class AppStarted extends AppEvent {
  const AppStarted();
}

/// Connectivity changed event
class AppConnectivityChanged extends AppEvent {
  final List<ConnectivityResult> results;

  const AppConnectivityChanged(this.results);

  @override
  List<Object?> get props => [results];
}

/// Theme changed event
class AppThemeChanged extends AppEvent {
  final AppThemeMode mode;

  const AppThemeChanged(this.mode);

  @override
  List<Object?> get props => [mode];
}

/// Location permission changed
class AppLocationPermissionChanged extends AppEvent {
  final LocationPermissionStatus status;

  const AppLocationPermissionChanged(this.status);

  @override
  List<Object?> get props => [status];
}
