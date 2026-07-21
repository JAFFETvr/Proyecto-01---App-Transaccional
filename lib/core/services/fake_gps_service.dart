import 'package:geolocator/geolocator.dart';

class FakeGpsService {
  /// Verifica si la ubicación actual del dispositivo proviene de un
  /// proveedor simulado (apps de "Fake GPS" / Mock Location).
  ///
  /// En Android, geolocator expone `Position.isMocked`, respaldado por
  /// `Location.isMock()` de la plataforma. iOS no expone una API pública
  /// equivalente, por lo que ahí siempre se reporta `false`.
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
