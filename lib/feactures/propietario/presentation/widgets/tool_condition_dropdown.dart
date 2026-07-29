import 'package:flutter/material.dart';

import 'section_title.dart';

/// Solo lectura: la condición la asigna la CNN, no el usuario.
class ToolConditionDropdown extends StatelessWidget {
  static const options = ['Nuevo', 'Buen Estado', 'Desgastado'];

  final String wearLevel;
  final bool isEditing;

  const ToolConditionDropdown({
    super.key,
    required this.wearLevel,
    required this.isEditing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Condición física'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
            border: Border.all(color: cs.outline),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: wearLevel,
              isExpanded: true,
              icon: const Icon(Icons.lock_outline, size: 18),
              items: options.map((w) {
                final color = w == 'Nuevo'
                    ? const Color(0xFF16A34A)
                    : w == 'Buen Estado'
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFDC2626);
                return DropdownMenuItem(
                  value: w,
                  child: Row(children: [
                    Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Text(w),
                  ]),
                );
              }).toList(),
              // Siempre null: el usuario nunca elige la condición a mano, ni
              // al crear ni al editar.
              onChanged: null,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isEditing
              ? 'La condición se definió al publicar la herramienta, según tus fotos.'
              : 'La condición la calcula la IA a partir de las fotos que subas arriba.',
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}
