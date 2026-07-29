import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:provider/provider.dart';
import 'core/services/session_prefs_store.dart';

import 'shared/theme/util.dart';
import 'shared/theme/theme.dart';

import 'core/di/injection_container.dart';
import 'core/services/fake_gps_service.dart';
import 'core/services/secure_session_store.dart';
import 'core/navigation/app_navigator.dart';

import './feactures/auth/login/presentation/screes/login_screen.dart';
import './feactures/auth/register/presentation/screes/register_screen.dart';
import './feactures/propietario/presentation/screes/dashboard_screen.dart';
import './feactures/solicitante/presentation/screes/catalog_screen.dart';
import './feactures/checkout/presentation/screes/checkout_screen.dart';
import './feactures/checkout/presentation/screes/rental_tracking_requester_screen.dart';
import './feactures/checkout/presentation/screes/rental_tracking_owner_screen.dart';
import './feactures/admin/presentation/screes/admin_dashboard_screen.dart';
import './shared/widgets/fake_gps_blocked_screen.dart';
import './shared/widgets/inactivity_watcher.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    TextTheme textTheme = createTextTheme(context, "Inter", "Montserrat");
    MaterialTheme theme = MaterialTheme(textTheme);

    return MultiProvider(
      providers: InjectionContainer.providers,

      child: MaterialApp(
        title: 'ToolShare',
        debugShowCheckedModeBanner: false,
        navigatorKey: AppNavigator.key,

        locale: DevicePreview.locale(context),
        builder: (context, child) =>
            InactivityWatcher(child: DevicePreview.appBuilder(context, child)),

        theme: theme.light(),
        darkTheme: theme.dark(),
        themeMode: ThemeMode.system,
        
        home: const _AppGate(),

        routes: {
          '/login':       (context) => const LoginScreen(),
          '/register':    (context) => const RegisterScreen(),
          '/propietario': (context) => const DashboardScreen(),
          '/solicitante': (context) => const CatalogScreen(),
          '/checkout':    (context) => const CheckoutScreen(),
          '/seguimiento-solicitante': (context) =>
              const RentalTrackingRequesterScreen(),
          '/seguimiento-propietario': (context) =>
              const RentalTrackingOwnerScreen(),
        },
      ),
    );
  }
}

/// Bloquea si detecta Fake GPS; si no, resuelve la pantalla inicial según la sesión.
class _AppGate extends StatefulWidget {
  const _AppGate();

  @override
  State<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<_AppGate> {
  late Future<Widget> _future;

  @override
  void initState() {
    super.initState();
    _future = _resolve();
  }

  void _retry() {
    setState(() => _future = _resolve());
  }

  Future<Widget> _resolve() async {
    final fakeGpsDetected = await FakeGpsService.isMockLocationActive();
    if (fakeGpsDetected) {
      return FakeGpsBlockedScreen(onRetry: _retry);
    }

    final token = await SessionPrefsStore.token();
    final role = await SessionPrefsStore.userRole();

    if (token == null) return const LoginScreen();

    // Reconcilia inactividad contra la marca persistida (por si el proceso fue cerrado).
    final lastActive = await SecureSessionStore.readLastActive();
    if (lastActive != null &&
        DateTime.now().difference(lastActive) >= InactivityWatcher.timeout) {
      await SessionPrefsStore.clear();
      await SecureSessionStore.clear();
      return const LoginScreen();
    }

    // Reafirma la suscripción al tópico de borrado remoto de este usuario
    // (defensivo: por si el sistema operativo la hubiera perdido).
    final userId = await SessionPrefsStore.userId();
    if (userId.isNotEmpty) {
      // TODO: reactivar cuando Firebase tenga credenciales
      // FcmService.subscribeToUserTopic(userId);
    }

    if (role == 'admin') return const AdminDashboardScreen();
    if (role == 'owner') return const DashboardScreen();
    return const CatalogScreen();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data ?? const LoginScreen();
      },
    );
  }
}