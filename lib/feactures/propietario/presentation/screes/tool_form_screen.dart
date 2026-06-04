import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/tool_provider.dart';

import '../../domain/entitie/tool_entity.dart';

class ToolFormScreen extends StatefulWidget {
  final ToolEntity? tool;

  const ToolFormScreen({super.key, this.tool});

  @override
  State<ToolFormScreen> createState() => _ToolFormScreenState();
}

class _ToolFormScreenState extends State<ToolFormScreen> {
  final _formKey    = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _catCtrl;
  bool _isAvailable = true;

  bool get _isEditing => widget.tool != null;

  static const _categories = [
    'Eléctrico', 'Corte', 'Acabado', 'Energía',
    'Neumático', 'Manual', 'Medición', 'Otro',
  ];

  @override
  void initState() {
    super.initState();
    final t = widget.tool;
    _nameCtrl    = TextEditingController(text: t?.name ?? '');
    _descCtrl    = TextEditingController(text: t?.description ?? '');
    _catCtrl     = TextEditingController(text: t?.category ?? '');
    _isAvailable = t?.isAvailable ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _descCtrl.dispose(); _catCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<ToolProvider>();

    bool ok;
    if (_isEditing) {
      ok = await provider.updateTool(
        id:          widget.tool!.id,
        name:        _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category:    _catCtrl.text.trim(),
        isAvailable: _isAvailable,
      );
    } else {
      ok = await provider.createTool(
        name:        _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category:    _catCtrl.text.trim(),
        isAvailable: _isAvailable,
      );
    }

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            _isEditing ? 'Herramienta actualizada ✓' : 'Herramienta creada ✓'),
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(provider.error ?? 'Error al guardar'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final provider = context.watch<ToolProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Herramienta' : 'Nueva Herramienta'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 16),
            children: [
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: Icon(Icons.handyman_outlined,
                          size: 44, color: cs.onSurfaceVariant),
                    ),
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: cs.primary, shape: BoxShape.circle,
                        border: Border.all(color: cs.surface, width: 2),
                      ),
                      child: Icon(Icons.camera_alt_outlined,
                          size: 15, color: cs.onPrimary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text('Nombre *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'Ej. Taladro Percutor 20V',
                  prefixIcon: Icon(Icons.construction_outlined),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),

              const Text('Categoría'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _catCtrl,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: 'Eléctrico, Manual, Corte…',
                  prefixIcon: const Icon(Icons.category_outlined),
                  suffixIcon: PopupMenuButton<String>(
                    icon: const Icon(Icons.arrow_drop_down),
                    onSelected: (v) => _catCtrl.text = v,
                    itemBuilder: (_) => _categories
                        .map((c) =>
                            PopupMenuItem(value: c, child: Text(c)))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Text('Descripción'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                maxLength: 300,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Estado, características…',
                ),
              ),
              const SizedBox(height: 8),

              Card(
                child: SwitchListTile(
                  value: _isAvailable,
                  onChanged: (v) => setState(() => _isAvailable = v),
                  title: const Text('Disponible para renta'),
                  subtitle: Text(
                    _isAvailable ? 'Visible en el catálogo'
                        : 'Oculta del catálogo',
                    style: TextStyle(
                      fontSize: 12,
                      color: _isAvailable
                          ? const Color(0xFF16A34A) : cs.error,
                    ),
                  ),
                  secondary: Icon(
                    _isAvailable ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: _isAvailable
                        ? const Color(0xFF16A34A) : cs.error,
                  ),
                  activeColor: const Color(0xFF16A34A),
                ),
              ),
              const SizedBox(height: 28),

              FilledButton.icon(
                onPressed: provider.loading ? null : _save,
                icon: provider.loading
                    ? SizedBox(
                        height: 18, width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: cs.onPrimary))
                    : const Icon(Icons.save_outlined),
                label: Text(_isEditing
                    ? 'Guardar Cambios' : 'Crear Herramienta'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}