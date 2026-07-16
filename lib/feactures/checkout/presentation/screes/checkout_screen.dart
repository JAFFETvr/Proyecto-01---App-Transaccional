import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'rental_tracking_requester_screen.dart';
import '../providers/rental_provider.dart';
import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/theme/theme_extensions.dart';
import '../../../../../shared/widgets/primary_gradient_button.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _webViewReady = false;
  late final WebViewController _webViewController;
  bool _processingPayment = false;
  String _selectedPayment = 'card'; // 'card' | 'cash'
  bool _showWebView = false;

  Map<String, dynamic> get _args =>
      ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};

  void _navigateToTracking() {
    final rental = context.read<RentalProvider>().currentRental;
    if (!mounted || rental == null) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const RentalTrackingRequesterScreen(),
        settings: RouteSettings(arguments: rental),
      ),
      (_) => false,
    );
  }

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => setState(() => _webViewReady = true),
        onNavigationRequest: (req) {
          if (req.url.startsWith('toolshare://')) {
            _navigateToTracking();
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ));
  }

  @override
  Widget build(BuildContext context) {
    final tool     = _args['tool'];
    final toolName = tool?.name ?? 'Herramienta';
    final days     = _args['days'] ?? 1;
    final total    = _args['total'] ?? 0.0;
    final deposit  = _args['deposit'] ?? 0.0;
    final priceDay = _args['pricePerDay'] ?? 0.0;

    final rentalProvider = context.watch<RentalProvider>();

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: context.textPrimary),
        title: Text(
          'Pago Seguro',
          style: GoogleFonts.montserrat(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: context.borderColor),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.successBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.lock_rounded, size: 12, color: AppColors.success),
              const SizedBox(width: 4),
              Text(
                'Seguro',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
            ]),
          ),
        ],
      ),

      body: Column(
        children: [
          // ── Resumen ─────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumen del pedido',
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                _SummaryRow(
                    icon: Icons.handyman_outlined,
                    label: toolName,
                    value: ''),
                _SummaryRow(
                    icon: Icons.calendar_today_outlined,
                    label: '$days día${days > 1 ? 's' : ''}',
                    value:
                        '\$${(priceDay * days).toStringAsFixed(0)} MXN'),
                _SummaryRow(
                    icon: Icons.security_outlined,
                    label: _selectedPayment == 'card'
                        ? 'Comisión de servicio (10%)'
                        : 'Depósito (10%)',
                    value:
                        '\$${(deposit as double).toStringAsFixed(0)} MXN'),
                const SizedBox(height: 10),
                Divider(color: context.borderColor),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total:',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: context.textPrimary,
                        )),
                    Text(
                      '\$${(total as double).toStringAsFixed(0)} MXN',
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.orange500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Aviso
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Icon(Icons.info_outline, size: 14, color: context.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _selectedPayment == 'card'
                      ? 'Solo se capturan los fondos al confirmar la entrega física.'
                      : 'Pago directo en efectivo al momento de recibir la herramienta.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: context.textSecondary,
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),

          // Selector de Método de Pago
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedPayment = 'card'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedPayment == 'card' ? AppColors.orange500 : context.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedPayment == 'card' ? AppColors.orange500 : context.borderColor,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.credit_card_rounded, size: 18, color: _selectedPayment == 'card' ? Colors.white : context.textSecondary),
                          const SizedBox(width: 8),
                          Text(
                            'Tarjeta',
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: _selectedPayment == 'card' ? Colors.white : context.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedPayment = 'cash'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedPayment == 'cash' ? AppColors.orange500 : context.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedPayment == 'cash' ? AppColors.orange500 : context.borderColor,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.payments_outlined, size: 18, color: _selectedPayment == 'cash' ? Colors.white : context.textSecondary),
                          const SizedBox(width: 8),
                          Text(
                            'Efectivo',
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: _selectedPayment == 'cash' ? Colors.white : context.textSecondary,
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
          const SizedBox(height: 16),

          // ── WebView de pago o Tarjeta de Advertencia en Efectivo ────────
          if (_selectedPayment == 'card')
            Expanded(
              child: _showWebView
                  ? Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          decoration: BoxDecoration(
                            color: context.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.fromBorderSide(
                                BorderSide(color: context.borderColor)),
                            boxShadow: AppColors.cardShadow,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: WebViewWidget(controller: _webViewController),
                        ),
                        if (!_webViewReady)
                          Container(
                            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            decoration: BoxDecoration(
                              color: context.surface,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.network(
                                  'https://http2.mlstatic.com/frontend-assets/mp-web-navigation/ui-navigation/5.21.22/mercadopago/logo__large@2x.png',
                                  height: 40,
                                  errorBuilder: (_, __, ___) => Icon(
                                      Icons.payment_outlined,
                                      size: 48,
                                      color: context.colors.outline),
                                ),
                                const SizedBox(height: 16),
                                const CircularProgressIndicator(),
                                const SizedBox(height: 12),
                                Text('Cargando pasarela de pago…',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: context.textSecondary,
                                    )),
                              ],
                            ),
                          ),
                      ],
                    )
                  : Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      decoration: BoxDecoration(
                        color: context.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.fromBorderSide(
                            BorderSide(color: context.borderColor)),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.credit_card_rounded,
                              size: 48, color: context.colors.outline),
                          const SizedBox(height: 12),
                          Text(
                            'Presiona "Confirmar" para\niniciar el pago seguro',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: context.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
            )
          else
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.colors.errorContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.gpp_maybe_rounded, size: 48, color: Color(0xFFD97706)),
                        const SizedBox(height: 12),
                        Text(
                          '⚠️ Advertencia Legal y de Seguro',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: context.colors.onErrorContainer,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Al elegir pago en efectivo, la transacción y acuerdo económico se realizan directamente con el propietario.\n\n'
                          'ToolShare no retiene fondos en garantía y NO nos hacemos responsables ni cubrimos seguro alguno en caso de robos, extravíos o daños a la herramienta.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            height: 1.4,
                            color: context.colors.onErrorContainer,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),

      // ── Botón de acción con degradado naranja ────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: _processingPayment || rentalProvider.loading
              ? const SizedBox(
                  height: 55,
                  child: Center(child: CircularProgressIndicator()),
                )
              : PrimaryGradientButton(
                  label: _showWebView
                      ? 'Esperando pago en MercadoPago…'
                      : 'Confirmar — \$${(total is double ? total : (total as num).toDouble()).toStringAsFixed(0)} MXN',
                  icon: Icons.lock_outline,
                  height: 55,
                  onPressed: _showWebView ? null : () async {
                    if (tool == null) return;
                    setState(() => _processingPayment = true);

                    final prefs = await SharedPreferences.getInstance();
                    final payerEmail = prefs.getString('user_email') ?? '';

                    final startDateStr = DateTime.now().toUtc().toIso8601String();
                    final endDateStr = DateTime.now().add(Duration(days: days)).toUtc().toIso8601String();

                    final rentalProv = context.read<RentalProvider>();

                    final success = await rentalProv.createRental(
                      toolId: tool.id as String,
                      startDate: startDateStr,
                      endDate: endDateStr,
                      paymentMethod: _selectedPayment,
                    );

                    if (!mounted) return;

                    if (!success) {
                      setState(() => _processingPayment = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(rentalProv.error ?? 'Error al registrar la renta'),
                          backgroundColor: AppColors.danger,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    // Pago en efectivo: navegar directo al seguimiento
                    if (_selectedPayment == 'cash') {
                      setState(() => _processingPayment = false);
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          icon: const Icon(Icons.check_circle_outline,
                              size: 52, color: AppColors.success),
                          title: Text('¡Renta creada!',
                              style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w800)),
                          content: Text(
                            'Coordina el encuentro con el propietario y realiza el pago en efectivo al recibir la herramienta.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          actions: [
                            FilledButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _navigateToTracking();
                              },
                              child: const Text('Ver seguimiento'),
                            ),
                          ],
                        ),
                      );
                      return;
                    }

                    // Pago con tarjeta: obtener init_point real
                    final rentalId = rentalProv.currentRental!.id;
                    final initPoint = await rentalProv.fetchPreference(rentalId, payerEmail);

                    setState(() => _processingPayment = false);

                    if (!mounted) return;

                    if (initPoint == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(rentalProv.error ?? 'Error al crear la preferencia de pago'),
                          backgroundColor: AppColors.danger,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    _webViewController.loadRequest(Uri.parse(initPoint));
                    setState(() => _showWebView = true);
                  },
                ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Icon(icon, size: 14, color: context.textSecondary),
        const SizedBox(width: 8),
        Expanded(
            child: Text(label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: context.textSecondary,
                ))),
        if (value.isNotEmpty)
          Text(value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              )),
      ]),
    );
  }
}
