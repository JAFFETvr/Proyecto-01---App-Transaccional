import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Mercado Pago (y algunos métodos de pago) intentan abrir apps nativas
/// (mercadopago://, bancomer://, oxxo://, etc.) desde dentro del checkout
/// web. Un WebView genérico no sabe renderizar esos esquemas y truena con
/// "ERR_UNKNOWN_URL_SCHEME" (visible en producción/Play Store) — hay que
/// interceptarlos e intentar abrirlos con el sistema operativo en vez de
/// dejar que el WebView los navegue directamente.
NavigationDecision handleNonHttpScheme(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.scheme == 'http' || uri.scheme == 'https') {
    return NavigationDecision.navigate;
  }
  launchUrl(uri, mode: LaunchMode.externalApplication)
      .catchError((_) => false);
  return NavigationDecision.prevent;
}
