import 'package:flutter/material.dart';

class RoleSelector extends StatelessWidget {
  final String selectedRole;
  final ValueChanged<String> onChanged;

  const RoleSelector({
    super.key,
    required this.selectedRole,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: _RoleCard(
          title: 'Propietario',
          subtitle: 'Publica y gestiona tus herramientas',
          icon: Icons.business_center_outlined,
          isSelected: selectedRole == 'owner',
          onTap: () => onChanged('owner'),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _RoleCard(
          title: 'Solicitante',
          subtitle: 'Busca y renta herramientas',
          icon: Icons.handyman_outlined,
          isSelected: selectedRole == 'requester',
          onTap: () => onChanged('requester'),
        ),
      ),
    ]);
  }
}

class _RoleCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title, required this.subtitle,
    required this.icon, required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? cs.primary : cs.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? cs.primaryContainer.withValues(alpha: 0.3)
              : cs.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon,
                color: isSelected ? cs.primary : cs.onSurfaceVariant,
                size: 26),
            const SizedBox(height: 8),
            Text(title,
                style: tt.titleSmall?.copyWith(
                    color: isSelected ? cs.primary : cs.onSurface,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: tt.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant),
                maxLines: 2),
          ],
        ),
      ),
    );
  }
}