import 'package:flutter/material.dart';
import '../../domain/entitie/tool_entity.dart';

class ToolListItem extends StatelessWidget {
  final ToolEntity tool;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ToolListItem({
    super.key,
    required this.tool,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: cs.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.handyman_outlined,
              color: cs.onSecondaryContainer, size: 24),
        ),
        title: Text(tool.name,
            style: tt.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tool.category.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(tool.category,
                  style: tt.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant)),
            ],
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: tool.isAvailable
                    ? const Color(0xFF16A34A).withOpacity(0.1)
                    : cs.errorContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tool.isAvailable ? 'Disponible' : 'En Renta',
                style: tt.labelSmall?.copyWith(
                  color: tool.isAvailable
                      ? const Color(0xFF16A34A) : cs.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'edit') onEdit();
            if (v == 'delete') onDelete();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit',
                child: ListTile(leading: Icon(Icons.edit_outlined),
                    title: Text('Editar'), dense: true)),
            PopupMenuItem(value: 'delete',
                child: ListTile(leading: Icon(Icons.delete_outline),
                    title: Text('Eliminar'), dense: true)),
          ],
        ),
      ),
    );
  }
}