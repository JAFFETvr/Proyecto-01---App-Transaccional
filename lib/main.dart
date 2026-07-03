





import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'my_app.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    DevicePreview(
      enabled: false, 
      builder: (context) => const MyApp(),
    ),
  );
}