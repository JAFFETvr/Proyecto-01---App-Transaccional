import 'package:geolocator/geolocator.dart';

class FakeGpsService {
  /// Detecta ubicación simulada (Fake GPS); en iOS siempre retorna `false`.
  static Future<bool> isMockLocationActive() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        return false;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      return position.isMocked;
    } catch (_) {
      return false;
    }
  }
}
