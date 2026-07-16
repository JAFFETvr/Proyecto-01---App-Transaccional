import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';

import '../../../../shared/components/location_picker_modal.dart';
import '../../../../shared/theme/app_colors.dart';
import '../providers/tool_provider.dart';
import '../../domain/entitie/tool_entity.dart';
import '../components/tool_list_item.dart' show kInsuranceMonthlyRate;
import 'pro_subscription_checkout_screen.dart';

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
  late final TextEditingController _ageCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _catCtrl;
  late final TextEditingController _estValCtrl;

  bool _isAvailable = true;
  String _wearLevel = 'Nuevo';
  File? _pickedImage;
  double? _latitude;
  double? _longitude;
  bool _imageLoading = false;

  double _suggestedPrice = 100.0;
  double _minPrice = 50.0;
  late double _finalPrice;
  bool _fetchingPricing = false;
  String _pricingDesc = '';
  Timer? _debounceTimer;

  bool get _isEditing => widget.tool != null;

  static const _categories = [
    'Manual', 'Eléctrico', 'Neumático', 'Medición', 'Energía', 'Otro',
  ];

  static const _wearOptions = ['Nuevo', 'Buen Estado', 'Desgastado'];

  @override
  void initState() { //
    super.initState();
    final t = widget.tool;
    _nameCtrl  = TextEditingController(text: t?.name ?? '');
    _brandCtrl = TextEditingController(text: t?.brand ?? '');
    _modelCtrl = TextEditingController();
    _ageCtrl   = TextEditingController(text: t != null ? t.ageMonths.toString() : '12');
    _descCtrl  = TextEditingController(text: t?.description ?? '');
    _catCtrl   = TextEditingController(text: t?.category ?? '');
    _estValCtrl = TextEditingController(
        text: (t != null && t.estimatedValue > 0) ? t.estimatedValue.toStringAsFixed(0) : '');
    _isAvailable = t?.isAvailable ?? true;

    if (t != null) {
      _suggestedPrice = t.dailyRate;
      _minPrice = t.suggestedMinDailyRate;
      _finalPrice = t.dailyRate;
      if (t.latitude != 0.0) {
        _latitude = t.latitude;
        _longitude = t.longitude;
      }
    } else {
      _finalPrice = _suggestedPrice;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _ageCtrl.dispose();
    _descCtrl.dispose();
    _catCtrl.dispose();
    _estValCtrl.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onFieldChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _updatePricingSuggestion();
      }
    });
  }

  Future<void> _updatePricingSuggestion() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _fetchingPricing = true);

    double score = 0.7;
    if (_wearLevel == 'Nuevo') {
      score = 1.0;
    } else if (_wearLevel == 'Buen Estado') {
      score = 0.8;
    } else if (_wearLevel == 'Desgastado') {
      score = 0.5;
    }

    try {
      final res = await context.read<ToolProvider>().autoValuate(
        name: name,
        scoreCondicion: score,
        category: _catCtrl.text.trim(),
        brand: _brandCtrl.text.trim().isEmpty ? 'Generico' : _brandCtrl.text.trim(),
        ageMonths: int.tryParse(_ageCtrl.text.trim()) ?? 12,
      );
      if (res != null && mounted) {
        setState(() {
          final estVal = (res['estimated_value'] as num?)?.toDouble() ?? 0.0;
          _estValCtrl.text = estVal > 0 ? estVal.toStringAsFixed(0) : '';
          _suggestedPrice = (res['suggested_daily_rate'] as num?)?.toDouble() ?? 100.0;
          _minPrice = (res['minimum_daily_rate'] as num?)?.toDouble() ?? 50.0;
          _pricingDesc = res['description'] as String? ?? '';
          
          if (_finalPrice < _minPrice) {
            _finalPrice = _minPrice;
          } else {
            final maxRateVal = _suggestedPrice * 2 > _minPrice ? _suggestedPrice * 2 : _minPrice + 10;
            if (_finalPrice > maxRateVal) {
              _finalPrice = maxRateVal;
            }
          }
        });
      }
    } catch (_) {
      // Keep existing values on transient errors
    } finally {
      if (mounted) {
        setState(() => _fetchingPricing = false);
      }
    }
  }

  Future<ImageSource?> _chooseImageSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final source = await _chooseImageSource();
    if (source == null) return;

    setState(() => _imageLoading = true);
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1080,
      );
      if (xFile != null) {
        final file = File(xFile.path);
        setState(() {
          _pickedImage = file;
        });

        if (mounted) {
          final provider = context.read<ToolProvider>();
          final pred = await provider.predictCondition(file);
          if (pred != null && mounted) {
            final clase = pred['clase_predicha'] as String?;
            String mappedLevel = _wearLevel;
            if (clase == 'nuevo') {
              mappedLevel = 'Nuevo';
            } else if (clase == 'uso_moderado') {
              mappedLevel = 'Buen Estado';
            } else if (clase == 'viejo_desgastado') {
              mappedLevel = 'Desgastado';
            }
            setState(() {
              _wearLevel = mappedLevel;
            });
            await _updatePricingSuggestion();
          } else if (mounted) {
            // Rechazado por la IA: limpiamos la foto y mostramos alerta
            setState(() {
              _pickedImage = null;
            });
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(provider.error ?? 'La imagen no corresponde a una herramienta de construcción válida.'),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
            ));
          }
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No se pudo acceder a la cámara/galería. Prueba en un dispositivo o emulador Android/iOS real.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _imageLoading = false);
      }
    }
  }



  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_latitude == null || _longitude == null || _latitude == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona la ubicación real de la herramienta en el mapa antes de publicar.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final provider = context.read<ToolProvider>();
    final estVal = double.tryParse(_estValCtrl.text.trim()) ?? 0.0;
    ToolEntity? saved;

    if (_isEditing) {
      saved = await provider.updateTool(
        id:          widget.tool!.id,
        name:        _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category:    _catCtrl.text.trim(),
        isAvailable: _isAvailable,
        estimatedValue: estVal,
        dailyRate: _finalPrice,
        latitude: _latitude,
        longitude: _longitude,
      );
    } else {
      double score = 0.7;
      if (_wearLevel == 'Nuevo') {
        score = 1.0;
      } else if (_wearLevel == 'Buen Estado') {
        score = 0.8;
      } else if (_wearLevel == 'Desgastado') {
        score = 0.5;
      }
      saved = await provider.createTool(
        name:        _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category:    _catCtrl.text.trim(),
        isAvailable: _isAvailable,
        estimatedValue: estVal,
        dailyRate: _finalPrice,
        latitude: _latitude,
        longitude: _longitude,
        brand: _brandCtrl.text.trim().isEmpty ? 'Generico' : _brandCtrl.text.trim(),
        ageMonths: int.tryParse(_ageCtrl.text.trim()) ?? 12,
        conditionScore: score,
      );
    }

    if (!mounted) return;
    final ok = saved != null;
    if (ok && _pickedImage != null) {
      final photoOk = await provider.uploadPhoto(saved.id, _pickedImage!);
      if (!photoOk && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Herramienta guardada, pero la foto no se pudo subir: ${provider.error ?? "intenta de nuevo desde Editar"}'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ));
      }
    }
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isEditing
            ? 'Herramienta actualizada ✓'
            : 'Herramienta creada ✓'),
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.pop(context);
    } else {
      final errorMsg = provider.error ?? 'Error al guardar';
      // Detectar si el error es por límite del plan gratuito
      final bool isPlanError = errorMsg.toLowerCase().contains('plan') ||
          errorMsg.toLowerCase().contains('limit') ||
          errorMsg.toLowerCase().contains('máximo') ||
          errorMsg.toLowerCase().contains('maximo') ||
          errorMsg.toLowerCase().contains('suscripci') ||
          errorMsg.toLowerCase().contains('pro') ||
          errorMsg.toLowerCase().contains('herramienta') ||
          errorMsg.toLowerCase().contains('valor') ||
          errorMsg.toLowerCase().contains('1500') ||
          errorMsg.toLowerCase().contains('3 ');
      if (isPlanError && !_isEditing) {
        await showDialog(
          context: context,
          builder: (ctx) {
            final dialogCs = Theme.of(ctx).colorScheme;
            return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            icon: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: dialogCs.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.workspace_premium_rounded,
                  size: 32, color: dialogCs.primary),
            ),
            title: const Text(
              'Límite del Plan Gratuito',
              textAlign: TextAlign.center,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: dialogCs.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: dialogCs.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    errorMsg,
                    style: TextStyle(
                      fontSize: 13,
                      color: dialogCs.onPrimaryContainer,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'El Plan Pro te permite publicar herramientas ilimitadas y de cualquier valor catálogo.',
                  style: TextStyle(fontSize: 13, color: dialogCs.onSurfaceVariant, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: dialogCs.primary,
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await openProSubscriptionCheckout(context);
                },
                icon: const Icon(Icons.bolt_rounded, size: 16),
                label: const Text('Obtener Plan Pro'),
              ),
            ],
          );
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errorMsg),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final provider = context.watch<ToolProvider>();
    final maxRateVal = _suggestedPrice * 2 > _minPrice ? _suggestedPrice * 2 : _minPrice + 10;

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
                onChanged: (_) => _onFieldChanged(),
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
                    onChanged: (_) => _onFieldChanged(),
                    onEditingComplete: () {
                      FocusScope.of(context).nextFocus();
                    },
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
                    onChanged: (_) => _onFieldChanged(),
                  ),
                ),
              ]),
              const SizedBox(height: 14),

              TextFormField(
                controller: _ageCtrl,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Antigüedad (Meses) *',
                  hintText: 'Ej. 12',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Campo requerido' : null,
                onChanged: (_) => _onFieldChanged(),
              ),
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
                    onSelected: (v) {
                      _catCtrl.text = v;
                      _updatePricingSuggestion();
                    },
                    itemBuilder: (_) => _categories
                        .map((c) => PopupMenuItem(value: c, child: Text(c)))
                        .toList(),
                  ),
                ),
                onChanged: (_) => _onFieldChanged(),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _estValCtrl,
                readOnly: _isEditing,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Valor original de catálogo (MXN) *',
                  hintText: 'Ej. 2500',
                  prefixIcon: const Icon(Icons.attach_money_outlined),
                  suffixIcon: _isEditing
                      ? Icon(Icons.lock_outline, size: 18, color: cs.onSurfaceVariant)
                      : null,
                  helperText: _isEditing
                      ? 'No editable después de publicar la herramienta'
                      : null,
                ),
                onChanged: (_) => _onFieldChanged(),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Campo requerido';
                  final val = double.tryParse(v);
                  if (val == null || val <= 0) return 'Ingrese un valor válido';
                  return null;
                },
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
                  color: _isEditing ? cs.surfaceContainerHighest.withValues(alpha: 0.3) : null,
                  border: Border.all(color: cs.outline),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _wearLevel,
                    isExpanded: true,
                    icon: Icon(_isEditing ? Icons.lock_outline : Icons.expand_more,
                        size: _isEditing ? 18 : 24),
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
                    onChanged: _isEditing
                        ? null
                        : (v) {
                            setState(() => _wearLevel = v!);
                            _updatePricingSuggestion();
                          },
                  ),
                ),
              ),
              if (_isEditing) ...[
                const SizedBox(height: 6),
                Text(
                  'La condición se define solo al publicar la herramienta.',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
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
                        Expanded(
                          child: Text('Precio sugerido por IA:',
                              style: tt.bodyMedium),
                        ),
                        _fetchingPricing
                            ? const SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text('\$${_suggestedPrice.toStringAsFixed(0)} MXN/día',
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
                    if (_pricingDesc.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        _pricingDesc,
                        style: tt.bodySmall?.copyWith(color: cs.primary, fontStyle: FontStyle.italic),
                      ),
                    ],
                    const Divider(height: 20),
                    Text('Tu precio final: \$${_finalPrice.toStringAsFixed(0)} MXN/día',
                        style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      'Mínimo permitido: \$${_minPrice.toStringAsFixed(0)} MXN/día (50%)',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                    Slider(
                      value: _finalPrice.clamp(_minPrice, maxRateVal),
                      min: _minPrice,
                      max: maxRateVal,
                      divisions: 30,
                      label: '\$${_finalPrice.toStringAsFixed(0)}',
                      onChanged: _fetchingPricing
                          ? null
                          : (v) => setState(() => _finalPrice = v),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('\$${_minPrice.toStringAsFixed(0)} (mín)',
                            style: tt.labelSmall
                                ?.copyWith(color: cs.onSurfaceVariant)),
                        Text('\$${maxRateVal.toStringAsFixed(0)} (máx)',
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
              const SizedBox(height: 20),

              if (_isEditing) ...[
                _SectionTitle('Respaldo ToolShare'),
                const SizedBox(height: 12),
                _ToolShareBackupCard(
                  estimatedValue: widget.tool!.estimatedValue,
                  isAvailable: widget.tool!.isAvailable,
                ),
                const SizedBox(height: 20),
              ],

              _SectionTitle('Geolocalización (Mapa Cercano)'),
              const SizedBox(height: 12),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: const Icon(Icons.map_rounded, color: Color(0xFFEA580C), size: 32),
                  title: Text(
                    (_latitude != null && _longitude != null && _latitude != 0.0)
                        ? 'Ubicación seleccionada'
                        : 'Ubicación no establecida',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    (_latitude != null && _longitude != null && _latitude != 0.0)
                        ? 'Coordenadas: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}'
                        : 'No seleccionada — obligatoria para publicar',
                    style: TextStyle(fontSize: 12, color: (_latitude != null && _latitude != 0.0) ? const Color(0xFF16A34A) : cs.onSurfaceVariant),
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA580C), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: const Text('Abrir Mapa'),
                    onPressed: () async {
                      final LatLng? res = await showDialog<LatLng>(
                        context: context,
                        builder: (_) => LocationPickerModal(initialLat: _latitude, initialLng: _longitude),
                      );
                      if (res != null) {
                        setState(() {
                          _latitude = res.latitude;
                          _longitude = res.longitude;
                        });
                      }
                    },
                  ),
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

/// "Respaldo ToolShare": presenta el seguro por herramienta (independiente
/// del plan de suscripción Pro/Gratuito) — la prima mensual se calcula como
/// un % del valor tasado por IA. Por ahora es informativo: el switch expresa
/// la intención de contratar, sin disparar un cobro real todavía.
class _ToolShareBackupCard extends StatefulWidget {
  final double estimatedValue;
  final bool isAvailable;

  const _ToolShareBackupCard({
    required this.estimatedValue,
    required this.isAvailable,
  });

  @override
  State<_ToolShareBackupCard> createState() => _ToolShareBackupCardState();
}

class _ToolShareBackupCardState extends State<_ToolShareBackupCard> {
  bool _insuranceWanted = false;

  double get _monthlyPremium => widget.estimatedValue * kInsuranceMonthlyRate;

  void _showTerms(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.shield_outlined, color: cs.primary, size: 22),
                  const SizedBox(width: 8),
                  Text('Qué cubre el Respaldo ToolShare',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: cs.onSurface)),
                ]),
                const SizedBox(height: 16),
                Text('Sí cubre:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.success)),
                const SizedBox(height: 6),
                _TermLine(text: 'Daño accidental durante el periodo de renta'),
                _TermLine(text: 'Robo o extravío comprobado de la herramienta'),
                _TermLine(text: 'Roturas atribuibles al uso indebido del solicitante'),
                const SizedBox(height: 14),
                Text('No cubre:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.error)),
                const SizedBox(height: 6),
                _TermLine(text: 'Desgaste normal por uso (brocas, discos, consumibles)', negative: true),
                _TermLine(text: 'Fletes, traslados o tiempo de inactividad del propietario', negative: true),
                _TermLine(text: 'Daños previos no declarados al publicar la herramienta', negative: true),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Entendido'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isAvailable = widget.isAvailable;
    final semaphoreColor = isAvailable ? AppColors.success : const Color(0xFF2563EB);
    final semaphoreText = isAvailable
        ? 'Listo para rentar. Tu equipo está respaldado contra daño total y robo.'
        : 'Fondo bloqueado. MercadoPago tiene retenido el deducible del solicitante.';
    final semaphoreIcon = isAvailable ? Icons.check_circle_outline : Icons.lock_outline;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.verified_user_rounded, color: cs.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Garantía de Activo de Confianza',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: cs.onSurface)),
              ),
            ]),
            const SizedBox(height: 10),
            Text(
              'Valor comercial tasado por IA: \$${widget.estimatedValue.toStringAsFixed(0)} MXN',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            // Seguro por herramienta (independiente del plan Pro/Gratuito)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.health_and_safety_outlined, color: cs.primary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Seguro contra daños y robo',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                    '\$${_monthlyPremium.toStringAsFixed(0)} MXN/mes (5% del valor tasado)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: cs.primary),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    value: _insuranceWanted,
                    onChanged: (v) => setState(() => _insuranceWanted = v),
                    title: Text(
                      _insuranceWanted ? 'Quiero contratar este seguro' : 'Sin seguro contratado',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: cs.onSurface),
                    ),
                    subtitle: Text(
                      _insuranceWanted
                          ? 'Registramos tu interés. El cobro mensual se activará próximamente.'
                          : 'Actívalo para proteger esta herramienta contra daño total y robo.',
                      style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: semaphoreColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: semaphoreColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(semaphoreIcon, color: semaphoreColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      semaphoreText,
                      style: TextStyle(fontSize: 12, color: semaphoreColor, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _showTerms(context),
                child: const Text('Ver términos de cobertura'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TermLine extends StatelessWidget {
  final String text;
  final bool negative;
  const _TermLine({required this.text, this.negative = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            negative ? Icons.close_rounded : Icons.check_rounded,
            size: 15,
            color: negative ? cs.error : AppColors.success,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant, height: 1.3)),
          ),
        ],
      ),
    );
  }
}