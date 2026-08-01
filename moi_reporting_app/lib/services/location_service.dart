import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<Position> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        final lastKnown = await Geolocator.getLastKnownPosition();
        return lastKnown ?? _fallbackPosition();
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          final lastKnown = await Geolocator.getLastKnownPosition();
          return lastKnown ?? _fallbackPosition();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        final lastKnown = await Geolocator.getLastKnownPosition();
        return lastKnown ?? _fallbackPosition();
      }

      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 5),
          ),
        );
      } catch (_) {
        final lastKnown = await Geolocator.getLastKnownPosition();
        return lastKnown ?? _fallbackPosition();
      }
    } catch (_) {
      return _fallbackPosition();
    }
  }

  static Position _fallbackPosition() {
    return Position(
      longitude: 31.2357,
      latitude: 30.0444,
      timestamp: DateTime.now(),
      accuracy: 100,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
  }
}
