import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logging/logging.dart';

/// Service for monitoring network connectivity
class ConnectivityService {
  static final _log = Logger('ConnectivityService');

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  List<ConnectivityResult> _currentStatus = [];

  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  /// Initialize and start monitoring connectivity
  Future<void> initialize() async {
    _currentStatus = await _connectivity.checkConnectivity();
    _log.info('Initial connectivity: $_currentStatus');

    _subscription = _connectivity.onConnectivityChanged.listen(
      (results) {
        _currentStatus = results;
        _log.fine('Connectivity changed: $results');
      },
      onError: (error) {
        _log.warning('Connectivity stream error: $error');
      },
    );
  }

  /// Check if currently connected to the internet
  bool get isConnected {
    return _currentStatus.isNotEmpty &&
        !_currentStatus.contains(ConnectivityResult.none);
  }

  /// Check if connected via WiFi
  bool get isOnWifi => _currentStatus.contains(ConnectivityResult.wifi);

  /// Check if connected via mobile data
  bool get isOnMobile => _currentStatus.contains(ConnectivityResult.mobile);

  /// Get current connectivity status
  List<ConnectivityResult> get currentStatus => _currentStatus;

  /// Stream of connectivity changes
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;

  /// Check connectivity (async)
  Future<bool> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _currentStatus = results;
    return isConnected;
  }

  /// Stream that emits true when connected, false when disconnected
  Stream<bool> get connectionStream => _connectivity.onConnectivityChanged.map(
        (results) =>
            results.isNotEmpty && !results.contains(ConnectivityResult.none),
      );

  /// Dispose of resources
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
