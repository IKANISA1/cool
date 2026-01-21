import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../services/connectivity_service.dart';
import 'app_event.dart';
import 'app_state.dart';

@injectable
class AppBloc extends Bloc<AppEvent, AppState> {
  final ConnectivityService _connectivityService;
  StreamSubscription? _connectivitySubscription;

  AppBloc(this._connectivityService) : super(const AppState()) {
    on<AppStarted>(_onAppStarted);
    on<AppConnectivityChanged>(_onConnectivityChanged);
    on<AppThemeChanged>(_onThemeChanged);
    on<AppLocationPermissionChanged>(_onLocationPermissionChanged);
  }

  Future<void> _onAppStarted(
    AppStarted event,
    Emitter<AppState> emit,
  ) async {
    // Initialize connectivity monitoring
    await _connectivityService.initialize();
    
    // Check initial status
    _updateConnectivity(_connectivityService.currentStatus, emit);

    // Subscribe to changes
    _connectivitySubscription = _connectivityService.onConnectivityChanged.listen(
      (results) => add(AppConnectivityChanged(results)),
    );
  }

  void _onConnectivityChanged(
    AppConnectivityChanged event,
    Emitter<AppState> emit,
  ) {
    _updateConnectivity(event.results, emit);
  }

  void _updateConnectivity(
    List<ConnectivityResult> results,
    Emitter<AppState> emit,
  ) {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      emit(state.copyWith(connectivityStatus: ConnectivityStatus.offline));
    } else {
      emit(state.copyWith(connectivityStatus: ConnectivityStatus.active));
    }
  }

  void _onThemeChanged(
    AppThemeChanged event,
    Emitter<AppState> emit,
  ) {
    emit(state.copyWith(themeMode: event.mode));
  }

  void _onLocationPermissionChanged(
    AppLocationPermissionChanged event,
    Emitter<AppState> emit,
  ) {
    emit(state.copyWith(locationPermissionStatus: event.status));
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }
}
