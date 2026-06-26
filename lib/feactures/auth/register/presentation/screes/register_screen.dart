import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/register_provider.dart';
import '../components/role_selector.dart';

import '../../../../propietario/presentation/screes/dashboard_screen.dart';
import '../../../../solicitante/presentation/screes/catalog_screen.dart';
import '../../../../propietario/presentation/providers/tool_provider.dart';
import '../../../../checkout/presentation/providers/rental_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _ineCtrl      = TextEditingController();
  String _role  = 'requester';
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    _ineCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    await context.read<RegisterProvider>().register(
      name:     _nameCtrl.text.trim(),
      email:    _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      role:     _role,
      phone:    _phoneCtrl.text.trim(),
      ine:      _ineCtrl.text.trim(),
    );

    if (!mounted) return;

    final provider = context.read<RegisterProvider>();
    if (provider.user == null) return;

    // ━━ Limpiar datos de sesión anterior en todos los providers ━━
    // Esto evita que los datos del usuario previo se muestren en la nueva sesión.
    context.read<ToolProvider>().clearTools();
    context.read<RentalProvider>().clearState();

    // Limpiar la clave is_pro que no persiste en RegisterProvider
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('user_is_pro', provider.user!.isPro);

    if (!mounted) return;

    final dest = provider.user!.isOwner
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

    final provider = context.watch<RegisterProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Crear Cuenta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Únete a ToolShare', style: tt.headlineMedium),
                const SizedBox(height: 4),
                Text('Completa tu perfil para empezar',
                    style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: 24),

                if (provider.errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(provider.errorMessage!,
                        style: TextStyle(color: cs.error)),
                  ),
                  const SizedBox(height: 16),
                ],

                const Text('Nombre completo'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'Juan Pérez',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 16),

                const Text('Teléfono'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: '55 1234 5678',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Campo requerido';
                    if (v.replaceAll(RegExp(r'\D'), '').length < 10) {
                      return 'Ingresa un número de 10 dígitos';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                const Text('Correo electrónico'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    hintText: 'correo@ejemplo.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Campo requerido';
                    if (!v.contains('@')) return 'Correo inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                const Text('Contraseña'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'Mínimo 8 caracteres',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Campo requerido';
                    if (v.length < 8) return 'Mínimo 8 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                const Text('Número de INE / Clave de Elector'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _ineCtrl,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    hintText: 'Ej. PRRLSS85010212H700',
                    prefixIcon: Icon(Icons.badge_outlined),
                    helperText: 'Encontrarás este dato en el reverso de tu INE',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Campo requerido';
                    if (v.trim().length < 10) return 'Clave de elector inválida';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                Text('Tipo de cuenta', style: tt.titleMedium),
                const SizedBox(height: 12),
                RoleSelector(
                  selectedRole: _role,
                  onChanged: (r) => setState(() => _role = r),
                ),
                const SizedBox(height: 28),

                FilledButton(
                  onPressed: provider.loading ? null : _handleRegister,
                  child: provider.loading
                      ? SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: cs.onPrimary))
                      : const Text('Crear Cuenta'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Ya tengo cuenta → Iniciar Sesión'),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}