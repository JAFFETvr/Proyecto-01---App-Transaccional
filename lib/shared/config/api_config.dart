import 'dart:io' show Platform;

class ApiConfig {
  /// Al usar un celular físico por USB, podemos redirigir el puerto ejecutando:
  /// adb reverse tcp:8080 tcp:8080
  /// Esto permite usar '127.0.0.1' de forma segura y evitar problemas de firewall o Wi-Fi.
  static const String serverIp = '127.0.0.1';
  static const String port = '8080';

  static String get baseUrl {
    if (Platform.isAndroid) return 'http://$serverIp:$port/api';
    return 'http://localhost:$port/api';
  }
}
