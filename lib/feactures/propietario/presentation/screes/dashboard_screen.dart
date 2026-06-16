import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/tool_provider.dart';
import '../components/tool_list_item.dart';
import 'tool_form_screen.dart';
import '../../../auth/login/presentation/screes/login_screen.dart';
import '../../../../../shared/theme/app_colors.dart';

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
          style: GoogleFonts.inter(color: AppColors.slate600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: GoogleFonts.inter(color: AppColors.slate600)),
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
    context.read<ToolProvider>().clearTools();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ToolProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
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
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(0),
              child: Container(height: 1, color: const Color(0xFFE2E8F0)),
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
                  color: AppColors.slate900,
                ),
              ),
            ]),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                color: AppColors.slate600,
                onPressed: _logout,
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
                      color: AppColors.slate600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gestiona tu inventario',
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
                  color: AppColors.slate900,
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
                      color: AppColors.slate300),
                  const SizedBox(height: 12),
                  Text(provider.error!,
                      style: GoogleFonts.inter(color: AppColors.slate600)),
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
                  Icon(Icons.inbox_rounded, size: 56, color: AppColors.slate300),
                  const SizedBox(height: 12),
                  Text('Sin herramientas',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate600,
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
          color: AppColors.surface,
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
              color: AppColors.slate600,
            ),
            textAlign: TextAlign.center,
          ),
        ]),
      ),
    );
  }
}