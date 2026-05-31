import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../viewModels/tool_viewmodel.dart';
import '../components/tool_list_item.dart';
import 'tool_form_screen.dart';
import '../../../auth/login/presentation/screes/login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _vm = ToolViewModel();
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _vm.fetchTools();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _userName = prefs.getString('user_name') ?? '');
    }
  }

  Future<void> _confirmDelete(String id, String name) async {
    final cs = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar herramienta'),
        content: Text('¿Eliminar "$name"? No se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: cs.error, minimumSize: const Size(80, 40)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final ok = await _vm.deleteTool(id);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_vm.error ?? 'Error al eliminar')));
    }
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(
                  builder: (_) => ToolFormScreen(viewModel: _vm)));
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva Herramienta'),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _vm,
          builder: (context, _) => CustomScrollView(
            slivers: [
              // SliverAppBar
              SliverAppBar(
                pinned: true,
                expandedHeight: 140,
                backgroundColor: cs.surface,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout_rounded),
                    onPressed: _logout,
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 14),
                  title: Text('Mi Panel',
                      style: tt.titleLarge?.copyWith(color: cs.onSurface)),
                  background: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 52, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hola, $_userName 👋',
                            style: tt.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant)),
                        const SizedBox(height: 4),
                        Text('Gestiona tu inventario',
                            style: tt.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),

              // Métricas
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Row(children: [
                    _MetricCard(label: 'Total',
                        value: '${_vm.totalTools}',
                        icon: Icons.handyman_outlined,
                        color: cs.primary),
                    const SizedBox(width: 12),
                    _MetricCard(label: 'Disponibles',
                        value: '${_vm.availableCount}',
                        icon: Icons.check_circle_outline,
                        color: const Color(0xFF16A34A)),
                    const SizedBox(width: 12),
                    _MetricCard(label: 'En Renta',
                        value: '${_vm.rentedCount}',
                        icon: Icons.timer_outlined,
                        color: cs.tertiary),
                  ]),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text('Mis Herramientas',
                      style: tt.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
              ),

              // Estados
              if (_vm.loading)
                const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()))
              else if (_vm.error != null)
                SliverFillRemaining(
                  child: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.wifi_off_rounded, size: 48,
                          color: cs.onSurfaceVariant),
                      const SizedBox(height: 12),
                      Text(_vm.error!, style: tt.bodyMedium),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _vm.fetchTools,
                        style: FilledButton.styleFrom(
                            minimumSize: const Size(140, 44)),
                        child: const Text('Reintentar'),
                      ),
                    ]),
                  ),
                )
              else if (_vm.tools.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.inbox_rounded, size: 56,
                          color: cs.onSurfaceVariant),
                      const SizedBox(height: 12),
                      Text('Sin herramientas', style: tt.titleMedium),
                    ]),
                  ),
                )
              else
                // SliverList con ListTile
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => ToolListItem(
                        tool: _vm.tools[i],
                        onEdit: () => Navigator.push(ctx,
                            MaterialPageRoute(
                                builder: (_) => ToolFormScreen(
                                    viewModel: _vm,
                                    tool: _vm.tools[i]))),
                        onDelete: () => _confirmDelete(
                            _vm.tools[i].id, _vm.tools[i].name),
                      ),
                      childCount: _vm.tools.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() { _vm.dispose(); super.dispose(); }
}

class _MetricCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _MetricCard({required this.label, required this.value,
      required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value, style: tt.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800, color: color)),
            Text(label, style: tt.labelSmall?.copyWith(
                color: cs.onSurfaceVariant), textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }
}