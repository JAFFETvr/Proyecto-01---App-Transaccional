import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entitie/tool_entity.dart';
import '../../../../../shared/theme/app_colors.dart';

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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF334155)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.handyman_outlined,
              color: Colors.white, size: 22),
        ),
        title: Text(
          tool.name,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.slate900,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tool.category.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                tool.category,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.slate600,
                ),
              ),
            ],
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: tool.isAvailable
                    ? AppColors.successBg
                    : AppColors.dangerBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tool.isAvailable ? 'Disponible' : 'En Renta',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: tool.isAvailable
                      ? AppColors.success
                      : AppColors.danger,
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
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit_outlined,
                    color: AppColors.slate600, size: 20),
                title: Text('Editar',
                    style: GoogleFonts.inter(fontSize: 14)),
                dense: true,
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: AppColors.danger, size: 20),
                title: Text('Eliminar',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.danger,
                    )),
                dense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}