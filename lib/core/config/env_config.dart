import 'dart:io' show Platform;

class EnvConfig {
  static const bool useProduction = false;

  // IP de la Mac en la red WiFi local (necesaria para dispositivos físicos
  // como el iPhone; 'localhost' solo funciona en el Simulador de iOS).
  static const String serverIp = '192.168.1.60';
  static const String port = '8080';

  static String get baseUrl {
    if (useProduction) {
      return 'https://toolshare-api.up.railway.app/api';
    }
    return 'http://$serverIp:$port/api';
  }
}
