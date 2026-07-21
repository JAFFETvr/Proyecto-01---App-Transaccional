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
import '../../../checkout/presentation/screes/my_rentals_screen.dart';
import 'catalog_map_screen.dart';
import '../../../../../shared/widgets/account_tab.dart';
import '../../../../../shared/widgets/app_bottom_nav_bar.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  int _selectedIndex = 0;

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
    final activeRentalCount = context
        .watch<RentalProvider>()
        .rentals
        .where((r) => !r.isCompleted && !r.isCancelled && !r.isDisputed)
        .length;

    return Scaffold(
      backgroundColor: context.bg,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeTab(context),
          const CatalogMapScreen(embedded: true),
          const MyRentalsScreen(),
          AccountTab(onLogout: _logout),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: (i) {
          setState(() => _selectedIndex = i);
          if (i == 0) context.read<CatalogProvider>().fetchTools();
        },
        items: [
          const AppBottomNavItem(
            icon: Icons.home_rounded,
            label: 'Disponibles',
          ),
          const AppBottomNavItem(
            icon: Icons.location_on_rounded,
            label: 'Mapa',
          ),
          AppBottomNavItem(
            icon: Icons.access_time_rounded,
            label: 'Rentas',
            badgeCount: activeRentalCount,
          ),
          const AppBottomNavItem(icon: Icons.person_rounded, label: 'Cuenta'),
        ],
      ),
    );
  }

  Widget _buildHomeTab(BuildContext context) {
    final provider = context.watch<CatalogProvider>();
    final tools = provider.filtered;

    return RefreshIndicator(
      onRefresh: () => provider.fetchTools(),
      color: AppColors.orange500,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: true,
            backgroundColor: context.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: false,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(0),
              child: Container(height: 1, color: context.borderColor),
            ),
            title: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.construction_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
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
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
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

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: context.textSecondary,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 13,
                    ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
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
              child: Center(child: CircularProgressIndicator()),
            )
          else if (provider.error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.wifi_off_rounded,
                      size: 48,
                      color: context.colors.outline,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      provider.error!,
                      style: GoogleFonts.inter(color: context.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () =>
                          context.read<CatalogProvider>().fetchTools(),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(140, 44),
                      ),
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
                    Icon(
                      Icons.search_off_rounded,
                      size: 56,
                      color: context.colors.outline,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Sin resultados',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.textSecondary,
                      ),
                    ),
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
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
