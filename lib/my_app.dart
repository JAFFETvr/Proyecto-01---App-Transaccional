import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'shared/theme/util.dart';
import 'shared/theme/theme.dart';

import './feactures/auth/login/presentation/providers/login_provider.dart';
import './feactures/auth/register/presentation/providers/register_provider.dart';
import './feactures/propietario/presentation/providers/tool_provider.dart';
import './feactures/solicitante/presentation/providers/catalog_provider.dart';
import './feactures/checkout/presentation/providers/rental_provider.dart';
import './feactures/checkout/presentation/providers/chat_provider.dart';

import './feactures/auth/login/data/di/login_di.dart';
import './feactures/auth/register/data/di/register_di.dart';
import './feactures/propietario/data/di/propietario_di.dart';
import './feactures/solicitante/data/di/solicitante_di.dart';
import './feactures/checkout/data/di/checkout_di.dart';

import './feactures/auth/login/presentation/screes/login_screen.dart';
import './feactures/auth/register/presentation/screes/register_screen.dart';
import './feactures/propietario/presentation/screes/dashboard_screen.dart';
import './feactures/solicitante/presentation/screes/catalog_screen.dart';
import './feactures/checkout/presentation/screes/checkout_screen.dart';
import './feactures/checkout/presentation/screes/rental_tracking_requester_screen.dart';
import './feactures/checkout/presentation/screes/rental_tracking_owner_screen.dart';
import './feactures/admin/presentation/providers/admin_provider.dart';
import './feactures/admin/presentation/screes/admin_dashboard_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _resolveHome() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final role  = prefs.getString('user_role') ?? '';

    if (token == null) return const LoginScreen();
    if (role == 'admin') return const AdminDashboardScreen();
    if (role == 'owner') return const DashboardScreen();
    return const CatalogScreen();
  }

  @override
  Widget build(BuildContext context) {
    TextTheme textTheme = createTextTheme(context, "Inter", "Montserrat");
    MaterialTheme theme = MaterialTheme(textTheme);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LoginProvider>(
          create: (_) => LoginProvider(
            loginUseCase: LoginDI.provideLoginUseCase(),
          ),
        ),

        ChangeNotifierProvider<RegisterProvider>(
          create: (_) => RegisterProvider(
            registerUseCase: RegisterDI.provideRegisterUseCase(),
          ),
        ),

        ChangeNotifierProvider<ToolProvider>(
          create: (_) => ToolProvider(
            getTools:   PropietarioDI.provideGetTools(),
            createTool: PropietarioDI.provideCreateTool(),
            updateTool: PropietarioDI.provideUpdateTool(),
            deleteTool: PropietarioDI.provideDeleteTool(),
            getPricingSuggestion: PropietarioDI.provideGetPricingSuggestion(),
            predictCondition: PropietarioDI.providePredictCondition(),
            autoValuate: PropietarioDI.provideAutoValuate(),
            getSubscriptionPreference: PropietarioDI.provideGetSubscriptionPreference(),
            confirmSubscriptionPayment: PropietarioDI.provideConfirmSubscriptionPayment(),
            refreshIsPro: PropietarioDI.provideRefreshIsPro(),
          ),
        ),

        ChangeNotifierProvider<CatalogProvider>(
          create: (_) => CatalogProvider(
            getCatalog: SolicitanteDI.provideGetCatalog(),
          ),
        ),

        ChangeNotifierProvider<RentalProvider>(
          create: (_) => RentalProvider(
            createRental:    CheckoutDI.provideCreateRental(),
            getRentals:      CheckoutDI.provideGetRentals(),
            getRental:       CheckoutDI.provideGetRental(),
            confirmDelivery: CheckoutDI.provideConfirmDelivery(),
            confirmReturn:   CheckoutDI.provideConfirmReturn(),
            disputeRental:   CheckoutDI.provideDisputeRental(),
            cancelRental:    CheckoutDI.provideCancelRental(),
            getPreference:   CheckoutDI.provideGetPreference(),
          ),
        ),

        ChangeNotifierProvider<ChatProvider>(
          create: (_) => ChatProvider(CheckoutDI.repository),
        ),

        ChangeNotifierProvider<AdminProvider>(
          create: (_) => AdminProvider(),
        ),
      ],

      child: MaterialApp(
        title: 'ToolShare', 
        debugShowCheckedModeBanner: false,
        
        locale: DevicePreview.locale(context),
        builder: DevicePreview.appBuilder,
        
        theme: theme.light(),
        darkTheme: theme.dark(),
        themeMode: ThemeMode.system,
        
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