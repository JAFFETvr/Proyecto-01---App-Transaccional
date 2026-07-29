import 'dart:io';
import 'package:flutter/material.dart';

import 'section_title.dart';

/// Selector de fotos; la condición final usa el peor score entre todas.
class ToolPhotoField extends StatelessWidget {
  final List<File> pickedImages;
  final List<String> existingPhotoUrls;
  final bool loading;
  final int minPhotos;
  final int maxPhotos;
  final bool editable;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  const ToolPhotoField({
    super.key,
    required this.pickedImages,
    this.existingPhotoUrls = const [],
    required this.loading,
    required this.onAdd,
    required this.onRemove,
    this.minPhotos = 2,
    this.maxPhotos = 5,
    this.editable = true,
  });

  int get _totalCount => pickedImages.length + existingPhotoUrls.length;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    // No editable = ya publicada, no hace falta exigir mínimo de nuevo.
    final metMinimum = !editable || _totalCount >= minPhotos;
    final canAddMore = editable && pickedImages.length < maxPhotos && !loading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Fotos de la herramienta'),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(
              metMinimum ? Icons.check_circle : Icons.info_outline,
              size: 16,
              color: metMinimum ? const Color(0xFF16A34A) : cs.error,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                !editable
                    ? '$_totalCount fotos verificadas por la IA'
                    : metMinimum
                        ? '$_totalCount fotos — mínimo cumplido'
                        : '$_totalCount de $minPhotos fotos — sube al menos $minPhotos ángulos distintos',
                style: tt.bodySmall?.copyWith(
                  color: metMinimum ? const Color(0xFF16A34A) : cs.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Fotografía la herramienta desde ángulos distintos (frente, atrás, '
          'partes con posible desgaste). Si un ángulo muestra daño real, se '
          'refleja en el precio aunque los demás se vean impecables.',
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final url in existingPhotoUrls)
                _PhotoThumb(
                  image: Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, error, stack) => Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              for (var i = 0; i < pickedImages.length; i++)
                _PhotoThumb(
                  image: Image.file(pickedImages[i], fit: BoxFit.cover),
                  onRemove: (editable && !loading) ? () => onRemove(i) : null,
                ),
              if (canAddMore)
                GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: loading
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo_outlined,
                                color: cs.onSurfaceVariant,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Agregar',
                                style: tt.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  final Widget image;
  final VoidCallback? onRemove;

  const _PhotoThumb({required this.image, this.onRemove});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          image,
          if (onRemove != null)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
