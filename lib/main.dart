import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'shared/theme/app_theme.dart';
import 'feactures/auth/login/presentation/screes/login_screen.dart';
import 'feactures/propietario/presentation/screes/dashboard_screen.dart';
import 'feactures/solicitante/presentation/screes/catalog_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ToolRentApp());
}

class ToolRentApp extends StatelessWidget {
  const ToolRentApp({super.key});

  Future<Widget> _resolveHome() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final role  = prefs.getString('user_role') ?? '';

    if (token == null) return const LoginScreen();
    if (role == 'owner') return const DashboardScreen();
    return const CatalogScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ToolRent',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
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
    );
  }
}