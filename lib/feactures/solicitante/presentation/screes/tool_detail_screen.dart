import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../domain/entitie/tool_entity.dart';
import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/theme/theme_extensions.dart';
import '../../../../../shared/widgets/primary_gradient_button.dart';
import '../../../review/presentation/providers/review_provider.dart';
import '../../../review/presentation/components/review_stars.dart';

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
  late final TextEditingController _daysCtrl =
      TextEditingController(text: _days.toString());

  double get _effectiveRate => widget.tool.dailyRate > 0 ? widget.tool.dailyRate : widget.pricePerDay;
  double get _subtotal => _effectiveRate * _days;
  double get _deposit  => _subtotal * 0.10;
  double get _total    => _subtotal + _deposit;

  void _setDays(int value) {
    final clamped = value.clamp(1, 30);
    setState(() => _days = clamped);
    final text = clamped.toString();
    if (_daysCtrl.text != text) {
      _daysCtrl.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReviewProvider>().fetchToolReviews(widget.tool.id);
    });
  }

  @override
  void dispose() {
    _daysCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tool = widget.tool;
    final reviewsResult = context.watch<ReviewProvider>().toolReviews;

    return Scaffold(
      backgroundColor: context.bg,
      body: CustomScrollView(
        slivers: [
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
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            context.bg,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
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

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          tool.name,
                          style: GoogleFonts.montserrat(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: context.textPrimary,
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

                  Row(children: [
                    Icon(Icons.location_on_outlined,
                        size: 14, color: context.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '~2.3 km · Zona Norte',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: context.textSecondary),
                    ),
                    const SizedBox(width: 16),
                    if (reviewsResult.reviewCount > 0) ...[
                      Icon(Icons.star_rounded,
                          size: 14, color: AppColors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${reviewsResult.averageRating.toStringAsFixed(1)} (${reviewsResult.reviewCount} reseña${reviewsResult.reviewCount == 1 ? '' : 's'})',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: context.textSecondary),
                      ),
                    ] else
                      Text(
                        'Sin reseñas todavía',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: context.textSecondary),
                      ),
                  ]),
                  if (tool.ownerName.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      Icon(Icons.person_outline_rounded,
                          size: 14, color: context.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'Propietario: ${tool.ownerName}',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: context.textSecondary),
                      ),
                    ]),
                  ],
                  const SizedBox(height: 20),

                  Divider(color: context.borderColor),
                  const SizedBox(height: 16),

                  Text(
                    'Descripción',
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tool.description.isNotEmpty
                        ? tool.description
                        : 'Sin descripción disponible.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: context.textSecondary,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (reviewsResult.reviewCount > 0) ...[
                    Row(children: [
                      Text(
                        'Reseñas',
                        style: GoogleFonts.montserrat(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ReviewStars(rating: reviewsResult.averageRating, size: 14),
                    ]),
                    const SizedBox(height: 10),
                    ...reviewsResult.reviews.take(3).map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: context.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: context.borderColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ReviewStars(rating: r.rating.toDouble(), size: 13),
                                if (r.comment.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    r.comment,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: context.textSecondary,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )),
                    const SizedBox(height: 10),
                  ],

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

                  Text(
                    'Calcular costo de renta',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: context.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Días de renta:',
                                style: GoogleFonts.inter(
                                    fontSize: 14, color: context.textPrimary)),
                            Row(children: [
                              _DayButton(
                                icon: Icons.remove_rounded,
                                onPressed: _days > 1
                                    ? () => _setDays(_days - 1)
                                    : null,
                              ),
                              SizedBox(
                                width: 48,
                                child: TextField(
                                  controller: _daysCtrl,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.orange500,
                                  ),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: 6),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                  ),
                                  onChanged: (v) {
                                    final parsed = int.tryParse(v);
                                    if (parsed != null) _setDays(parsed);
                                  },
                                  onSubmitted: (v) {
                                    final parsed = int.tryParse(v);
                                    _setDays(parsed ?? _days);
                                  },
                                ),
                              ),
                              _DayButton(
                                icon: Icons.add_rounded,
                                onPressed: _days < 30
                                    ? () => _setDays(_days + 1)
                                    : null,
                              ),
                            ]),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Divider(color: context.borderColor),
                        const SizedBox(height: 14),

                        _CostRow(
                          label:
                              'Renta ($_days día${_days > 1 ? 's' : ''}):',
                          value: '\$${_subtotal.toStringAsFixed(2)} MXN',
                          valueBold: false,
                        ),
                        const SizedBox(height: 8),

                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: context.colors.surfaceContainerHighest.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border(
                              left: BorderSide(
                                  color: context.borderColor, width: 3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _CostRow(
                                label: 'Comisión de servicio (10%):',
                                value: '\$${_deposit.toStringAsFixed(2)} MXN',
                                valueBold: false,
                                labelColor: context.textSecondary,
                                valueColor: context.textSecondary,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Cargo de la plataforma por el servicio de renta',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: context.textSecondary.withValues(alpha: 0.7),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Divider(color: context.borderColor),
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

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.colors.tertiaryContainer,
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
                            color: context.colors.onTertiaryContainer,
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
              : context.colors.surfaceContainerHigh,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 16,
          color: isEnabled ? AppColors.orange500 : context.colors.outline,
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
                  color: context.textSecondary,
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
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight:
                  labelBold ? FontWeight.w700 : FontWeight.w500,
              color: labelColor ?? context.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight:
                valueBold ? FontWeight.w800 : FontWeight.w600,
            color: valueColor ?? context.textPrimary,
          ),
        ),
      ],
    );
  }
}
