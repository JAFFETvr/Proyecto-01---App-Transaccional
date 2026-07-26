import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entitie/tool_entity.dart';
import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/theme/theme_extensions.dart';

class ToolCard extends StatelessWidget {
  final ToolEntity tool;
  final VoidCallback onTap;
  final String? zone;

  const ToolCard({
    super.key,
    required this.tool,
    required this.onTap,
    this.zone,
  });

  Widget _placeholderBg() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E293B),
            const Color(0xFF334155),
          ],
        ),
      ),
      child: Icon(
        Icons.handyman_outlined,
        size: 52,
        color: Colors.white.withValues(alpha: 0.15),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppColors.cardShadow,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    tool.photoUrl.isNotEmpty
                        ? Image.network(
                            tool.photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _placeholderBg(),
                            loadingBuilder: (ctx, child, progress) =>
                                progress == null ? child : _placeholderBg(),
                          )
                        : _placeholderBg(),
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.35),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (tool.category.isNotEmpty)
                      Positioned(
                        top: 10, left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tool.category,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.slate900,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 10, right: 10,
                      child: Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: tool.isAvailable
                              ? AppColors.success
                              : AppColors.danger,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tool.name,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '\$${(tool.dailyRate > 0 ? tool.dailyRate : 350.0).toStringAsFixed(0)} MXN /día',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.orange500,
                      ),
                    ),
                    if (tool.ownerName.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(children: [
                        Icon(Icons.person_outline_rounded,
                            size: 11, color: context.textSecondary),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            'Por: ${tool.ownerName}',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: context.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                    ],
                    const SizedBox(height: 6),
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
                        tool.isAvailable ? 'Disponible' : 'Rentado',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: tool.isAvailable
                              ? AppColors.success
                              : AppColors.danger,
                        ),
                      ),
                    ),
                    if (zone != null) ...[
                      const SizedBox(height: 5),
                      Row(children: [
                        Icon(Icons.location_on_outlined,
                            size: 11, color: context.textSecondary),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            zone!,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: context.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}