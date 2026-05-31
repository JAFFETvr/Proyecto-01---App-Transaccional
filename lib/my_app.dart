import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'shared/theme/util.dart';
import 'shared/theme/theme.dart';


import './feactures/auth/login/presentation/screes/login_screen.dart';
import './feactures/auth/register/presentation/screes/register_screen.dart';
import './feactures/propietario/presentation/screes/dashboard_screen.dart';
import './feactures/solicitante/presentation/screes/catalog_screen.dart';


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Lógica para resolver la pantalla inicial según la sesión guardada
  Future<Widget> _resolveHome() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final role  = prefs.getString('user_role') ?? '';

    // Si no hay token, va al login
    if (token == null) return const LoginScreen();
    // Si es dueño, va a su panel
    if (role == 'owner') return const DashboardScreen();
    // Si es solicitante, va al catálogo
    return const CatalogScreen();
  }

  @override
  Widget build(BuildContext context) {
    // Configuración de tu tema personalizado
    TextTheme textTheme = createTextTheme(context, "Macondo Swash Caps", "Roboto");
    MaterialTheme theme = MaterialTheme(textTheme);

    return MaterialApp(
      title: 'ToolShare', 
      debugShowCheckedModeBanner: false,
      
      // Configuración de DevicePreview
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      
      // Configuración de temas
      theme: theme.light(),
      darkTheme: theme.dark(),
      themeMode: ThemeMode.system,
      
      // En lugar de usar 'initialRoute', usamos 'home' con el FutureBuilder 
      // para evitar que los usuarios logueados vean la pantalla de login por un segundo.
      home: FutureBuilder<Widget>(
        future: _resolveHome(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return snapshot.data ?? const LoginScreen();
        },
      ),
      
      // Mantenemos el mapa de rutas por si decides navegar usando Navigator.pushNamed()
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/propietario': (context) => const DashboardScreen(),
        '/solicitante': (context) => const CatalogScreen(),
      },
    );
  }
}