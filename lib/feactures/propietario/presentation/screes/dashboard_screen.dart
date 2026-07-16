import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/tool_provider.dart';
import '../components/tool_list_item.dart';
import 'tool_form_screen.dart';
import 'pro_subscription_checkout_screen.dart';
import '../../../auth/login/presentation/screes/login_screen.dart';
import '../../../auth/login/presentation/providers/login_provider.dart';
import '../../../auth/register/presentation/providers/register_provider.dart';
import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/theme/theme_extensions.dart';
import '../../../checkout/presentation/providers/rental_provider.dart';
import '../../../checkout/presentation/screes/rental_tracking_owner_screen.dart';
import '../../../checkout/presentation/screes/my_rentals_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserName();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ToolProvider>().fetchTools();
      context.read<RentalProvider>().fetchRentals();
    });
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _userName = prefs.getString('user_name') ?? '');
    }
  }

  Future<void> _confirmDelete(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Eliminar herramienta',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
        content: Text(
          '¿Eliminar "$name"? No se puede deshacer.',
          style: GoogleFonts.inter(color: context.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: GoogleFonts.inter(color: context.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              minimumSize: const Size(80, 40),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final provider = context.read<ToolProvider>();
    final ok = await provider.deleteTool(id);

    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Error al eliminar')));
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    context.read<LoginProvider>().logout();
    context.read<RegisterProvider>().logout();
    context.read<ToolProvider>().clearTools();
    context.read<RentalProvider>().clearState();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ToolProvider>();
    final rentalProvider = context.watch<RentalProvider>();
    final activeRentals = rentalProvider.rentals
        .where((r) => !r.isCompleted && !r.isCancelled && !r.isDisputed)
        .toList();
    final bool hasActiveRental = activeRentals.isNotEmpty;
    final activeRental = activeRentals.firstOrNull;

    return Scaffold(
      backgroundColor: context.bg,
      drawer: Drawer(
        backgroundColor: context.surface,
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.handyman_rounded, size: 48, color: Colors.white),
                    const SizedBox(height: 10),
                    Text(
                      'Panel Propietario',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.assignment_rounded, color: AppColors.orange500),
              title: Text(
                'Mis Rentas',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
              ),
              trailing: activeRentals.isNotEmpty
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.orange500, borderRadius: BorderRadius.circular(12)),
                      child: Text('${activeRentals.length}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    )
                  : Icon(Icons.arrow_forward_ios_rounded, size: 16, color: context.colors.outline),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MyRentalsScreen()));
              },
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.danger),
              title: Text(
                'Cerrar sesión',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: AppColors.danger,
                ),
              ),
              onTap: _logout,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      // ── FAB con degradado naranja ─────────────────────────────────────────
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.primaryButtonShadow,
        ),
        child: FloatingActionButton.extended(
          onPressed: () async {
            await Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ToolFormScreen()));
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: Text(
            'Nueva Herramienta',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // ── AppBar ────────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: context.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(0),
              child: Container(height: 1, color: context.borderColor),
            ),
            title: Row(children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.construction_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Mi Panel',
                style: GoogleFonts.montserrat(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary,
                ),
              ),
            ]),
            actions: [
              IconButton(
                icon: Badge(
                  isLabelVisible: activeRentals.isNotEmpty,
                  label: Text('${activeRentals.length}'),
                  child: const Icon(Icons.assignment_rounded),
                ),
                color: AppColors.orange500,
                tooltip: 'Mis Rentas',
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyRentalsScreen())),
              ),
            ],
          ),

          // ── Saludo ────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hola, $_userName 👋',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: context.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gestiona tu inventario',
                    style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Tarjeta Plan Suscripción ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: provider.isPro
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF059669), Color(0xFF10B981)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white24,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.stars_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Plan Pro Activo 👑',
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Publica herramientas ilimitadas y de cualquier valor.',
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.borderColor),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.orange500.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.info_outline_rounded, color: AppColors.orange500, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Plan Gratuito',
                                style: GoogleFonts.montserrat(
                                  color: context.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Límite de hasta 3 herramientas y valor máximo de \$1,500 MXN por activo.',
                            style: GoogleFonts.inter(
                              color: context.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: provider.loading
                                  ? null
                                  : () => openProSubscriptionCheckout(context),
                              icon: const Icon(Icons.bolt_rounded, size: 16),
                              label: const Text('Adquirir Plan Pro (\$69/mes)'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.orange500,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),

          // ── Banner de Renta en Progreso (Propietario) ─────────────────────
          if (hasActiveRental)
            SliverToBoxAdapter(
              child: GestureDetector(
                onTap: () {
                  if (activeRentals.length > 1) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyRentalsScreen()),
                    );
                  } else if (activeRental != null) {
                    rentalProvider.setCurrentRental(activeRental);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RentalTrackingOwnerScreen(),
                        settings: RouteSettings(arguments: activeRental),
                      ),
                    );
                  }
                },
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.handshake_outlined,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activeRentals.length > 1
                                  ? '${activeRentals.length} rentas en progreso'
                                  : 'Herramienta en renta',
                              style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              activeRentals.length > 1
                                  ? 'Toca para gestionar todas tus rentas'
                                  : (activeRental!.isPending
                                      ? 'Pendiente de entrega — Toca para gestionar'
                                      : 'Activa — Toca para ver el estado'),
                              style: GoogleFonts.inter(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: Colors.white, size: 22),
                    ],
                  ),
                ),
              ),
            ),

          // ── Metric cards ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(children: [
                _MetricCard(
                  label: 'Total',
                  value: '${provider.totalTools}',
                  icon: Icons.handyman_outlined,
                  color: AppColors.orange500,
                ),
                const SizedBox(width: 12),
                _MetricCard(
                  label: 'Disponibles',
                  value: '${provider.availableCount}',
                  icon: Icons.check_circle_outline,
                  color: AppColors.success,
                ),
                const SizedBox(width: 12),
                _MetricCard(
                  label: 'En Renta',
                  value: '${provider.rentedCount}',
                  icon: Icons.timer_outlined,
                  color: const Color(0xFF6366F1),
                ),
              ]),
            ),
          ),

          // ── Encabezado lista ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                'Mis Herramientas',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
            ),
          ),

          // ── Lista ─────────────────────────────────────────────────────────
          if (provider.loading)
            const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()))
          else if (provider.error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.wifi_off_rounded, size: 48,
                      color: context.colors.outline),
                  const SizedBox(height: 12),
                  Text(provider.error!,
                      style: GoogleFonts.inter(color: context.textSecondary)),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () =>
                        context.read<ToolProvider>().fetchTools(),
                    style: FilledButton.styleFrom(
                        minimumSize: const Size(140, 44)),
                    child: const Text('Reintentar'),
                  ),
                ]),
              ),
            )
          else if (provider.tools.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.inbox_rounded, size: 56, color: context.colors.outline),
                  const SizedBox(height: 12),
                  Text('Sin herramientas',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.textSecondary,
                      )),
                ]),
              ),
            )
          else
            SliverSafeArea(
              top: false,
              sliver: SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => ToolListItem(
                      tool: provider.tools[i],
                      onEdit: () => Navigator.push(ctx,
                          MaterialPageRoute(
                              builder: (_) =>
                                  ToolFormScreen(tool: provider.tools[i]))),
                      onDelete: () => _confirmDelete(
                          provider.tools[i].id, provider.tools[i].name),
                    ),
                    childCount: provider.tools.length,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── _MetricCard ─────────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: context.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ]),
      ),
    );
  }
}