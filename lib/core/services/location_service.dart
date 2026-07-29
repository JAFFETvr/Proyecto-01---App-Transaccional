import 'package:geolocator/geolocator.dart';

/// Encapsula el acceso al GPS del dispositivo (permisos + Geolocator) para que
/// la capa de presentación no dependa directamente de esa infraestructura.
class LocationService {
  const LocationService._();

  /// Best effort: no lanza, retorna `null` en cualquier fallo.
  static Future<({double latitude, double longitude})?> tryGetCurrentPosition({
    bool highAccuracy = true,
  }) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy:
                highAccuracy ? LocationAccuracy.high : LocationAccuracy.medium,
          ),
        );
        return (latitude: pos.latitude, longitude: pos.longitude);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Distancia en metros entre dos coordenadas. Envuelve la utilidad de
  /// Geolocator para que las vistas no dependan del paquete directamente.
  static double distanceMeters(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) =>
      Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
}
