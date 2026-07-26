import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/theme_extensions.dart';
import '../../../../shared/widgets/primary_gradient_button.dart';
import '../providers/bank_account_provider.dart';

/// Datos bancarios del propietario, usados solo para que el administrador
/// transfiera manualmente el pago de una disputa ganada con seguro activo
/// (Mercado Pago no ofrece una API de transferencia directa entre cuentas
/// con la integración actual).
class BankAccountScreen extends StatefulWidget {
  const BankAccountScreen({super.key});

  @override
  State<BankAccountScreen> createState() => _BankAccountScreenState();
}

class _BankAccountScreenState extends State<BankAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clabeCtrl = TextEditingController();
  final _holderCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Se espera la respuesta del GET y se llenan los controllers
    // directamente aquí, en vez de depender de que build() reaccione al
    // cambio del provider — así el formulario siempre se prellena al entrar
    // a la pantalla, sin importar el timing del primer rebuild.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<BankAccountProvider>();
      await provider.fetch();
      if (!mounted) return;
      final account = provider.account;
      if (account != null && account.registered) {
        setState(() {
          _clabeCtrl.text = account.clabe;
          _holderCtrl.text = account.accountHolder;
          _bankCtrl.text = account.bankName;
        });
      }
    });
  }

  @override
  void dispose() {
    _clabeCtrl.dispose();
    _holderCtrl.dispose();
    _bankCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<BankAccountProvider>();
    final ok = await provider.save(
      clabe: _clabeCtrl.text.trim(),
      accountHolder: _holderCtrl.text.trim(),
      bankName: _bankCtrl.text.trim(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Datos bancarios guardados ✓'
              : provider.error ?? 'No se pudieron guardar los datos',
        ),
        backgroundColor: ok ? const Color(0xFF10B981) : AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('¿Eliminar datos bancarios?'),
        content: const Text(
          'Se borrará la CLABE, el titular y el banco registrados. Puedes '
          'volver a registrarlos cuando quieras.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;

    final provider = context.read<BankAccountProvider>();
    final ok = await provider.delete();
    if (!mounted) return;
    if (ok) {
      setState(() {
        _clabeCtrl.clear();
        _holderCtrl.clear();
        _bankCtrl.clear();
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Datos bancarios eliminados ✓'
              : provider.error ?? 'No se pudieron eliminar los datos',
        ),
        backgroundColor: ok ? const Color(0xFF10B981) : AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BankAccountProvider>();

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: context.textPrimary),
        title: Text(
          'Datos bancarios',
          style: GoogleFonts.montserrat(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.orange500.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.orange500.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 18,
                        color: AppColors.orange500,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Solo se usan si ganas una disputa en una herramienta '
                          'con el seguro ToolShare activo: el administrador te '
                          'transfiere manualmente el 30% del valor cubierto a '
                          'esta cuenta.',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: context.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'CLABE interbancaria',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _clabeCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 18,
                  decoration: const InputDecoration(
                    hintText: '18 dígitos',
                    counterText: '',
                  ),
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.length != 18 ||
                        !RegExp(r'^\d{18}$').hasMatch(value)) {
                      return 'La CLABE debe tener exactamente 18 dígitos';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Nombre del titular',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _holderCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Tal como aparece en la cuenta',
                  ),
                  validator: (v) => (v?.trim().isEmpty ?? true)
                      ? 'Escribe el nombre del titular'
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  'Banco',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _bankCtrl,
                  decoration: const InputDecoration(hintText: 'Ej. BBVA'),
                  validator: (v) => (v?.trim().isEmpty ?? true)
                      ? 'Escribe el banco'
                      : null,
                ),
                const SizedBox(height: 28),
                PrimaryGradientButton(
                  label: 'Guardar datos bancarios',
                  icon: Icons.save_outlined,
                  height: 52,
                  onPressed: provider.loading ? null : _save,
                ),
                if (provider.account?.registered == true) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: provider.loading ? null : _confirmDelete,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Eliminar datos bancarios'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
