import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'rental_tracking_requester_screen.dart';
import '../providers/rental_provider.dart';
import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/theme/theme_extensions.dart';
import '../../../../../shared/widgets/primary_gradient_button.dart';
import '../../../../../shared/utils/webview_scheme_guard.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _webViewReady = false;
  late final WebViewController _webViewController;
  bool _processingPayment = false;
  bool _showWebView = false;
  String _paymentMethod = 'card';

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

  // Respaldo del webhook de Mercado Pago: en vez de solo confiar en que
  // "llegamos a la URL de éxito" significa que se pagó, se le pide al
  // backend que vuelva a verificar ese payment_id directo con MP antes de
  // marcar la renta como pagada. Si el webhook ya lo hizo, esto no rompe
  // nada (el backend es idempotente); si el webhook se tarda o falla, esto
  // evita que la herramienta se quede "Disponible" con el pago ya cobrado.
  Future<void> _confirmPaymentAndNavigate(String returnUrl) async {
    final rentalProv = context.read<RentalProvider>();
    final rental = rentalProv.currentRental;
    if (rental != null) {
      final uri = Uri.tryParse(returnUrl);
      final paymentId = uri?.queryParameters['payment_id'] ??
          uri?.queryParameters['collection_id'];
      if (paymentId != null && paymentId.isNotEmpty) {
        await rentalProv.confirmPayment(rental.id, paymentId);
      }
    }
    _navigateToTracking();
  }

  // El pago se canceló o fue rechazado: NO se debe navegar a tracking como
  // si la renta hubiera arrancado. Se cierra el WebView y se deja al
  // solicitante reintentar desde la misma pantalla de checkout.
  void _onPaymentFailed() {
    if (!mounted) return;
    setState(() {
      _showWebView = false;
      _webViewReady = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('El pago no se completó. Puedes intentarlo de nuevo.'),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onPaymentPending() {
    if (!mounted) return;
    setState(() {
      _showWebView = false;
      _webViewReady = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Tu pago quedó pendiente de aprobación. Te avisaremos cuando se confirme.',
        ),
        backgroundColor: Color(0xFFF59E0B),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // Mercado Pago detecta por el user-agent cuando su Checkout Pro se
      // abre dentro de un WebView embebido genérico (en vez de un navegador
      // real) y, por seguridad anti-fraude, deshabilita el formulario de
      // pago (el botón "Pagar" queda inerte/gris). Usar un user-agent de
      // Safari móvil real hace que MP lo trate como un navegador normal y
      // habilite el checkout completo.
      ..setUserAgent(
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) '
        'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => setState(() => _webViewReady = true),
          onNavigationRequest: (req) {
            // OJO: los tres back_urls que manda el backend (success/failure/
            // pending) comparten el mismo prefijo ".../payment". Antes se
            // trataban todos como éxito y se navegaba a tracking aunque el
            // pago hubiera sido cancelado o rechazado — hay que distinguir
            // el resultado exacto, no solo el prefijo.
            if (req.url.startsWith('toolshare://success') ||
                req.url.startsWith(
                  'https://toolshare-api.up.railway.app/payment/success',
                )) {
              _confirmPaymentAndNavigate(req.url);
              return NavigationDecision.prevent;
            }
            if (req.url.startsWith('toolshare://failure') ||
                req.url.startsWith(
                  'https://toolshare-api.up.railway.app/payment/failure',
                )) {
              _onPaymentFailed();
              return NavigationDecision.prevent;
            }
            if (req.url.startsWith('toolshare://pending') ||
                req.url.startsWith(
                  'https://toolshare-api.up.railway.app/payment/pending',
                )) {
              _onPaymentPending();
              return NavigationDecision.prevent;
            }
            return handleNonHttpScheme(req.url);
          },
        ),
      );
    if (Platform.isIOS) {
      (_webViewController.platform as WebKitWebViewController)
          .setInspectable(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tool = _args['tool'];
    final toolName = tool?.name ?? 'Herramienta';
    final days = _args['days'] ?? 1;
    final total = _args['total'] ?? 0.0;
    final deposit = _args['deposit'] ?? 0.0;
    final commission = _args['commission'] ?? 0.0;
    final priceDay = _args['pricePerDay'] ?? 0.0;

    // En efectivo el dinero se intercambia directo entre solicitante y
    // propietario: ToolShare no cobra comisión de servicio ni retiene depósito
    // (no pasa nada por la pasarela). El precio queda fijo en la tarifa de la
    // renta. Solo en tarjeta se suman comisión + depósito al total.
    final bool isCash = _paymentMethod == 'cash';
    final double rentOnly =
        (priceDay as num).toDouble() * (days as num).toInt();
    final double displayCommission = isCash ? 0.0 : (commission as num).toDouble();
    final double displayDeposit = isCash ? 0.0 : (deposit as num).toDouble();
    final double displayTotal =
        isCash ? rentOnly : (total as num).toDouble();

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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_rounded,
                  size: 12,
                  color: AppColors.success,
                ),
                const SizedBox(width: 4),
                Text(
                  'Seguro',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
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
                    value: '',
                  ),
                  _SummaryRow(
                    icon: Icons.calendar_today_outlined,
                    label: '$days día${days > 1 ? 's' : ''}',
                    value: '\$${rentOnly.toStringAsFixed(0)} MXN',
                  ),
                  if (isCash)
                    _SummaryRow(
                      icon: Icons.storefront_outlined,
                      label: 'Comisión de servicio',
                      value: 'No aplica (efectivo)',
                    )
                  else ...[
                    _SummaryRow(
                      icon: Icons.storefront_outlined,
                      label: 'Comisión de servicio',
                      value: '\$${displayCommission.toStringAsFixed(0)} MXN',
                    ),
                    _SummaryRow(
                      icon: Icons.security_outlined,
                      label: displayDeposit > 0
                          ? 'Depósito de garantía (10% del valor de la herramienta)'
                          : 'Depósito de garantía',
                      value: displayDeposit > 0
                          ? '\$${displayDeposit.toStringAsFixed(0)} MXN'
                          : 'No requerido',
                    ),
                  ],
                  const SizedBox(height: 10),
                  Divider(color: context.borderColor),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isCash ? 'Total a pagar en efectivo:' : 'Total:',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: context.textPrimary,
                        ),
                      ),
                      Text(
                        '\$${displayTotal.toStringAsFixed(0)} MXN',
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

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: context.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isCash
                          ? 'En efectivo pagas directamente al propietario. ToolShare no cobra comisión ni retiene depósito.'
                          : 'Solo se capturan los fondos al confirmar la entrega física.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: context.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Método de pago',
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _PaymentMethodOption(
                          icon: Icons.credit_card_rounded,
                          label: 'Tarjeta',
                          selected: _paymentMethod == 'card',
                          onTap: _showWebView
                              ? null
                              : () => setState(() => _paymentMethod = 'card'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _PaymentMethodOption(
                          icon: Icons.payments_outlined,
                          label: 'Efectivo',
                          selected: _paymentMethod == 'cash',
                          onTap: _showWebView
                              ? null
                              : () => setState(() => _paymentMethod = 'cash'),
                        ),
                      ),
                    ],
                  ),
                  if (_paymentMethod == 'cash') ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFF59E0B),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Al pagar en efectivo, el intercambio de dinero es directamente entre solicitante y propietario. ToolShare no interviene en esta transacción y no se hace responsable en caso de fraude o estafa.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFFB45309),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: _showWebView
                  ? MediaQuery.of(context).size.height * 0.65
                  : 320,
              child: _showWebView
                  ? Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          decoration: BoxDecoration(
                            color: context.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.fromBorderSide(
                              BorderSide(color: context.borderColor),
                            ),
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
                                    color: context.colors.outline,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const CircularProgressIndicator(),
                                const SizedBox(height: 12),
                                Text(
                                  'Cargando pasarela de pago…',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: context.textSecondary,
                                  ),
                                ),
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
                          BorderSide(color: context.borderColor),
                        ),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _paymentMethod == 'cash'
                                ? Icons.payments_outlined
                                : Icons.credit_card_rounded,
                            size: 48,
                            color: context.colors.outline,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _paymentMethod == 'cash'
                                ? 'Presiona "Confirmar" para\nreservar y pagar en efectivo'
                                : 'Presiona "Confirmar" para\niniciar el pago seguro',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: context.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),

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
                      : 'Confirmar — \$${displayTotal.toStringAsFixed(0)} MXN',
                  icon: Icons.lock_outline,
                  height: 55,
                  onPressed: _showWebView
                      ? null
                      : () async {
                          if (tool == null) return;
                          setState(() => _processingPayment = true);

                          final prefs = await SharedPreferences.getInstance();
                          final payerEmail =
                              prefs.getString('user_email') ?? '';

                          final startDateStr = DateTime.now()
                              .toUtc()
                              .toIso8601String();
                          final endDateStr = DateTime.now()
                              .add(Duration(days: days.toInt()))
                              .toUtc()
                              .toIso8601String();

                          final rentalProv = context.read<RentalProvider>();

                          final success = await rentalProv.createRental(
                            toolId: tool.id as String,
                            startDate: startDateStr,
                            endDate: endDateStr,
                            paymentMethod: _paymentMethod,
                          );

                          if (!mounted) return;

                          if (!success) {
                            setState(() => _processingPayment = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  rentalProv.error ??
                                      'Error al registrar la renta',
                                ),
                                backgroundColor: AppColors.danger,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }

                          if (_paymentMethod == 'cash') {
                            setState(() => _processingPayment = false);
                            _navigateToTracking();
                            return;
                          }

                          final rentalId = rentalProv.currentRental!.id;
                          final initPoint = await rentalProv.fetchPreference(
                            rentalId,
                            payerEmail,
                          );

                          setState(() => _processingPayment = false);

                          if (!mounted) return;

                          if (initPoint == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  rentalProv.error ??
                                      'Error al crear la preferencia de pago',
                                ),
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

class _PaymentMethodOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _PaymentMethodOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.orange500.withValues(alpha: 0.1)
              : context.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.orange500 : context.borderColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 22,
              color: selected ? AppColors.orange500 : context.textSecondary,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.orange500 : context.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 14, color: context.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: context.textSecondary,
              ),
            ),
          ),
          if (value.isNotEmpty)
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
        ],
      ),
    );
  }
}
