import 'package:flutter/material.dart';
import '../viewModels/register_viewmodel.dart';
import '../components/role_selector.dart';
import '../../../../propietario/presentation/screes/dashboard_screen.dart';
import '../../../../solicitante/presentation/screes/catalog_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _vm           = RegisterViewModel();
  final _formKey      = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _role  = 'requester';
  bool _obscure = true;

  @override
  void dispose() {
    _vm.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    await _vm.register(
      name:     _nameCtrl.text.trim(),
      email:    _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      role:     _role,
    );

    if (!mounted) return;
    if (_vm.user == null) return;

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
      appBar: AppBar(title: const Text('Crear Cuenta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: 24, vertical: 16),
          child: AnimatedBuilder(
            animation: _vm,
            builder: (context, _) => Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Únete a ToolRent', style: tt.headlineMedium),
                  const SizedBox(height: 4),
                  Text('Completa tu perfil para empezar',
                      style: tt.bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 24),

                  // Error banner
                  if (_vm.errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(_vm.errorMessage!,
                          style: TextStyle(color: cs.error)),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Nombre
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

                  // Email
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
                      if (v == null || v.trim().isEmpty)
                        return 'Campo requerido';
                      if (!v.contains('@')) return 'Correo inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Contraseña
                  const Text('Contraseña'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: 'Mínimo 8 caracteres',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () =>
                            setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Campo requerido';
                      if (v.length < 8) return 'Mínimo 8 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Selector de rol
                  Text('Tipo de cuenta', style: tt.titleMedium),
                  const SizedBox(height: 12),
                  RoleSelector(
                    selectedRole: _role,
                    onChanged: (r) => setState(() => _role = r),
                  ),
                  const SizedBox(height: 28),

                  FilledButton(
                    onPressed: _vm.loading ? null : _handleRegister,
                    child: _vm.loading
                        ? SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: cs.onPrimary))
                        : const Text('Crear Cuenta'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child:
                        const Text('Ya tengo cuenta → Iniciar Sesión'),
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