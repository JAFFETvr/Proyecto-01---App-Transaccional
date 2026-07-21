import 'package:firebase_messaging/firebase_messaging.dart';

import 'session_service.dart';

/// Clave del dato personalizado que marca una notificación de FCM como
/// una orden de borrado remoto (en vez de una notificación general).
const String kWipeAction = 'wipe_sensitive_data';

/// Handler de mensajes en segundo plano / app terminada. FCM exige que sea
/// una función de nivel superior (o estática) anotada con @pragma para que
/// el motor de Dart no la elimine en modo release.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (message.data['action'] == kWipeAction) {
    await SessionService.wipeAndLogout();
  }
}

/// Encapsula FCM: permisos, tópico específico por usuario (para que el
/// borrado remoto apunte a UN usuario, nunca a todos) y los listeners que
/// detectan la orden de borrado en cada estado de la app.
class FcmService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((message) {
      if (message.data['action'] == kWipeAction) {
        SessionService.wipeAndLogout();
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (message.data['action'] == kWipeAction) {
        SessionService.wipeAndLogout();
      }
    });
  }

  /// Suscribe este dispositivo al tópico exclusivo del usuario logueado.
  /// Enviar un mensaje a este tópico específico (desde la consola de
  /// Firebase) es lo que hace que el borrado sea dirigido a ESE usuario.
  static Future<void> subscribeToUserTopic(String userId) {
    return FirebaseMessaging.instance.subscribeToTopic(topicFor(userId));
  }

  static Future<void> unsubscribeFromUserTopic(String userId) {
    return FirebaseMessaging.instance.unsubscribeFromTopic(topicFor(userId));
  }

  static String topicFor(String userId) => 'user_wipe_$userId';
}
