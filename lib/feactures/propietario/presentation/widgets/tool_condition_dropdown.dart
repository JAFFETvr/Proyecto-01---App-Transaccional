import 'package:flutter/material.dart';

import 'section_title.dart';

/// Selector de condición física de la herramienta. Solo editable al publicar;
/// después queda fija (la ajusta la IA a partir de la foto).
class ToolConditionDropdown extends StatelessWidget {
  static const options = ['Nuevo', 'Buen Estado', 'Desgastado'];

  final String wearLevel;
  final bool isEditing;
  final ValueChanged<String> onChanged;

  const ToolConditionDropdown({
    super.key,
    required this.wearLevel,
    required this.isEditing,
    required this.onChanged,
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
            color: isEditing ? cs.surfaceContainerHighest.withValues(alpha: 0.3) : null,
            border: Border.all(color: cs.outline),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: wearLevel,
              isExpanded: true,
              icon: Icon(isEditing ? Icons.lock_outline : Icons.expand_more,
                  size: isEditing ? 18 : 24),
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
              onChanged: isEditing ? null : (v) => onChanged(v!),
            ),
          ),
        ),
        if (isEditing) ...[
          const SizedBox(height: 6),
          Text(
            'La condición se define solo al publicar la herramienta.',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}
