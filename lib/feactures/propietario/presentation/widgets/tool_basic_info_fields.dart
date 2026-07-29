import 'package:flutter/material.dart';

import 'section_title.dart';

/// Campos de datos básicos de la herramienta.
class ToolBasicInfoFields extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController brandCtrl;
  final TextEditingController modelCtrl;
  final TextEditingController ageCtrl;
  final TextEditingController catCtrl;
  final TextEditingController estValCtrl;
  final TextEditingController descCtrl;
  final bool isEditing;
  final bool ticketValidado;
  final bool fetchingPricing;
  final List<String> categories;
  final VoidCallback onFieldChanged;
  final ValueChanged<String> onCategorySelected;

  const ToolBasicInfoFields({
    super.key,
    required this.nameCtrl,
    required this.brandCtrl,
    required this.modelCtrl,
    required this.ageCtrl,
    required this.catCtrl,
    required this.estValCtrl,
    required this.descCtrl,
    required this.isEditing,
    required this.ticketValidado,
    required this.fetchingPricing,
    required this.categories,
    required this.onFieldChanged,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Información básica'),
        const SizedBox(height: 12),

        TextFormField(
          controller: nameCtrl,
          enabled: !isEditing,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Nombre *',
            hintText: 'Ej. Taladro Percutor',
            prefixIcon: Icon(Icons.construction_outlined),
          ),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
          onChanged: (_) => onFieldChanged(),
        ),
        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: brandCtrl,
                enabled: !isEditing,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Marca',
                  hintText: 'DeWalt',
                  prefixIcon: Icon(Icons.business_outlined),
                ),
                onChanged: (_) => onFieldChanged(),
                onEditingComplete: () {
                  FocusScope.of(context).nextFocus();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: modelCtrl,
                enabled: !isEditing,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Modelo',
                  hintText: 'DCD777',
                ),
                onChanged: (_) => onFieldChanged(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        TextFormField(
          controller: ageCtrl,
          enabled: !isEditing,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Antigüedad (Meses) *',
            hintText: 'Ej. 12',
            prefixIcon: Icon(Icons.calendar_today_outlined),
          ),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
          onChanged: (_) => onFieldChanged(),
        ),

        const SizedBox(height: 14),

        TextFormField(
          controller: estValCtrl,
          readOnly: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Valor de catálogo estimado (MXN)',
            hintText: 'Se calcula automáticamente',
            prefixIcon: const Icon(Icons.attach_money_outlined),
            suffixIcon: fetchingPricing
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Icon(
                    Icons.lock_outline,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
            helperText: isEditing
                ? 'No editable después de publicar la herramienta'
                : (ticketValidado
                      ? 'Verificado con tu ticket de compra'
                      : 'Calculado con el catálogo de referencia de ToolShare'),
          ),
          validator: (v) {
            final val = double.tryParse(v ?? '');
            if (val == null || val <= 0) {
              return 'Completa nombre y categoría para calcularlo';
            }
            return null;
          },
        ),
        const SizedBox(height: 14),

        TextFormField(
          controller: descCtrl,
          enabled: !isEditing,
          maxLines: 3,
          maxLength: 300,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Descripción',
            hintText: 'Estado, características, accesorios incluidos…',
          ),
        ),
      ],
    );
  }
}
