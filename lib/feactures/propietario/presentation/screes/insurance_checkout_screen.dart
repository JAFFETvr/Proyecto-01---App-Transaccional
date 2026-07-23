import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/theme/theme_extensions.dart';
import '../../../../../shared/widgets/primary_gradient_button.dart';
import '../providers/tool_provider.dart';

/// Abre el flujo de pago del seguro mensual para una herramienta.
///
/// Igual que la renta: el checkout de Mercado Pago se abre en un navegador
/// real (no en un WebView embebido, donde MP deja el botón "Pagar" inerte por
/// anti-fraude). Al volver a la app se reconcilia el pago con el backend
/// (que lo busca en MP por external_reference), sin depender de interceptar el
/// redirect de retorno.
Future<void> openInsuranceCheckout(BuildContext context, String toolId) async {
  final toolProvider = context.read<ToolProvider>();
  final initPoint = await toolProvider.getInsurancePreference(toolId);
  if (!context.mounted) return;

  if (initPoint == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(toolProvider.error ?? 'Error al iniciar el pago del seguro'),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  final activated = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => InsuranceCheckoutScreen(
        initPoint: initPoint,
        toolId: toolId,
      ),
    ),
  );

  if (activated != true || !context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('¡Seguro contratado! Tu herramienta ya está protegida 🛡️'),
      backgroundColor: Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

class InsuranceCheckoutScreen extends StatefulWidget {
  final String initPoint;
  final String toolId;
  const InsuranceCheckoutScreen({
    super.key,
    required this.initPoint,
    required this.toolId,
  });

  @override
  State<InsuranceCheckoutScreen> createState() => _InsuranceCheckoutScreenState();
}

class _InsuranceCheckoutScreenState extends State<InsuranceCheckoutScreen>
    with WidgetsBindingObserver {
  bool _awaiting = false;
  bool _reconciling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _openCheckout());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _awaiting) {
      _reconcile();
    }
  }

  Future<void> _openCheckout() async {
    final uri = Uri.tryParse(widget.initPoint);
    if (uri == null) return;
    var ok = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    if (!ok) {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    if (!mounted) return;
    if (ok) {
      setState(() => _awaiting = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir el pago del seguro.'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _reconcile({bool manual = false}) async {
    if (_reconciling) return;
    setState(() => _reconciling = true);
    final activated =
        await context.read<ToolProvider>().reconcileInsurance(widget.toolId);
    if (!mounted) return;
    setState(() => _reconciling = false);

    if (activated) {
      Navigator.of(context).pop(true);
    } else if (manual) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Todavía no confirmamos el pago del seguro. Si ya pagaste, '
            'espera unos segundos y vuelve a intentar.',
          ),
          backgroundColor: Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: context.textPrimary),
        title: Text(
          'Seguro — Pago Seguro',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: AppColors.orange500.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield_outlined,
                    size: 46, color: AppColors.orange500),
              ),
              const SizedBox(height: 24),
              Text(
                'Pago del seguro',
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Completa el pago del seguro en Mercado Pago.\n'
                'Al terminar, vuelve a la app y presiona "Ya completé el pago".',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.5,
                  color: context.textSecondary,
                ),
              ),
              const SizedBox(height: 28),
              if (_reconciling)
                const CircularProgressIndicator()
              else ...[
                PrimaryGradientButton(
                  label: 'Ya completé el pago — verificar',
                  icon: Icons.refresh_rounded,
                  height: 52,
                  onPressed: () => _reconcile(manual: true),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _openCheckout,
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('Reabrir pago'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
