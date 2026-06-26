import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entitie/tool_entity.dart';
import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/widgets/primary_gradient_button.dart';

class ToolDetailScreen extends StatefulWidget {
  final ToolEntity tool;
  final double pricePerDay;

  const ToolDetailScreen({
    super.key,
    required this.tool,
    this.pricePerDay = 350.0,
  });

  @override
  State<ToolDetailScreen> createState() => _ToolDetailScreenState();
}

class _ToolDetailScreenState extends State<ToolDetailScreen> {
  int _days = 1;

  double get _effectiveRate => widget.tool.dailyRate > 0 ? widget.tool.dailyRate : widget.pricePerDay;
  double get _subtotal => _effectiveRate * _days;
  double get _deposit  => _subtotal * 0.10;
  double get _total    => _subtotal + _deposit;

  @override
  Widget build(BuildContext context) {
    final tool = widget.tool;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero AppBar ─────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.slate900,
            surfaceTintColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Fondo industrial oscuro con degradado
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF1E293B),
                          Color(0xFF0F172A),
                        ],
                      ),
                    ),
                    child: Stack(children: [
                      // Textura de herramienta grande semitransparente
                      Center(
                        child: Icon(
                          Icons.handyman_outlined,
                          size: 140,
                          color: Colors.white.withOpacity(0.06),
                        ),
                      ),
                      Center(
                        child: Container(
                          width: 110, height: 110,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.orange500.withOpacity(0.15),
                                AppColors.orange600.withOpacity(0.08),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.handyman_rounded,
                            size: 56,
                            color: AppColors.orange500.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ]),
                  ),
                  // Overlay inferior para transición suave
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            AppColors.background,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Badge categoría
                  if (tool.category.isNotEmpty)
                    Positioned(
                      top: 56, right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Text(
                          tool.category,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Contenido ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre + badge disponibilidad
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          tool.name,
                          style: GoogleFonts.montserrat(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.slate900,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: tool.isAvailable
                              ? AppColors.successBg
                              : AppColors.dangerBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tool.isAvailable ? 'Disponible' : 'Rentada',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: tool.isAvailable
                                ? AppColors.success
                                : AppColors.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Ubicación + rating
                  Row(children: [
                    Icon(Icons.location_on_outlined,
                        size: 14, color: AppColors.slate600),
                    const SizedBox(width: 4),
                    Text(
                      '~2.3 km · Zona Norte',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.slate600),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.star_rounded,
                        size: 14, color: AppColors.amber),
                    const SizedBox(width: 4),
                    Text(
                      '4.8 (23 rentas)',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.slate600),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // Divider sutil
                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 16),

                  // Descripción
                  Text(
                    'Descripción',
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tool.description.isNotEmpty
                        ? tool.description
                        : 'Sin descripción disponible.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.slate600,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Info chips
                  Row(children: [
                    _InfoChip(
                      icon: Icons.build_circle_outlined,
                      label: 'Estado',
                      value: 'Buen Estado',
                      color: const Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 10),
                    _InfoChip(
                      icon: Icons.calendar_today_outlined,
                      label: 'Precio/día',
                      value: '\$${_effectiveRate.toStringAsFixed(0)} MXN',
                      color: AppColors.orange500,
                    ),
                  ]),
                  const SizedBox(height: 28),

                  // ── Calculadora de renta ─────────────────────────────────
                  Text(
                    'Calcular costo de renta',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate900,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Column(
                      children: [
                        // Selector de días
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Días de renta:',
                                style: GoogleFonts.inter(
                                    fontSize: 14, color: AppColors.slate900)),
                            Row(children: [
                              _DayButton(
                                icon: Icons.remove_rounded,
                                onPressed: _days > 1
                                    ? () => setState(() => _days--)
                                    : null,
                              ),
                              SizedBox(
                                width: 42,
                                child: Text(
                                  '$_days',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.orange500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              _DayButton(
                                icon: Icons.add_rounded,
                                onPressed: _days < 30
                                    ? () => setState(() => _days++)
                                    : null,
                              ),
                            ]),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 14),

                        _CostRow(
                          label:
                              'Renta ($_days día${_days > 1 ? 's' : ''}):',
                          value: '\$${_subtotal.toStringAsFixed(2)} MXN',
                          valueBold: false,
                        ),
                        const SizedBox(height: 8),

                        // Deducible / Depósito en garantía
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: const Border(
                              left: BorderSide(
                                  color: Color(0xFFE2E8F0), width: 3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _CostRow(
                                label: 'Depósito en garantía (10%):',
                                value: '\$${_deposit.toStringAsFixed(2)} MXN',
                                valueBold: false,
                                labelColor: AppColors.slate600,
                                valueColor: AppColors.slate600,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Se devuelve al finalizar en buen estado',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.slate600.withOpacity(0.7),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Divider(color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 14),

                        _CostRow(
                          label: 'Total a pagar:',
                          value: '\$${_total.toStringAsFixed(2)} MXN',
                          valueBold: true,
                          valueColor: AppColors.orange500,
                          labelBold: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Banner de confianza
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.successBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.success.withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      Icon(Icons.shield_outlined,
                          color: AppColors.success, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Tu pago está protegido. Los fondos se retienen y solo se liberan cuando confirmas la entrega.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF064E3B),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Botón principal con degradado naranja ────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: tool.isAvailable
              ? PrimaryGradientButton(
                  label:
                      'Proceder al Pago — \$${_total.toStringAsFixed(0)} MXN',
                  icon: Icons.lock_outline,
                  height: 55,
                  onPressed: () => Navigator.of(context).pushNamed(
                    '/checkout',
                    arguments: {
                      'tool': tool,
                      'days': _days,
                      'pricePerDay': _effectiveRate,
                      'total': _total,
                      'deposit': _deposit,
                    },
                  ),
                )
              : PrimaryGradientButton(
                  label: 'Herramienta no disponible',
                  onPressed: null,
                ),
        ),
      ),
    );
  }
}

// ── Widgets internos ────────────────────────────────────────────────────────

class _DayButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _DayButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: isEnabled
              ? AppColors.orange500.withOpacity(0.1)
              : AppColors.slate100,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 16,
          color: isEnabled ? AppColors.orange500 : AppColors.slate300,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.slate600,
                )),
          ]),
          const SizedBox(height: 5),
          Text(value,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              )),
        ]),
      ),
    );
  }
}

class _CostRow extends StatelessWidget {
  final String label;
  final String value;
  final bool valueBold;
  final bool labelBold;
  final Color? labelColor;
  final Color? valueColor;

  const _CostRow({
    required this.label,
    required this.value,
    this.valueBold = false,
    this.labelBold = false,
    this.labelColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight:
                labelBold ? FontWeight.w700 : FontWeight.w500,
            color: labelColor ?? AppColors.slate900,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight:
                valueBold ? FontWeight.w800 : FontWeight.w600,
            color: valueColor ?? AppColors.slate900,
          ),
        ),
      ],
    );
  }
}
