import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/catalog_provider.dart';
import '../components/tool_card.dart';
import '../../domain/entitie/tool_entity.dart';
import '../../../auth/login/presentation/screes/login_screen.dart';
import '../../../auth/login/presentation/providers/login_provider.dart';
import '../../../auth/register/presentation/providers/register_provider.dart';
import '../../../propietario/presentation/providers/tool_provider.dart';
import 'tool_detail_screen.dart';
import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/theme/theme_extensions.dart';
import '../../../checkout/presentation/providers/rental_provider.dart';
import '../../../checkout/presentation/screes/rental_tracking_requester_screen.dart';
import '../../../checkout/presentation/screes/my_rentals_screen.dart';
import 'catalog_map_screen.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogProvider>().fetchTools();
      context.read<RentalProvider>().fetchRentals();
    });
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

  void _showDetail(BuildContext context, ToolEntity tool) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ToolDetailScreen(
          tool: tool,
          pricePerDay: tool.dailyRate > 0 ? tool.dailyRate : 350.0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CatalogProvider>();
    final tools = provider.filtered;
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
                    const Icon(Icons.person_outline, size: 48, color: Colors.white),
                    const SizedBox(height: 10),
                    Text(
                      'Mi Perfil',
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: true,
            backgroundColor: context.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.logout_rounded),
              color: context.textSecondary,
              onPressed: _logout,
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(0),
              child: Container(
                height: 1,
                color: context.borderColor,
              ),
            ),
            title: Row(
              children: [
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ToolShare',
                      style: GoogleFonts.montserrat(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimary,
                      ),
                    ),
                    Text(
                      '${provider.totalCount} herramientas',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: FilterChip(
                  label: Text(
                    'Disponibles',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  selected: provider.onlyAvailable,
                  onSelected: (v) =>
                      context.read<CatalogProvider>().setOnlyAvailable(v),
                  showCheckmark: false,
                  selectedColor: context.colors.tertiaryContainer,
                  labelStyle: GoogleFonts.inter(
                    color: provider.onlyAvailable
                        ? AppColors.success
                        : context.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  side: BorderSide(
                    color: provider.onlyAvailable
                        ? AppColors.success
                        : context.borderColor,
                  ),
                ),
              ),
            ],
          ),

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
                        builder: (_) => const RentalTrackingRequesterScreen(),
                        settings: RouteSettings(arguments: activeRental),
                      ),
                    );
                  }
                },
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEA580C), Color(0xFFF97316)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.orange500.withOpacity(0.3),
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
                        child: const Icon(Icons.timer_outlined,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activeRentals.length > 1
                                  ? 'Tienes ${activeRentals.length} rentas en proceso'
                                  : 'Tienes una renta activa',
                              style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              activeRentals.length > 1
                                  ? 'Toca para ver la sección de tus rentas'
                                  : (activeRental!.isPending
                                      ? 'Pendiente de entrega — Toca para ver'
                                      : 'En curso — Toca para ver el seguimiento'),
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

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
              child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CatalogMapScreen())),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: AppColors.primaryButtonShadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.map_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Explorar Mapa Interactivo',
                              style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Encuentra herramientas cerca de tu ubicación actual',
                              style: GoogleFonts.inter(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: context.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppColors.cardShadow,
                ),
                child: TextField(
                  onChanged: (v) =>
                      context.read<CatalogProvider>().setSearch(v),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: context.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Buscar herramientas…',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: context.textSecondary.withValues(alpha: 0.6),
                    ),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: context.textSecondary, size: 20),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 13),
                    isDense: true,
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                scrollDirection: Axis.horizontal,
                itemCount: provider.categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat = provider.categories[i];
                  final isSelected = provider.filterCategory == cat;
                  return FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (_) =>
                        context.read<CatalogProvider>().setCategory(cat),
                    showCheckmark: false,
                    selectedColor: AppColors.orange500.withOpacity(0.12),
                    labelStyle: GoogleFonts.inter(
                      color: isSelected
                          ? AppColors.orange600
                          : context.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.orange500
                          : context.borderColor,
                    ),
                  );
                },
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              child: Text(
                provider.loading
                    ? 'Cargando…'
                    : '${tools.length} resultado${tools.length != 1 ? 's' : ''}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: context.textSecondary,
                ),
              ),
            ),
          ),

          if (provider.loading)
            const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()))
          else if (provider.error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi_off_rounded, size: 48,
                        color: context.colors.outline),
                    const SizedBox(height: 12),
                    Text(provider.error!,
                        style: GoogleFonts.inter(color: context.textSecondary)),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () =>
                          context.read<CatalogProvider>().fetchTools(),
                      style: FilledButton.styleFrom(
                          minimumSize: const Size(140, 44)),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          else if (tools.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_off_rounded, size: 56,
                        color: context.colors.outline),
                    const SizedBox(height: 12),
                    Text('Sin resultados',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: context.textSecondary,
                        )),
                  ],
                ),
              ),
            )
          else
            SliverSafeArea(
              top: false,
              sliver: SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => ToolCard(
                      tool: tools[i],
                      onTap: () => _showDetail(context, tools[i]),
                    ),
                    childCount: tools.length,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}