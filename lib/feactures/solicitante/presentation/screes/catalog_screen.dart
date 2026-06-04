import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/catalog_provider.dart';

import '../components/tool_card.dart';
import '../../domain/entitie/tool_entity.dart';

import '../../../auth/login/presentation/screes/login_screen.dart';

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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, sc) => ListView(
          controller: sc,
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Icon(Icons.handyman_outlined, size: 56, color: cs.primary),
            const SizedBox(height: 16),
            Text(tool.name,
                style: tt.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
                textAlign: TextAlign.center),
            if (tool.category.isNotEmpty)
              Text(tool.category,
                  style: tt.bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center),
            const SizedBox(height: 16),
            if (tool.description.isNotEmpty)
              Text(tool.description, style: tt.bodyMedium),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: tool.isAvailable ? () => Navigator.pop(ctx) : null,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(tool.isAvailable
                  ? 'Solicitar Renta' : 'No Disponible'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final provider = context.watch<CatalogProvider>();
    final tools = provider.filtered;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              floating: true,
              expandedHeight: 130,
              backgroundColor: cs.surface,
              actions: [
                FilterChip(
                  label: const Text('Disponibles'),
                  selected: provider.onlyAvailable,
                  onSelected: (v) =>
                      context.read<CatalogProvider>().setOnlyAvailable(v),
                  showCheckmark: false,
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.logout_rounded),
                  onPressed: _logout,
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                titlePadding:
                    const EdgeInsets.fromLTRB(16, 0, 16, 12),
                title: SearchBar(
                  hintText: 'Buscar herramientas…',
                  leading: Icon(Icons.search,
                      color: cs.onSurfaceVariant),
                  onChanged: (v) =>
                      context.read<CatalogProvider>().setSearch(v),
                  elevation: const WidgetStatePropertyAll(0),
                  backgroundColor: WidgetStatePropertyAll(
                      cs.surfaceContainerHighest.withOpacity(0.7)),
                  shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  padding: const WidgetStatePropertyAll(
                      EdgeInsets.symmetric(horizontal: 12)),
                  constraints:
                      const BoxConstraints(maxHeight: 44),
                ),
                background: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 52, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Catálogo',
                          style: tt.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800)),
                      Text('${provider.totalCount} herramientas',
                          style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: SizedBox(
                height: 50,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  scrollDirection: Axis.horizontal,
                  itemCount: provider.categories.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final cat = provider.categories[i];
                    return FilterChip(
                      label: Text(cat),
                      selected: provider.filterCategory == cat,
                      onSelected: (_) =>
                          context.read<CatalogProvider>().setCategory(cat),
                      showCheckmark: false,
                    );
                  },
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  provider.loading
                      ? 'Cargando…'
                      : '${tools.length} resultado${tools.length != 1 ? 's' : ''}',
                  style: tt.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
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
                          color: cs.onSurfaceVariant),
                      const SizedBox(height: 12),
                      Text(provider.error!, style: tt.bodyMedium),
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
                          color: cs.outlineVariant),
                      const SizedBox(height: 12),
                      Text('Sin resultados', style: tt.titleMedium),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
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
          ],
        ),
      ),
    );
  }
}