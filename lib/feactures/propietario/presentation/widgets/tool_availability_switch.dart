import 'package:flutter/material.dart';

class ToolAvailabilitySwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const ToolAvailabilitySwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: const Text('Disponible para renta'),
        subtitle: Text(
          value ? 'Visible en el catálogo' : 'Oculta del catálogo',
          style: TextStyle(
            fontSize: 12,
            color: value ? const Color(0xFF16A34A) : cs.error,
          ),
        ),
        secondary: Icon(
          value ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: value ? const Color(0xFF16A34A) : cs.error,
        ),
        activeThumbColor: const Color(0xFF16A34A),
      ),
    );
  }
}
