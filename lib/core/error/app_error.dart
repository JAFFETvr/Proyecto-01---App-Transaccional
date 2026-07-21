class AppError implements Exception {
  final int statusCode;
  final String message;

  const AppError({required this.statusCode, required this.message});

  String get userMessage {
    switch (statusCode) {
      case 400: return message.isNotEmpty ? message : 'Datos inválidos. Revisa los campos.';
      case 401: return 'Credenciales incorrectas.';
      case 403: return 'No tienes permiso para esta acción.';
      case 404: return 'No encontrado.';
      case 409: return message.isNotEmpty ? message : 'Conflicto: operación no permitida.';
      case 0:   return message;
      default:  return message.isNotEmpty ? message : 'Error del servidor ($statusCode).';
    }
  }

  @override
  String toString() => 'AppError($statusCode): $message';
}