class AppError implements Exception {
  final int statusCode;
  final String message;

  const AppError({required this.statusCode, required this.message});

  String get userMessage {
    switch (statusCode) {
      case 400: return 'Datos inválidos. Revisa los campos.';
      case 401: return 'Credenciales incorrectas.';
      case 403: return 'No tienes permiso para esta acción.';
      case 404: return 'No encontrado.';
      // El mensaje real del servidor siempre es más descriptivo que uno hardcoded.
      // Aplica para: 409 conflicto de email, 409 herramienta con rentas, etc.
      case 409: return message.isNotEmpty ? message : 'Conflicto: operación no permitida.';
      case 0:   return message; // error de red / sin conexión
      default:  return message.isNotEmpty ? message : 'Error del servidor ($statusCode).';
    }
  }

  @override
  String toString() => 'AppError($statusCode): $message';
}