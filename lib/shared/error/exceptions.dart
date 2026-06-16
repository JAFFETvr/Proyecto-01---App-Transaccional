
class ServerException implements Exception {
  final String message;

  ServerException({required this.message});
}

/// Excepción para cuando el teléfono no tiene internet o no alcanza al servidor.
class NetworkException implements Exception {}