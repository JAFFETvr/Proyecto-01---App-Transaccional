import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/catalog_provider.dart';
import '../components/tool_card.dart';
import '../../domain/entitie/tool_entity.dart';
import '../../../auth/login/presentation/screes/login_screen.dart';
import 'tool_detail_screen.dart';
import '../../../../../shared/theme/app_colors.dart';

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
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _showDetail(BuildContext context, ToolEntity tool) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ToolDetailScreen(tool: tool, pricePerDay: 350.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CatalogProvider>();
    final tools = provider.filtered;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── AppBar premium ────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            floating: true,
            expandedHeight: 0,
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            // Borde inferior sutil
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(0),
              child: Container(
                height: 1,
                color: const Color(0xFFE2E8F0),
              ),
            ),
            title: Row(
              children: [
                // Logo/Icono ToolShare
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
                        color: AppColors.slate900,
                      ),
                    ),
                    Text(
                      '${provider.totalCount} herramientas',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.slate600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              // Filtro disponibles
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
                  selectedColor: AppColors.successBg,
                  labelStyle: GoogleFonts.inter(
                    color: provider.onlyAvailable
                        ? AppColors.success
                        : AppColors.slate600,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  side: BorderSide(
                    color: provider.onlyAvailable
                        ? AppColors.success
                        : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              // Logout
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                color: AppColors.slate600,
                onPressed: _logout,
              ),
            ],
          ),

          // ── Barra de búsqueda ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppColors.cardShadow,
                ),
                child: TextField(
                  onChanged: (v) =>
                      context.read<CatalogProvider>().setSearch(v),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.slate900,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Buscar herramientas…',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.slate600.withOpacity(0.5),
                    ),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: AppColors.slate600, size: 20),
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

          // ── Chips de categoría ────────────────────────────────────────────
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
                          : AppColors.slate600,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.orange500
                          : const Color(0xFFE2E8F0),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Contador de resultados ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              child: Text(
                provider.loading
                    ? 'Cargando…'
                    : '${tools.length} resultado${tools.length != 1 ? 's' : ''}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.slate600,
                ),
              ),
            ),
          ),

          // ── Contenido ─────────────────────────────────────────────────────
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
                        color: AppColors.slate300),
                    const SizedBox(height: 12),
                    Text(provider.error!,
                        style: GoogleFonts.inter(color: AppColors.slate600)),
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
                        color: AppColors.slate300),
                    const SizedBox(height: 12),
                    Text('Sin resultados',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate600,
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