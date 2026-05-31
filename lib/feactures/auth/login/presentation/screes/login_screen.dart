import 'package:flutter/material.dart';
import '../viewModels/login_viewmodel.dart';
import '../components/login_form.dart';
import '../../../../propietario/presentation/screes/dashboard_screen.dart';
import '../../../../solicitante/presentation/screes/catalog_screen.dart';
import '../../../register/presentation/screes/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _vm = LoginViewModel();

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(String email, String password) async {
    await _vm.login(email: email, password: password);

    if (!mounted) return;
    if (_vm.user == null) return; // hubo error, el form lo muestra

    // Navegar sin posibilidad de volver al Login
    final dest = _vm.user!.isOwner
        ? const DashboardScreen()
        : const CatalogScreen();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => dest),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
                horizontal: 28, vertical: 40),
            child: AnimatedBuilder(
              animation: _vm,
              builder: (context, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
                  Center(
                    child: Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(Icons.construction_rounded,
                          color: cs.onPrimaryContainer, size: 38),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text('Bienvenido', style: tt.headlineLarge),
                  const SizedBox(height: 6),
                  Text('Inicia sesión para continuar',
                      style: tt.bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 32),

                  LoginForm(
                    onSubmit: _handleLogin,
                    isLoading: _vm.loading,
                    errorMessage: _vm.errorMessage,
                  ),

                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RegisterScreen())),
                    child: const Text('Crear una cuenta'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}