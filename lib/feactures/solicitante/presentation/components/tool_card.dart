import 'package:flutter/material.dart';
import '../../domain/entitie/tool_entity.dart';

class ToolCard extends StatelessWidget {
  final ToolEntity tool;
  final VoidCallback onTap;

  const ToolCard({super.key, required this.tool, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen con Stack de badges
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Fondo
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          cs.secondaryContainer,
                          cs.primaryContainer.withOpacity(0.5),
                        ],
                      ),
                    ),
                    child: Icon(Icons.handyman_outlined,
                        size: 48,
                        color: cs.primary.withOpacity(0.6)),
                  ),
                  // Badge categoría (Stack)
                  if (tool.category.isNotEmpty)
                    Positioned(
                      top: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: cs.surface.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(tool.category,
                            style: tt.labelSmall?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  // Punto disponibilidad (Stack)
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      width: 12, height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: tool.isAvailable
                            ? const Color(0xFF16A34A) : cs.error,
                        border: Border.all(color: cs.surface, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tool.name,
                      style: tt.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: tool.isAvailable
                              ? const Color(0xFF16A34A).withOpacity(0.1)
                              : cs.errorContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tool.isAvailable ? 'Disponible' : 'Rentado',
                          style: tt.labelSmall?.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: tool.isAvailable
                                ? const Color(0xFF16A34A) : cs.error,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 12, color: cs.onSurfaceVariant),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}