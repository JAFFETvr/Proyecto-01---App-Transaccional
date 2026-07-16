import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/login_provider.dart';
import '../components/login_form.dart';

import '../../../../propietario/presentation/screes/dashboard_screen.dart';
import '../../../../solicitante/presentation/screes/catalog_screen.dart';
import '../../../../admin/presentation/screes/admin_dashboard_screen.dart';
import '../../../register/presentation/screes/register_screen.dart';
import '../../../../../../shared/theme/app_colors.dart';
import '../../../../../../shared/theme/theme_extensions.dart';
import '../../../../propietario/presentation/providers/tool_provider.dart';
import '../../../../checkout/presentation/providers/rental_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  Future<void> _handleLogin(String email, String password) async {
    await context.read<LoginProvider>().login(
      email: email,
      password: password,
    );

    if (!mounted) return;

    final provider = context.read<LoginProvider>();
    if (provider.user == null) return;

    // ━━ Limpiar datos de sesión anterior en todos los providers ━━
    // Garantiza que no se muestren datos en memoria de otro usuario.
    context.read<ToolProvider>().clearTools();
    context.read<RentalProvider>().clearState();

    final dest = provider.user!.isAdmin
        ? const AdminDashboardScreen()
        : provider.user!.isOwner
            ? const DashboardScreen()
            : const CatalogScreen();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => dest),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LoginProvider>();

    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Logo ─────────────────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 76, height: 76,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: AppColors.primaryButtonShadow,
                        ),
                        child: const Icon(Icons.construction_rounded,
                            color: Colors.white, size: 40),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'ToolShare',
                        style: GoogleFonts.montserrat(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: context.textPrimary,
                        ),
                      ),
                      Text(
                        'Economía circular de herramientas',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // ── Títulos ─────────────────────────────────────────────
                Text(
                  'Bienvenido',
                  style: GoogleFonts.montserrat(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Inicia sesión para continuar',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: context.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                // ── Formulario ───────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: LoginForm(
                    onSubmit: _handleLogin,
                    isLoading: provider.loading,
                    errorMessage: provider.errorMessage,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Crear cuenta ─────────────────────────────────────────
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RegisterScreen())),
                    child: RichText(
                      text: TextSpan(
                        text: '¿No tienes cuenta? ',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: context.textSecondary,
                        ),
                        children: [
                          TextSpan(
                            text: 'Crear una',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.orange500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}