import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../auth/login/presentation/screes/login_screen.dart';
import '../../../checkout/domain/entitie/rental_entity.dart';
import '../providers/admin_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _currentFilter = 'disputed'; // 'disputed' o ''

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchDashboardData(statusFilter: _currentFilter);
    });
  }

  void _changeFilter(String newFilter) {
    if (_currentFilter == newFilter) return;
    setState(() => _currentFilter = newFilter);
    context.read<AdminProvider>().fetchDashboardData(statusFilter: newFilter);
  }

  void _showResolveDialog(RentalEntity rental) {
    final notesCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Encabezado Judicial ──────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: AppColors.primaryButtonShadow,
                  ),
                  child: const Icon(Icons.gavel_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dictamen Judicial AI',
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.slate900,
                        ),
                      ),
                      Text(
                        'Contrato Renta #${rental.id.length > 8 ? rental.id.substring(0, 8) : rental.id}',
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Evidencia reportada ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.report_problem_rounded, color: AppColors.danger, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Motivo de Disputa Reportado:',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.slate700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    rental.disputeReason.isNotEmpty ? rental.disputeReason : 'Sin descripción proporcionada.',
                    style: GoogleFonts.inter(fontSize: 14, color: AppColors.slate900, height: 1.4),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: AppColors.slate200),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Garantía Retenida en MP:',
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate600),
                      ),
                      Text(
                        '\$${rental.deductibleAmount.toStringAsFixed(2)} MXN',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.emerald600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Campo de notas judiciales ────────────────────────────────────
            Text(
              'Justificación Judicial del Dictamen:',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.slate900,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: notesCtrl,
              maxLines: 3,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.slate900),
              decoration: InputDecoration(
                hintText: 'Ej. Daño verificado por visión artificial post-entrega. Se procede a cobrar garantía...',
                hintStyle: GoogleFonts.inter(color: AppColors.slate400, fontSize: 13),
                filled: true,
                fillColor: AppColors.background,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.slate200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.orange500, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Botones de Ejecución ─────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final ok = await context.read<AdminProvider>().resolveDispute(
                        rentalId: rental.id,
                        action: 'refund',
                        notes: notesCtrl.text.trim(),
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(ok ? 'Reembolso liberado al Solicitante ✓' : 'Error al dictaminar')),
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.slate700,
                      side: const BorderSide(color: AppColors.slate300),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      'Favor Solicitante\n(Reembolsar todo)',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: AppColors.primaryButtonShadow,
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final ok = await context.read<AdminProvider>().resolveDispute(
                          rentalId: rental.id,
                          action: 'capture',
                          notes: notesCtrl.text.trim(),
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(ok ? 'Garantía cobrada a favor del Propietario ✓' : 'Error al dictaminar')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        'Favor Propietario\n(Cobrar garantía)',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final stats = provider.stats;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── AppBar limpia estilo Fintech Industrial ────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(0),
              child: Container(height: 1, color: AppColors.slate200),
            ),
            title: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: AppColors.primaryButtonShadow,
                  ),
                  child: const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Panel Core Admin',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate900,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                color: AppColors.slate600,
                tooltip: 'Actualizar datos',
                onPressed: () => provider.fetchDashboardData(statusFilter: _currentFilter),
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                color: AppColors.slate600,
                tooltip: 'Cerrar sesión',
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  );
                },
              ),
            ],
          ),

          // ── Subtítulo de bienvenida ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Centro de Arbitraje y Resguardo MP',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Supervisión Algorítmica',
                    style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slate900,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Cuadrícula de Métricas ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          title: 'Fondos Congelados',
                          value: '\$${stats?.frozenFunds.toStringAsFixed(0) ?? '0'} MXN',
                          icon: Icons.lock_rounded,
                          iconColor: AppColors.emerald600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricCard(
                          title: 'Disputas Alerta AI',
                          value: '${stats?.disputedRentals ?? 0}',
                          icon: Icons.warning_rounded,
                          iconColor: AppColors.orange500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          title: 'Activos Totales',
                          value: '${stats?.totalTools ?? 0}',
                          icon: Icons.handyman_rounded,
                          iconColor: AppColors.blue600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricCard(
                          title: 'Contratos Activos',
                          value: '${stats?.activeRentals ?? 0} / ${stats?.totalRentals ?? 0}',
                          icon: Icons.assignment_turned_in_rounded,
                          iconColor: AppColors.purple600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Selector de Filtros (Chips) ────────────────────────────────────
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                children: [
                  _FilterChip(
                    label: '🚨 Disputas Pendientes',
                    isSelected: _currentFilter == 'disputed',
                    onTap: () => _changeFilter('disputed'),
                  ),
                  const SizedBox(width: 10),
                  _FilterChip(
                    label: '📦 Todas las Operaciones',
                    isSelected: _currentFilter == '',
                    onTap: () => _changeFilter(''),
                  ),
                ],
              ),
            ),
          ),

          // ── Lista de Alquileres ────────────────────────────────────────────
          if (provider.loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator(color: AppColors.orange500)),
            )
          else if (provider.rentals.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.slate100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.done_all_rounded, size: 48, color: AppColors.slate400),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _currentFilter == 'disputed'
                          ? 'Excelente. No hay disputas pendientes.'
                          : 'No hay registros de alquileres.',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
              sliver: SliverList.builder(
                itemCount: provider.rentals.length,
                itemBuilder: (ctx, i) {
                  final r = provider.rentals[i];
                  final isDisputed = r.status == 'disputed';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: AppColors.cardShadow,
                      border: Border.all(
                        color: isDisputed ? AppColors.orange500 : AppColors.slate200,
                        width: isDisputed ? 1.5 : 1.0,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _StatusBadge(status: r.status),
                              Text(
                                '\$${r.totalAmount.toStringAsFixed(0)} MXN',
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                  color: AppColors.slate900,
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1, color: AppColors.slate100),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.qr_code_rounded, size: 16, color: AppColors.slate400),
                              const SizedBox(width: 6),
                              Text(
                                'Contrato #${r.id}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.slate500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.slate400),
                              const SizedBox(width: 6),
                              Text(
                                '${r.startDate.split('T')[0]}  →  ${r.endDate.split('T')[0]}',
                                style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate700),
                              ),
                            ],
                          ),
                          if (r.disputeReason.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.dangerBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Reporte de Incidente:',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.danger,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    r.disputeReason,
                                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate900),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (isDisputed) ...[
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: AppColors.primaryButtonShadow,
                              ),
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.gavel_rounded, size: 18),
                                label: Text(
                                  'Dictaminar Arbitraje AI',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () => _showResolveDialog(r),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ── Tarjeta de Métrica Elegante ──────────────────────────────────────────────
class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.cardShadow,
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate500,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.slate900,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chip de Filtro Interactivo ───────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.slate300,
          ),
          boxShadow: isSelected ? AppColors.primaryButtonShadow : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.slate700,
          ),
        ),
      ),
    );
  }
}

// ── Medalla de Estado Semántico ──────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (status.toLowerCase()) {
      case 'disputed':
        bg = AppColors.dangerBg;
        fg = AppColors.danger;
        break;
      case 'completed':
        bg = AppColors.successBg;
        fg = AppColors.success;
        break;
      case 'active':
        bg = AppColors.blue600.withOpacity(0.15);
        fg = AppColors.blue600;
        break;
      default:
        bg = AppColors.slate100;
        fg = AppColors.slate600;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: fg),
      ),
    );
  }
}
