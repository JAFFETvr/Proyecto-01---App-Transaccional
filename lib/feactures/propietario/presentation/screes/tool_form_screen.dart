import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
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
  final _formKey     = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _brandCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _catCtrl;

  bool _isAvailable = true;
  String _wearLevel = 'Nuevo';
  File? _pickedImage;
  double? _latitude;
  double? _longitude;
  bool _locationLoading = false;
  bool _imageLoading = false;

  final double _suggestedPrice = 350.0;
  late double _finalPrice;

  bool get _isEditing => widget.tool != null;

  static const _categories = [
    'Eléctrico', 'Corte', 'Acabado', 'Energía',
    'Neumático', 'Manual', 'Medición', 'Otro',
  ];

  static const _wearOptions = ['Nuevo', 'Buen Estado', 'Desgastado'];

  @override
  void initState() {
    super.initState();
    final t = widget.tool;
    _nameCtrl  = TextEditingController(text: t?.name ?? '');
    _brandCtrl = TextEditingController();
    _modelCtrl = TextEditingController();
    _descCtrl  = TextEditingController(text: t?.description ?? '');
    _catCtrl   = TextEditingController(text: t?.category ?? '');
    _isAvailable = t?.isAvailable ?? true;
    _finalPrice  = _suggestedPrice;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _descCtrl.dispose();
    _catCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() => _imageLoading = true);
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1080,
      );
      if (xFile != null) {
        setState(() => _pickedImage = File(xFile.path));
      }
    } finally {
      setState(() => _imageLoading = false);
    }
  }

  Future<void> _captureLocation() async {
    setState(() => _locationLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Activa el GPS del dispositivo')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permiso de ubicación denegado. Actívalo en Ajustes.')),
          );
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      setState(() {
        _latitude  = pos.latitude;
        _longitude = pos.longitude;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo obtener la ubicación')),
        );
      }
    } finally {
      setState(() => _locationLoading = false);
    }
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
        content: Text(_isEditing
            ? 'Herramienta actualizada ✓'
            : 'Herramienta creada ✓'),
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
    final tt = Theme.of(context).textTheme;

    final provider = context.watch<ToolProvider>();
    final minPrice = _suggestedPrice * 0.5;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Herramienta' : 'Nueva Herramienta'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [

              _SectionTitle('Foto de la herramienta'),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _imageLoading ? null : _pickImage,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _pickedImage != null ? cs.primary : cs.outlineVariant,
                      width: _pickedImage != null ? 2 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _imageLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _pickedImage != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(_pickedImage!, fit: BoxFit.cover),
                                Positioned(
                                  bottom: 8, right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: cs.surface.withValues(alpha: 0.85),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                                      Icon(Icons.camera_alt_outlined,
                                          size: 14, color: cs.primary),
                                      const SizedBox(width: 4),
                                      Text('Cambiar',
                                          style: tt.labelSmall?.copyWith(color: cs.primary)),
                                    ]),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt_outlined,
                                    size: 40, color: cs.onSurfaceVariant),
                                const SizedBox(height: 8),
                                Text('Toca para tomar una foto',
                                    style: tt.bodySmall
                                        ?.copyWith(color: cs.onSurfaceVariant)),
                              ],
                            ),
                ),
              ),
              const SizedBox(height: 24),

              _SectionTitle('Información básica'),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  hintText: 'Ej. Taladro Percutor',
                  prefixIcon: Icon(Icons.construction_outlined),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 14),

              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _brandCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Marca',
                      hintText: 'DeWalt',
                      prefixIcon: Icon(Icons.business_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _modelCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Modelo',
                      hintText: 'DCD777',
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 14),

              TextFormField(
                controller: _catCtrl,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Categoría',
                  hintText: 'Eléctrico, Manual, Corte…',
                  prefixIcon: const Icon(Icons.category_outlined),
                  suffixIcon: PopupMenuButton<String>(
                    icon: const Icon(Icons.arrow_drop_down),
                    onSelected: (v) => _catCtrl.text = v,
                    itemBuilder: (_) => _categories
                        .map((c) => PopupMenuItem(value: c, child: Text(c)))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                maxLength: 300,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Estado, características, accesorios incluidos…',
                ),
              ),
              const SizedBox(height: 24),

              _SectionTitle('Condición física'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outline),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _wearLevel,
                    isExpanded: true,
                    icon: const Icon(Icons.expand_more),
                    items: _wearOptions.map((w) {
                      final color = w == 'Nuevo'
                          ? const Color(0xFF16A34A)
                          : w == 'Buen Estado'
                              ? const Color(0xFF2563EB)
                              : const Color(0xFFDC2626);
                      return DropdownMenuItem(
                        value: w,
                        child: Row(children: [
                          Container(
                            width: 10, height: 10,
                            decoration: BoxDecoration(
                                color: color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 10),
                          Text(w),
                        ]),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _wearLevel = v!),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              _SectionTitle('Ubicación de la herramienta'),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _locationLoading ? null : _captureLocation,
                icon: _locationLoading
                    ? SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: cs.primary))
                    : Icon(
                        _latitude != null
                            ? Icons.location_on
                            : Icons.my_location_rounded),
                label: Text(_latitude != null
                    ? 'Ubicación capturada ✓'
                    : 'Capturar mi ubicación GPS'),
              ),
              if (_latitude != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.location_on,
                        size: 16, color: Color(0xFF16A34A)),
                    const SizedBox(width: 8),
                    Text(
                      'Lat: ${_latitude!.toStringAsFixed(6)} | '
                      'Lng: ${_longitude!.toStringAsFixed(6)}',
                      style: tt.bodySmall?.copyWith(
                          color: const Color(0xFF16A34A),
                          fontWeight: FontWeight.w600),
                    ),
                  ]),
                ),
              ],
              const SizedBox(height: 24),

              _SectionTitle('Precio de renta'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Precio sugerido por IA:',
                            style: tt.bodyMedium),
                        Text('\$${_suggestedPrice.toStringAsFixed(0)} MXN/día',
                            style: tt.titleMedium?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Basado en el modelo de regresión del backend',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    const Divider(height: 20),
                    Text('Tu precio final: \$${_finalPrice.toStringAsFixed(0)} MXN/día',
                        style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      'Mínimo permitido: \$${minPrice.toStringAsFixed(0)} MXN/día (50%)',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                    Slider(
                      value: _finalPrice,
                      min: minPrice,
                      max: _suggestedPrice * 2,
                      divisions: 30,
                      label: '\$${_finalPrice.toStringAsFixed(0)}',
                      onChanged: (v) => setState(() => _finalPrice = v),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('\$${minPrice.toStringAsFixed(0)} (mín)',
                            style: tt.labelSmall
                                ?.copyWith(color: cs.onSurfaceVariant)),
                        Text('\$${(_suggestedPrice * 2).toStringAsFixed(0)} (máx)',
                            style: tt.labelSmall
                                ?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Card(
                child: SwitchListTile(
                  value: _isAvailable,
                  onChanged: (v) => setState(() => _isAvailable = v),
                  title: const Text('Disponible para renta'),
                  subtitle: Text(
                    _isAvailable ? 'Visible en el catálogo' : 'Oculta del catálogo',
                    style: TextStyle(
                      fontSize: 12,
                      color: _isAvailable ? const Color(0xFF16A34A) : cs.error,
                    ),
                  ),
                  secondary: Icon(
                    _isAvailable
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: _isAvailable ? const Color(0xFF16A34A) : cs.error,
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
                label: Text(_isEditing ? 'Guardar Cambios' : 'Publicar Herramienta'),
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

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Row(children: [
      Container(width: 3, height: 18,
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: BorderRadius.circular(2),
          )),
      const SizedBox(width: 8),
      Text(text, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
    ]);
  }
}