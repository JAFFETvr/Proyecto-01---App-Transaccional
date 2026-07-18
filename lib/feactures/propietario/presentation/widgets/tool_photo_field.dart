import 'dart:io';
import 'package:flutter/material.dart';

import 'section_title.dart';

/// Selector de la foto principal de la herramienta (usada además para la
/// clasificación de condición por IA).
class ToolPhotoField extends StatelessWidget {
  final File? pickedImage;
  final String? existingPhotoUrl;
  final bool loading;
  final VoidCallback onTap;

  const ToolPhotoField({
    super.key,
    required this.pickedImage,
    this.existingPhotoUrl,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final hasExisting = pickedImage == null &&
        existingPhotoUrl != null &&
        existingPhotoUrl!.isNotEmpty;
    final hasAnyImage = pickedImage != null || hasExisting;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Foto de la herramienta'),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: loading ? null : onTap,
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasAnyImage ? cs.primary : cs.outlineVariant,
                width: hasAnyImage ? 2 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : hasAnyImage
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          pickedImage != null
                              ? Image.file(pickedImage!, fit: BoxFit.cover)
                              : Image.network(
                                  existingPhotoUrl!,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (ctx, child, progress) =>
                                      progress == null
                                          ? child
                                          : const Center(child: CircularProgressIndicator()),
                                  errorBuilder: (ctx, error, stack) => Center(
                                    child: Icon(Icons.broken_image_outlined,
                                        size: 40, color: cs.onSurfaceVariant),
                                  ),
                                ),
                          Positioned(
                            bottom: 8, right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: cs.surface.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.camera_alt_outlined,
                                    size: 14, color: cs.primary),
                                const SizedBox(width: 4),
                                Text('Cambiar',
                                    style: tt.labelSmall?.copyWith(color: cs.primary)),
                              ]),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined,
                              size: 40, color: cs.onSurfaceVariant),
                          const SizedBox(height: 8),
                          Text('Toca para tomar una foto',
                              style: tt.bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant)),
                        ],
                      ),
          ),
        ),
      ],
    );
  }
}
