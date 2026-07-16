import '../../core/config/env_config.dart';

/// Se mantiene por compatibilidad: todos los `*_remote_datasource.dart` de las
/// features ya importan `ApiConfig`. La configuración real vive ahora en
/// `core/config/env_config.dart`.
class ApiConfig {
  static String get baseUrl => EnvConfig.baseUrl;
}
