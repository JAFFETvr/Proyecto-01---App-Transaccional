import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'my_app.dart';
import 'package:device_preview/device_preview.dart';

void main() {
  runApp(DevicePreview(
      enabled: kDebugMode,
      builder : (_) => const MyApp())
      );

}

//intalar libreria 

//luego utilizar comando flutter pub get para descargar la libreria 