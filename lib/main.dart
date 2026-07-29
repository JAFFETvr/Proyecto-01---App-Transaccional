





import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
// import 'package:firebase_core/firebase_core.dart';

// import 'firebase_options.dart';
// import 'core/services/fcm_service.dart';
import 'my_app.dart';

bool get _isMobilePlatform =>
    !kIsWeb && (Platform.isAndroid || Platform.isIOS);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: reactivar cuando Firebase tenga credenciales (firebase_options.dart / google-services.json)

  runApp(
    DevicePreview(
      enabled: !_isMobilePlatform,
      builder: (context) => const MyApp(),
    ),
  );
}