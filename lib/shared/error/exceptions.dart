
class ServerException implements Exception {
  final String message;

  ServerException({required this.message});
}

class NetworkException implements Exception {}