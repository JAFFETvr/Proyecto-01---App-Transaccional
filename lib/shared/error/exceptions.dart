// lib/shared/error/exceptions.dart

/// Excepción que lanzaremos cuando nuestra API (Go) nos devuelva un error
/// como 400, 401, 403, 404 o 500.
class ServerException implements Exception {
  final String message;

  ServerException({required this.message});
}

/// Excepción para cuando el teléfono no tiene internet o no alcanza al servidor.
class NetworkException implements Exception {}