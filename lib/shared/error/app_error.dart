// Errores tipados que viajan desde datasource hasta la UI.
class AppError implements Exception {
  final int statusCode;
  final String message;

  const AppError({required this.statusCode, required this.message});

  // Mensaje legible para mostrar en pantalla
  String get userMessage {
    switch (statusCode) {
      case 400: return 'Datos inválidos. Revisa los campos.';
      case 401: return 'Credenciales incorrectas.';
      case 403: return 'No tienes permiso para esta acción.';
      case 404: return 'No encontrado.';
      case 409: return 'El correo ya está registrado.';
      case 0:   return message; // error de red / sin conexión
      default:  return 'Error del servidor ($statusCode).';
    }
  }

  @override
  String toString() => 'AppError($statusCode): $message';
}