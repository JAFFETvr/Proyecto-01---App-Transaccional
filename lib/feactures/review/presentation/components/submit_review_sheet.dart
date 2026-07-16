import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/review_provider.dart';
import 'review_stars.dart';

/// Hoja inferior para calificar una renta completada (POST /rentals/{id}/review).
/// El backend detecta automáticamente a quién califica el autor autenticado
/// (propietario → solicitante, solicitante → herramienta); aquí solo se pide
/// el rating y un comentario opcional.
class SubmitReviewSheet extends StatefulWidget {
  final String rentalId;
  final String role; // 'owner' | 'requester' — distingue las 2 reseñas de una misma renta
  final String title;
  final String subtitle;

  const SubmitReviewSheet({
    super.key,
    required this.rentalId,
    required this.role,
    required this.title,
    required this.subtitle,
  });

  static Future<void> show(
    BuildContext context, {
    required String rentalId,
    required String role,
    required String title,
    required String subtitle,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SubmitReviewSheet(rentalId: rentalId, role: role, title: title, subtitle: subtitle),
      ),
    );
  }

  @override
  State<SubmitReviewSheet> createState() => _SubmitReviewSheetState();
}

class _SubmitReviewSheetState extends State<SubmitReviewSheet> {
  int _rating = 0;
  final _commentCtrl = TextEditingController();

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Selecciona una calificación de 1 a 5 estrellas.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final provider = context.read<ReviewProvider>();
    final ok = await provider.submitReview(
      rentalId: widget.rentalId,
      role: widget.role,
      rating: _rating,
      comment: _commentCtrl.text.trim(),
    );

    if (!mounted) return;

    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('¡Gracias por tu reseña!'),
        behavior: SnackBarBehavior.floating,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(provider.error ?? 'No se pudo enviar la reseña.'),
        behavior: SnackBarBehavior.floating,
      ));
      if (provider.hasReviewed(widget.rentalId, role: widget.role)) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReviewProvider>();
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: GoogleFonts.montserrat(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.subtitle,
              style: GoogleFonts.inter(fontSize: 13, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Center(
              child: ReviewStarsInput(
                rating: _rating,
                onChanged: (v) => setState(() => _rating = v),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentCtrl,
              maxLines: 3,
              maxLength: 300,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Comparte tu experiencia (opcional)',
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: provider.submitting ? null : _submit,
                child: provider.submitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Enviar reseña'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
