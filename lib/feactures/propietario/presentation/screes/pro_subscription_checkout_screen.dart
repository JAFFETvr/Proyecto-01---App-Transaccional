import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/theme/theme_extensions.dart';
import '../providers/tool_provider.dart';

Future<void> openProSubscriptionCheckout(BuildContext context) async {
  final toolProvider = context.read<ToolProvider>();
  final initPoint = await toolProvider.getSubscriptionPreference();
  if (!context.mounted) return;

  if (initPoint == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(toolProvider.error ?? 'Error al iniciar el pago'),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  final paymentId = await Navigator.of(context).push<String>(
    MaterialPageRoute(
      builder: (_) => ProSubscriptionCheckoutScreen(initPoint: initPoint),
    ),
  );

  if (paymentId == null || !context.mounted) return;

  final activated = await toolProvider.confirmSubscriptionPayment(paymentId);
  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(activated
          ? '¡Plan Pro activado! Ya puedes publicar sin límites 🎉'
          : toolProvider.error ?? 'El pago no se pudo confirmar todavía.'),
      backgroundColor: activated ? const Color(0xFF10B981) : AppColors.danger,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

class ProSubscriptionCheckoutScreen extends StatefulWidget {
  final String initPoint;
  const ProSubscriptionCheckoutScreen({super.key, required this.initPoint});

  @override
  State<ProSubscriptionCheckoutScreen> createState() =>
      _ProSubscriptionCheckoutScreenState();
}

class _ProSubscriptionCheckoutScreenState
    extends State<ProSubscriptionCheckoutScreen> {
  late final WebViewController _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) '
        'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1',
      )
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => setState(() => _ready = true),
        onNavigationRequest: (req) {
          if (req.url.startsWith('toolshare://') ||
              req.url.startsWith(
                  'https://toolshare-api.up.railway.app/payment')) {
            final paymentId = Uri.parse(req.url).queryParameters['payment_id'];
            Navigator.of(context).pop(paymentId);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(widget.initPoint));
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
          'Plan Pro — Pago Seguro',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (!_ready)
            Container(
              color: context.bg,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
