import 'package:permission_handler/permission_handler.dart';
import 'package:logging/logging.dart';

/// Permission service for handling runtime permissions
abstract class PermissionService {
  /// Check if location permission is granted
  Future<bool> hasLocationPermission();

  /// Request location permission
  Future<bool> requestLocationPermission();

  /// Check if camera permission is granted
  Future<bool> hasCameraPermission();

  /// Request camera permission
  Future<bool> requestCameraPermission();

  /// Open app settings
  Future<bool> openSettings();

  /// Check multiple permissions at once
  Future<Map<Permission, PermissionStatus>> checkPermissions(
    List<Permission> permissions,
  );

  /// Request multiple permissions at once
  Future<Map<Permission, PermissionStatus>> requestPermissions(
    List<Permission> permissions,
  );
}

/// Implementation of [PermissionService] using permission_handler
class PermissionServiceImpl implements PermissionService {
  static final _log = Logger('PermissionService');

  @override
  Future<bool> hasLocationPermission() async {
    final status = await Permission.locationWhenInUse.status;
    return status.isGranted;
  }

  @override
  Future<bool> requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    _log.fine('Location permission status: $status');

    if (status.isPermanentlyDenied) {
      _log.warning('Location permission permanently denied');
      return false;
    }

    return status.isGranted;
  }

  @override
  Future<bool> hasCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  @override
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    _log.fine('Camera permission status: $status');

    if (status.isPermanentlyDenied) {
      _log.warning('Camera permission permanently denied');
      return false;
    }

    return status.isGranted;
  }

  @override
  Future<bool> openSettings() {
    return openAppSettings();
  }

  @override
  Future<Map<Permission, PermissionStatus>> checkPermissions(
    List<Permission> permissions,
  ) async {
    final Map<Permission, PermissionStatus> statuses = {};
    
    for (final permission in permissions) {
      statuses[permission] = await permission.status;
    }
    
    return statuses;
  }

  @override
  Future<Map<Permission, PermissionStatus>> requestPermissions(
    List<Permission> permissions,
  ) async {
    return await permissions.request();
  }
}
