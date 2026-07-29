import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Intercepta esquemas no-http (mercadopago://, etc.) para evitar ERR_UNKNOWN_URL_SCHEME.
NavigationDecision handleNonHttpScheme(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.scheme == 'http' || uri.scheme == 'https') {
    return NavigationDecision.navigate;
  }
  launchUrl(uri, mode: LaunchMode.externalApplication)
      .catchError((_) => false);
  return NavigationDecision.prevent;
}
