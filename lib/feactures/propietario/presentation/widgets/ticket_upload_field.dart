import 'package:flutter/material.dart';

import 'section_title.dart';

/// Sección de comprobante de compra: es la fuente de precio más confiable,
/// evita que la herramienta quede marcada para revisión manual.
class TicketUploadField extends StatelessWidget {
  final bool ticketValidado;
  final double? detectedPrice;
  final bool loading;
  final bool editable;
  final VoidCallback onPickTicket;

  const TicketUploadField({
    super.key,
    required this.ticketValidado,
    required this.detectedPrice,
    required this.loading,
    required this.onPickTicket,
    this.editable = true,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Comprobante de compra (opcional)'),
        const SizedBox(height: 6),
        Text(
          'Sube una foto de tu ticket o factura: es la fuente de precio más confiable y evita que tu herramienta quede marcada para revisión manual.',
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        ticketValidado
            ? Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified_outlined,
                      color: Color(0xFF16A34A),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Ticket verificado: \$${detectedPrice!.toStringAsFixed(0)} MXN',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ),
                    if (editable)
                      TextButton(
                        onPressed: loading ? null : onPickTicket,
                        child: const Text('Cambiar'),
                      ),
                  ],
                ),
              )
            : OutlinedButton.icon(
                onPressed: (editable && !loading) ? onPickTicket : null,
                icon: loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.receipt_long_outlined),
                label: Text(
                  loading ? 'Leyendo ticket...' : 'Subir ticket de compra',
                ),
              ),
      ],
    );
  }
}
