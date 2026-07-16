import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
    final nameValid = _nameCtrl.text.trim().isNotEmpty;
    final emailValid = _emailCtrl.text.trim().isNotEmpty && _emailCtrl.text.contains('@');
    final passValid = _passwordCtrl.text.length >= 8;
    final phoneValid = _phoneCtrl.text.trim().isNotEmpty;

    if (!nameValid || !emailValid || !passValid || !phoneValid) {
      _formKey.currentState!.validate();
      return;
    }

    if (_ineCtrl.text.trim().isEmpty) {
      await _showKYCDialog();
    } else {
      if (_formKey.currentState!.validate()) {
        _registerAfterKYC();
      }
    }
  }

  Future<void> _showKYCDialog() async {
    final picker = ImagePicker();
    String? inePath;
    String? selfiePath;
    bool kycLoading = false;
    String? kycError;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final cs = Theme.of(context).colorScheme;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.shield_outlined, color: Colors.blue, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Verificación KYC Obligatoria',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: cs.onSurface),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Para garantizar la trazabilidad de los contratos digitales, necesitamos escanear tu INE y validar tu rostro biométricamente.',
                    style: TextStyle(fontSize: 12.5),
                  ),
                  const SizedBox(height: 16),
                  if (kycError != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cs.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        kycError!,
                        style: TextStyle(color: cs.error, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: inePath != null ? Colors.green : cs.outlineVariant),
                    ),
                    leading: Icon(
                      inePath != null ? Icons.check_circle : Icons.badge_outlined,
                      color: inePath != null ? Colors.green : cs.primary,
                    ),
                    title: const Text('Fotografía del INE (Frente)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      inePath != null ? 'Capturada ✓' : 'Presiona para tomar foto',
                      style: TextStyle(fontSize: 11, color: inePath != null ? Colors.green : cs.onSurfaceVariant),
                    ),
                    onTap: kycLoading
                        ? null
                        : () async {
                            try {
                              final file = await picker.pickImage(source: ImageSource.camera);
                              if (file != null) {
                                setDialogState(() => inePath = file.path);
                              }
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'No se pudo acceder a la cámara. Prueba esta pantalla en un dispositivo o emulador Android/iOS real.'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: selfiePath != null ? Colors.green : cs.outlineVariant),
                    ),
                    leading: Icon(
                      selfiePath != null ? Icons.check_circle : Icons.face_outlined,
                      color: selfiePath != null ? Colors.green : cs.primary,
                    ),
                    title: const Text('Selfie Biométrica (Rostro)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      selfiePath != null ? 'Capturada ✓' : 'Presiona para tomar foto',
                      style: TextStyle(fontSize: 11, color: selfiePath != null ? Colors.green : cs.onSurfaceVariant),
                    ),
                    onTap: kycLoading
                        ? null
                        : () async {
                            try {
                              final file = await picker.pickImage(
                                  source: ImageSource.camera, preferredCameraDevice: CameraDevice.front);
                              if (file != null) {
                                setDialogState(() => selfiePath = file.path);
                              }
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'No se pudo acceder a la cámara. Prueba esta pantalla en un dispositivo o emulador Android/iOS real.'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: kycLoading ? null : () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: (inePath == null || selfiePath == null || kycLoading)
                    ? null
                    : () async {
                        setDialogState(() {
                          kycLoading = true;
                          kycError = null;
                        });
                        final provider = context.read<RegisterProvider>();
                        final res = await provider.verifyKyc(inePath: inePath!, selfiePath: selfiePath!);
                        if (res != null) {
                          setDialogState(() {
                            kycLoading = false;
                          });
                          final extractedIne = res['clave_elector_ine'] as String? ?? '';
                          _ineCtrl.text = extractedIne;
                          Navigator.pop(ctx);
                          _registerAfterKYC();
                        } else {
                          setDialogState(() {
                            kycError = provider.errorMessage ?? 'Falló la validación biométrica.';
                            kycLoading = false;
                          });
                        }
                      },
                child: kycLoading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Verificar KYC'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _registerAfterKYC() async {
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

    context.read<ToolProvider>().clearTools();
    context.read<RentalProvider>().clearState();

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
                  readOnly: true,
                  onTap: _handleRegister,
                  decoration: InputDecoration(
                    hintText: 'Presiona para escanear tu INE',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.camera_alt_outlined, color: Colors.blue),
                      onPressed: _handleRegister,
                    ),
                    helperText: 'Este campo se llena automáticamente al escanear tu INE',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Debes completar la verificación KYC';
                    }
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