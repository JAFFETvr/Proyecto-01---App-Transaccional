import 'package:flutter/material.dart';

/// Navigator key global: permite navegar y cerrar sesión desde servicios
/// que no tienen un BuildContext propio (ej. el watchdog de inactividad).
class AppNavigator {
  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();
}
