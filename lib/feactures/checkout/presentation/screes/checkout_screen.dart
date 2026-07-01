import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';

import 'rental_tracking_requester_screen.dart';
import '../providers/rental_provider.dart';
import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/widgets/primary_gradient_button.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _processingPayment = false;
  String _selectedPayment = 'card'; // 'card' | 'cash'

  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvvController = TextEditingController();

  Map<String, dynamic> get _args =>
      ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};

  @override
  void initState() {
    super.initState();
    // Escuchar cambios para re-renderizar la tarjeta en tiempo real
    _cardNumberController.addListener(() => setState(() {}));
    _cardHolderController.addListener(() => setState(() {}));
    _cardExpiryController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    super.dispose();
  }

  String _getCardTokenFromNumber(String number) {
    final clean = number.replaceAll(' ', '');
    if (clean.startsWith('4000')) {
      return 'tok_chargeDeclined';
    }
    if (clean.startsWith('4224')) {
      return 'tok_chargeDeclinedInsufficientFunds';
    }
    return 'tok_visa';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.slate900),
        title: Text(
          'Pago Seguro',
          style: GoogleFonts.montserrat(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.slate900,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE2E8F0)),
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

      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Resumen ─────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
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
                      color: AppColors.slate900,
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
                      label: 'Depósito (10%)',
                      value:
                          '\$${(deposit as double).toStringAsFixed(0)} MXN'),
                  const SizedBox(height: 10),
                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total:',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.slate900,
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
                Icon(Icons.info_outline, size: 14, color: AppColors.slate600),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _selectedPayment == 'card'
                        ? 'Solo se capturan los fondos al confirmar la entrega física.'
                        : 'Pago directo en efectivo al momento de recibir la herramienta.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.slate600,
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
                          color: _selectedPayment == 'card' ? AppColors.orange500 : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedPayment == 'card' ? AppColors.orange500 : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.credit_card_rounded, size: 18, color: _selectedPayment == 'card' ? Colors.white : AppColors.slate700),
                            const SizedBox(width: 8),
                            Text(
                              'Tarjeta',
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: _selectedPayment == 'card' ? Colors.white : AppColors.slate700,
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
                          color: _selectedPayment == 'cash' ? AppColors.orange500 : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedPayment == 'cash' ? AppColors.orange500 : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.payments_outlined, size: 18, color: _selectedPayment == 'cash' ? Colors.white : AppColors.slate700),
                            const SizedBox(width: 8),
                            Text(
                              'Efectivo',
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: _selectedPayment == 'cash' ? Colors.white : AppColors.slate700,
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
              Column(
                children: [
                  // Ilustración de Tarjeta
                  Container(
                    height: 200,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'STRIPE TEST MODE ACTIVE',
                                  style: GoogleFonts.montserrat(
                                    color: AppColors.orange500,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tarjeta de Débito / Crédito',
                                  style: GoogleFonts.inter(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(
                              Icons.nfc_rounded,
                              color: Colors.white54,
                              size: 28,
                            ),
                          ],
                        ),
                        Text(
                          _cardNumberController.text.isEmpty ? '4242  4242  4242  4242' : _cardNumberController.text,
                          style: GoogleFonts.shareTechMono(
                            color: Colors.white,
                            fontSize: 22,
                            letterSpacing: 2,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TITULAR',
                                  style: GoogleFonts.inter(
                                    color: Colors.white38,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _cardHolderController.text.isEmpty ? 'TEST USER' : _cardHolderController.text.toUpperCase(),
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'VENCE',
                                  style: GoogleFonts.inter(
                                    color: Colors.white38,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _cardExpiryController.text.isEmpty ? '12/29' : _cardExpiryController.text,
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            Image.network(
                              'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5e/Visa_Logo.svg/2560px-Visa_Logo.svg.png',
                              height: 18,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.credit_card,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Formulario de Tarjeta Estilo SHEIN
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detalles de la tarjeta',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.slate800,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _cardNumberController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Número de tarjeta',
                            hintText: '4242 4242 4242 4242',
                            prefixIcon: const Icon(Icons.credit_card),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onChanged: (v) {
                            String text = v.replaceAll(' ', '');
                            if (text.length > 16) {
                              text = text.substring(0, 16);
                            }
                            String formatted = '';
                            for (int i = 0; i < text.length; i++) {
                              if (i > 0 && i % 4 == 0) {
                                formatted += ' ';
                              }
                              formatted += text[i];
                            }
                            if (formatted != v) {
                              _cardNumberController.value = TextEditingValue(
                                text: formatted,
                                selection: TextSelection.collapsed(offset: formatted.length),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _cardHolderController,
                          keyboardType: TextInputType.name,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            labelText: 'Nombre del titular',
                            hintText: 'JUAN PEREZ',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: _cardExpiryController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Vence',
                                  hintText: 'MM/YY',
                                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onChanged: (v) {
                                  String text = v.replaceAll('/', '');
                                  if (text.length > 4) {
                                    text = text.substring(0, 4);
                                  }
                                  String formatted = '';
                                  for (int i = 0; i < text.length; i++) {
                                    if (i == 2) {
                                      formatted += '/';
                                    }
                                    formatted += text[i];
                                  }
                                  if (formatted != v) {
                                    _cardExpiryController.value = TextEditingValue(
                                      text: formatted,
                                      selection: TextSelection.collapsed(offset: formatted.length),
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: TextField(
                                controller: _cardCvvController,
                                keyboardType: TextInputType.number,
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: 'CVV',
                                  hintText: '***',
                                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'ℹ️ Para probar éxito usa tarjeta 4242. Para simular declinado usa tarjeta 4000.',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            color: AppColors.slate500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              )
            else
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Center(
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
                          color: const Color(0xFF92400E),
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
                          color: const Color(0xFF78350F),
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
                  label:
                      'Confirmar — \$${(total is double ? total : (total as num).toDouble()).toStringAsFixed(0)} MXN',
                  icon: Icons.lock_outline,
                  height: 55,
                  onPressed: () async {
                    if (tool == null) return;
                    setState(() => _processingPayment = true);

                    // Formato ISO8601 UTC
                    final startDateStr = DateTime.now().toUtc().toIso8601String();
                    final endDateStr = DateTime.now().add(Duration(days: days)).toUtc().toIso8601String();

                    final success = await context.read<RentalProvider>().createRental(
                          toolId: tool.id as String,
                          startDate: startDateStr,
                          endDate: endDateStr,
                          paymentMethod: _selectedPayment,
                          cardToken: _selectedPayment == 'card' ? _getCardTokenFromNumber(_cardNumberController.text) : null,
                          payerEmail: 'solicitante@ejemplo.com',
                        );

                    setState(() => _processingPayment = false);

                    if (!mounted) return;

                    if (success) {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          icon: const Icon(Icons.check_circle_outline,
                              size: 52, color: AppColors.success),
                          title: Text('¡Pago procesado!',
                              style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w800)),
                          content: Text(
                            'Los fondos han sido retenidos de forma segura. '
                            'Ahora coordina el encuentro con el propietario.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.slate600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          actions: [
                            FilledButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const RentalTrackingRequesterScreen(),
                                    settings: RouteSettings(
                                      arguments: rentalProvider.currentRental,
                                    ),
                                  ),
                                  (_) => false,
                                );
                              },
                              child: const Text('Ver seguimiento'),
                            ),
                          ],
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(rentalProvider.error ?? 'Error al procesar el pago y registrar la renta'),
                          backgroundColor: AppColors.danger,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
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
        Icon(icon, size: 14, color: AppColors.slate600),
        const SizedBox(width: 8),
        Expanded(
            child: Text(label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.slate600,
                ))),
        if (value.isNotEmpty)
          Text(value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.slate900,
              )),
      ]),
    );
  }
}
