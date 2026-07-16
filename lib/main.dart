





import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'my_app.dart';

bool get _isMobilePlatform =>
    !kIsWeb && (Platform.isAndroid || Platform.isIOS);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    DevicePreview(
      enabled: !_isMobilePlatform,
      builder: (context) => const MyApp(),
    ),
  );
}