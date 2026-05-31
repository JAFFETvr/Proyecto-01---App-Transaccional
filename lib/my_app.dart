import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'shared/theme/util.dart';
import 'shared/theme/theme.dart';

// Importa tus pantallas
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/propietario/presentation/screens/propietario_screen.dart';
import 'features/solicitante/presentation/screens/solicitante_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    TextTheme textTheme = createTextTheme(context, "Macondo Swash Caps", "Roboto");
    MaterialTheme theme = MaterialTheme(textTheme);

    return MaterialApp(
      title: 'ToolShare API',
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      theme: theme.light(),
      darkTheme: theme.dark(),
      themeMode: ThemeMode.system,
      initialRoute: '/login', // Punto de entrada
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/propietario': (context) => const PropietarioScreen(),
        '/solicitante': (context) => const SolicitanteScreen(),
      },
    );
  }
}