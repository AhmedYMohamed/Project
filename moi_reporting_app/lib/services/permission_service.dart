import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static const String _keyPermissionsRequested = 'permissions_requested';

  /// Request all core permissions on first app launch
  static Future<void> requestAllPermissionsIfFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final bool alreadyRequested = prefs.getBool(_keyPermissionsRequested) ?? false;

    if (alreadyRequested) return;

    // Request permissions batch
    await [
      Permission.location,
      Permission.microphone,
      Permission.camera,
      Permission.notification,
      Permission.photos,
    ].request();

    await prefs.setBool(_keyPermissionsRequested, true);
  }
}
