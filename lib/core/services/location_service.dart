import 'package:geolocator/geolocator.dart';

class LocationService {
  static final LocationService instance = LocationService._internal();
  LocationService._internal();

  Position? lastKnownPosition;

  /// Requests permissions and retrieves current device position.
  Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return lastKnownPosition;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return lastKnownPosition;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return lastKnownPosition;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      lastKnownPosition = position;
      return position;
    } catch (_) {
      return lastKnownPosition;
    }
  }

  /// Calculates distance in meters between user and coordinates.
  double? calculateDistanceInMeters(double targetLat, double targetLng) {
    if (lastKnownPosition == null) return null;
    return Geolocator.distanceBetween(
      lastKnownPosition!.latitude,
      lastKnownPosition!.longitude,
      targetLat,
      targetLng,
    );
  }

  /// Formats distance into a human readable string (e.g., '1.2 km' or '850 m').
  String formatDistance(double? distanceInMeters) {
    if (distanceInMeters == null) return '';
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else {
      final km = distanceInMeters / 1000;
      return '${km.toStringAsFixed(1)} km';
    }
  }
}
