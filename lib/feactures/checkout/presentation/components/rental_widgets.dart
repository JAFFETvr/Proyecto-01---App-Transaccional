import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entitie/rental_entity.dart';

/// Aviso de devolución próxima o vencida (reemplaza push, FCM está deshabilitado).
class ReturnDueBanner extends StatelessWidget {
  final RentalEntity rental;
  const ReturnDueBanner({super.key, required this.rental});

  @override
  Widget build(BuildContext context) {
    if (!rental.returnDueSoon && !rental.returnOverdue) {
      return const SizedBox.shrink();
    }
    final overdue = rental.returnOverdue;
    final color = overdue ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);
    final text = overdue
        ? 'La fecha de devolución ya venció. Coordina la entrega cuanto antes.'
        : 'Quedan ${rental.timeLeftLabel} para devolver la herramienta.';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(overdue ? Icons.warning_amber_rounded : Icons.alarm_rounded,
              size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Icono de chat con un punto rojo cuando hay mensajes sin leer de la otra
/// persona.
class ChatIconWithBadge extends StatelessWidget {
  final bool hasUnread;
  final Color color;
  final VoidCallback onPressed;
  final String tooltip;

  const ChatIconWithBadge({
    super.key,
    required this.hasUnread,
    required this.color,
    required this.onPressed,
    this.tooltip = 'Chat',
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.chat_bubble_outline_rounded, color: color),
          tooltip: tooltip,
          onPressed: onPressed,
        ),
        if (hasUnread)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}

/// Resultado del dictamen de disputa, interpretado según el rol (capture/refund).
class DisputeResultCard extends StatelessWidget {
  final RentalEntity rental;
  final bool isOwner;

  const DisputeResultCard({
    super.key,
    required this.rental,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    final action = rental.disputeAdminAction; // 'capture' | 'refund' | null
    if (action == null) return const SizedBox.shrink();

    // capture => el depósito se cobró a favor del propietario.
    // refund  => se reembolsó al solicitante.
    final ownerWon = action == 'capture';
    final youWon = isOwner ? ownerWon : !ownerWon;

    final color =
        youWon ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final title = youWon
        ? 'Ganaste la disputa'
        : 'Perdiste la disputa';
    final subtitle = youWon
        ? (isOwner
            ? 'El administrador falló a tu favor: se te cobró el depósito de garantía por el daño reportado.'
            : 'El administrador falló a tu favor: se te reembolsó el pago retenido.')
        : (isOwner
            ? 'El administrador falló a favor del solicitante: se le reembolsó el pago retenido.'
            : 'El administrador falló a favor del propietario: se cobró el depósito de garantía.');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                youWon ? Icons.emoji_events_rounded : Icons.gavel_rounded,
                color: color,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.5,
              color: color.withValues(alpha: 0.95),
            ),
          ),
          if (rental.disputeAdminNotes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Dictamen del administrador:',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              rental.disputeAdminNotes,
              style: GoogleFonts.inter(fontSize: 13, height: 1.45),
            ),
          ],
        ],
      ),
    );
  }
}
