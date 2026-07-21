import 'package:flutter/material.dart';

import 'section_title.dart';

/// Precio sugerido por el motor de minería de datos + control deslizante
/// para que el propietario ajuste el precio final dentro del rango permitido.
class ToolPricingCard extends StatelessWidget {
  final double suggestedPrice;
  final double minPrice;
  final double finalPrice;
  final double maxRateVal;
  final bool fetchingPricing;
  final String pricingDesc;
  final bool requiresManualReview;
  final bool editable;
  final ValueChanged<double> onFinalPriceChanged;

  const ToolPricingCard({
    super.key,
    required this.suggestedPrice,
    required this.minPrice,
    required this.finalPrice,
    required this.maxRateVal,
    required this.fetchingPricing,
    required this.pricingDesc,
    required this.requiresManualReview,
    required this.onFinalPriceChanged,
    this.editable = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Precio de renta'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Precio sugerido por IA:',
                      style: tt.bodyMedium,
                    ),
                  ),
                  fetchingPricing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          '\$${suggestedPrice.toStringAsFixed(0)} MXN/día',
                          style: tt.titleMedium?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Calculado con el motor de minería de datos de ToolShare',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              if (pricingDesc.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  pricingDesc,
                  style: tt.bodySmall?.copyWith(
                    color: cs.primary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const Divider(height: 20),
              Text(
                'Tu precio final: \$${finalPrice.toStringAsFixed(0)} MXN/día',
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Mínimo permitido: \$${minPrice.toStringAsFixed(0)} MXN/día (50%)',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              Slider(
                value: finalPrice.clamp(minPrice, maxRateVal),
                min: minPrice,
                max: maxRateVal,
                divisions: 30,
                label: '\$${finalPrice.toStringAsFixed(0)}',
                onChanged: (editable && !fetchingPricing)
                    ? onFinalPriceChanged
                    : null,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\$${minPrice.toStringAsFixed(0)} (mín)',
                    style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  Text(
                    '\$${maxRateVal.toStringAsFixed(0)} (máx)',
                    style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (requiresManualReview) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFF59E0B),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No encontramos una referencia de precio objetiva para esta herramienta. '
                    'Quedará marcada para revisión del administrador. Sube un ticket de compra para evitarlo.',
                    style: tt.bodySmall?.copyWith(
                      color: const Color(0xFFB45309),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
