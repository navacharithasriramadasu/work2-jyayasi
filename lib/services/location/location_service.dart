import 'dart:developer' as dev;
import 'package:geolocator/geolocator.dart';

/// Real GPS Location Service providing live tactical coordinates for iTantra nodes.
class LocationService {
  double _latitude = 17.385044; // Default tactical grid base if GPS unavailable
  double _longitude = 78.486671;
  double _altitude = 542.0;
  bool _hasGpsLock = false;

  double get latitude => _latitude;
  double get longitude => _longitude;
  double get altitude => _altitude;
  bool get hasGpsLock => _hasGpsLock;

  String get formattedCoordinates =>
      '${_latitude.toStringAsFixed(5)}° N, ${_longitude.toStringAsFixed(5)}° E';

  /// Updates current position from device GPS hardware
  Future<Position?> updateCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        dev.log('[LocationService] Location services are disabled.');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          dev.log('[LocationService] Location permission denied.');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        dev.log('[LocationService] Location permissions permanently denied.');
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 4),
        ),
      );

      _latitude = position.latitude;
      _longitude = position.longitude;
      _altitude = position.altitude;
      _hasGpsLock = true;
      dev.log('[LocationService] GPS Lock acquired: $_latitude, $_longitude');
      return position;
    } catch (e) {
      dev.log('[LocationService] GPS update error: $e');
      return null;
    }
  }
}
