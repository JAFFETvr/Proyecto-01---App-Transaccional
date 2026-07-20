import 'dart:io' show Platform;

class EnvConfig {
  static const bool useProduction = true;

  static const String serverIp = '127.0.0.1';
  static const String port = '8080';

  static String get baseUrl {
    if (useProduction) {
      return 'https://toolshare-api.up.railway.app/api';
    }
    if (Platform.isAndroid) return 'http://$serverIp:$port/api';
    return 'http://localhost:$port/api';
  }
}
