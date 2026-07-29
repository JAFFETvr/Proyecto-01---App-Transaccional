import 'package:firebase_messaging/firebase_messaging.dart';

import 'session_service.dart';

/// Clave del dato personalizado que marca una notificación de FCM como
/// una orden de borrado remoto (en vez de una notificación general).
const String kWipeAction = 'wipe_sensitive_data';

/// Debe ser top-level y llevar @pragma para no ser eliminada en release.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (message.data['action'] == kWipeAction) {
    await SessionService.wipeAndLogout();
  }
}

/// Encapsula FCM: permisos, tópico por usuario y listeners de borrado remoto.
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

  /// Tópico exclusivo del usuario: así el borrado remoto apunta solo a él.
  static Future<void> subscribeToUserTopic(String userId) {
    return FirebaseMessaging.instance.subscribeToTopic(topicFor(userId));
  }

  static Future<void> unsubscribeFromUserTopic(String userId) {
    return FirebaseMessaging.instance.unsubscribeFromTopic(topicFor(userId));
  }

  static String topicFor(String userId) => 'user_wipe_$userId';
}
