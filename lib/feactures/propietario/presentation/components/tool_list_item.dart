import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entitie/tool_entity.dart';
import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/theme/theme_extensions.dart';

/// Prima mensual del seguro por herramienta: 5% del valor tasado por IA.
/// Es un producto independiente del plan de suscripción (Pro/Gratuito).
const double kInsuranceMonthlyRate = 0.05;

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

  double get _monthlyPremium => tool.estimatedValue * kInsuranceMonthlyRate;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: ListTile(
        onTap: onEdit,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
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
            if (tool.estimatedValue > 0)
              Positioned(
                right: -4,
                bottom: -4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: context.surface, width: 1.5),
                  ),
                  child: const Icon(Icons.shield_rounded,
                      size: 11, color: Colors.white),
                ),
              ),
          ],
        ),
        title: Text(
          tool.name,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
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
                  color: context.textSecondary,
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
            if (tool.estimatedValue > 0) ...[
              const SizedBox(height: 4),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.shield_outlined, size: 12, color: AppColors.success),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    'Seguro disponible: \$${_monthlyPremium.toStringAsFixed(0)}/mes',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
            ],
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
                    color: context.textSecondary, size: 20),
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