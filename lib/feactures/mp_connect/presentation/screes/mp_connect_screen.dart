import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:provider/provider.dart';

import '../providers/mp_connect_provider.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/theme_extensions.dart';
import '../../../../shared/widgets/primary_gradient_button.dart';

/// Pantalla para que el propietario vincule su propia cuenta de Mercado Pago
/// (Marketplace/OAuth). Una vez vinculada, cada renta que cobre se divide
/// automáticamente: la comisión de servicio se queda en la plataforma y el
/// resto se deposita directo en su cuenta de Mercado Pago.
class MpConnectScreen extends StatefulWidget {
  const MpConnectScreen({super.key});

  @override
  State<MpConnectScreen> createState() => _MpConnectScreenState();
}

class _MpConnectScreenState extends State<MpConnectScreen> {
  bool _showWebView = false;
  bool _webViewReady = false;
  late final WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    context.read<MpConnectProvider>().fetchStatus();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => setState(() => _webViewReady = true),
        onNavigationRequest: (req) {
          // El backend responde una página HTML propia al terminar el OAuth
          // (ver MPConnectCallback); al llegar ahí cerramos el WebView y
          // refrescamos el estado.
          if (req.url.contains('/auth/mp-connect/callback')) {
            Future.microtask(() async {
              if (!mounted) return;
              setState(() => _showWebView = false);
              await context.read<MpConnectProvider>().fetchStatus();
            });
          }
          return NavigationDecision.navigate;
        },
      ));
    if (Platform.isIOS) {
      (_webViewController.platform as WebKitWebViewController)
          .setInspectable(true);
    }
  }

  Future<void> _connect() async {
    final provider = context.read<MpConnectProvider>();
    final authUrl = await provider.startConnect();
    if (!mounted || authUrl == null) {
      if (mounted && provider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error!),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    setState(() {
      _webViewReady = false;
      _showWebView = true;
    });
    _webViewController.loadRequest(Uri.parse(authUrl));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MpConnectProvider>();

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: context.textPrimary),
        title: Text(
          'Cuenta de Mercado Pago',
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
      ),
      body: _showWebView
          ? Stack(
              children: [
                WebViewWidget(controller: _webViewController),
                if (!_webViewReady)
                  Container(
                    color: context.bg,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            )
          : provider.loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: context.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  provider.connected
                                      ? Icons.check_circle_rounded
                                      : Icons.warning_amber_rounded,
                                  color: provider.connected
                                      ? AppColors.success
                                      : AppColors.orange500,
                                  size: 28,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    provider.connected
                                        ? 'Cuenta vinculada'
                                        : 'Cuenta no vinculada',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: context.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              provider.connected
                                  ? 'Ya puedes recibir pagos: al completarse una renta, tu parte se deposita automáticamente en tu cuenta de Mercado Pago (puedes retirarla a tu banco cuando quieras).'
                                  : 'Para recibir el pago de tus rentas necesitas vincular tu propia cuenta de Mercado Pago (gratis, toma un par de minutos). ToolShare se queda solo con la comisión de servicio; el resto llega directo a tu cuenta.',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: context.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      PrimaryGradientButton(
                        label: provider.connected
                            ? 'Volver a vincular'
                            : 'Conectar mi cuenta de Mercado Pago',
                        icon: Icons.link_rounded,
                        height: 55,
                        onPressed: _connect,
                      ),
                    ],
                  ),
                ),
    );
  }
}
