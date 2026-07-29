import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Redimensiona/recomprime una foto antes de enviarla al modelo de la CNN,
/// sin bloquear el hilo de UI: decode/resize/encode corre en un Isolate.
class ImageCompressionService {
  const ImageCompressionService._();

  static Future<File> compress(
    File source, {
    int maxWidth = 1080,
    int quality = 80,
  }) async {
    final bytes = await source.readAsBytes();
    final compressed = await Isolate.run(
      () => _compressBytes(bytes, maxWidth, quality),
    );

    final dir = await getTemporaryDirectory();
    final out = File(
      '${dir.path}/${DateTime.now().microsecondsSinceEpoch}_compressed.jpg',
    );
    return out.writeAsBytes(compressed);
  }

  // Corre en el Isolate hijo: nada de estado compartido con el hilo principal.
  static Uint8List _compressBytes(Uint8List bytes, int maxWidth, int quality) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;

    final resized = decoded.width > maxWidth
        ? img.copyResize(decoded, width: maxWidth)
        : decoded;

    return Uint8List.fromList(img.encodeJpg(resized, quality: quality));
  }
}
