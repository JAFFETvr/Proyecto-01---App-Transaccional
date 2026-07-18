import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/tool_provider.dart';
import '../../domain/entitie/tool_entity.dart';
import 'pro_subscription_checkout_screen.dart';
import '../widgets/tool_photo_field.dart';
import '../widgets/ticket_upload_field.dart';
import '../widgets/tool_basic_info_fields.dart';
import '../widgets/tool_condition_dropdown.dart';
import '../widgets/tool_pricing_card.dart';
import '../widgets/tool_availability_switch.dart';
import '../widgets/tool_share_backup_card.dart';
import '../widgets/tool_location_field.dart';

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

  bool _ticketLoading = false;
  double? _ticketDetectedPrice;
  bool _ticketValidado = false;

  double _suggestedPrice = 100.0;
  double _minPrice = 50.0;
  late double _finalPrice;
  bool _fetchingPricing = false;
  bool _requiresManualReview = false;
  String _pricingDesc = '';
  Timer? _debounceTimer;

  bool get _isEditing => widget.tool != null;

  static const _categories = [
    'Manual', 'Eléctrico', 'Neumático', 'Medición', 'Energía', 'Otro',
  ];

  @override
  void initState() {
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

  double _scoreForWearLevel(String level) {
    if (level == 'Nuevo') return 1.0;
    if (level == 'Buen Estado') return 0.8;
    if (level == 'Desgastado') return 0.5;
    return 0.7;
  }

  Future<void> _updatePricingSuggestion() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _fetchingPricing = true);

    try {
      final res = await context.read<ToolProvider>().autoValuate(
        name: name,
        scoreCondicion: _scoreForWearLevel(_wearLevel),
        category: _catCtrl.text.trim(),
        brand: _brandCtrl.text.trim().isEmpty ? 'Generico' : _brandCtrl.text.trim(),
        ageMonths: int.tryParse(_ageCtrl.text.trim()) ?? 12,
        precioBaseManual: _ticketValidado ? _ticketDetectedPrice : null,
        ticketValidado: _ticketValidado,
      );
      if (res != null && mounted) {
        setState(() {
          _suggestedPrice = (res['suggested_daily_rate'] as num?)?.toDouble() ?? 100.0;
          _minPrice = (res['minimum_daily_rate'] as num?)?.toDouble() ?? 50.0;
          _pricingDesc = res['description'] as String? ?? '';
          _requiresManualReview = res['requires_manual_review'] as bool? ?? false;

          final estValue = (res['estimated_value'] as num?)?.toDouble();
          if (estValue != null && estValue > 0) {
            _estValCtrl.text = estValue.toStringAsFixed(0);
          }

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
    } finally {
      if (mounted) {
        setState(() => _fetchingPricing = false);
      }
    }
  }

  Future<void> _pickTicketImage() async {
    final source = await _chooseImageSource();
    if (source == null) return;

    setState(() => _ticketLoading = true);
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1080,
      );
      if (xFile != null && mounted) {
        final file = File(xFile.path);
        final provider = context.read<ToolProvider>();
        final res = await provider.extractTicketPrice(file);
        final valid = res?['valid'] as bool? ?? false;
        final precio = (res?['precio_detectado'] as num?)?.toDouble();

        if (valid && precio != null && mounted) {
          setState(() {
            _ticketDetectedPrice = precio;
            _ticketValidado = true;
          });
          await _updatePricingSuggestion();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Ticket leído: \$${precio.toStringAsFixed(0)} MXN detectado y verificado.'),
              backgroundColor: const Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
            ));
          }
        } else if (mounted) {
          setState(() {
            _ticketDetectedPrice = null;
            _ticketValidado = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(res?['error'] as String? ??
                'No se pudo leer un monto en el ticket. Se usará el catálogo de referencia.'),
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No se pudo acceder a la cámara/galería.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _ticketLoading = false);
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

    if (!_isEditing && (double.tryParse(_estValCtrl.text.trim()) ?? 0) <= 0) {
      await _updatePricingSuggestion();
      if ((double.tryParse(_estValCtrl.text.trim()) ?? 0) <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Completa nombre y categoría para calcular el valor de la herramienta.'),
              backgroundColor: Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    }

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
        conditionScore: _scoreForWearLevel(_wearLevel),
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
              ToolPhotoField(
                pickedImage: _pickedImage,
                existingPhotoUrl: widget.tool?.photoUrl,
                loading: _imageLoading,
                onTap: _pickImage,
              ),
              const SizedBox(height: 24),

              TicketUploadField(
                ticketValidado: _ticketValidado,
                detectedPrice: _ticketDetectedPrice,
                loading: _ticketLoading,
                onPickTicket: _pickTicketImage,
              ),
              const SizedBox(height: 24),

              ToolBasicInfoFields(
                nameCtrl: _nameCtrl,
                brandCtrl: _brandCtrl,
                modelCtrl: _modelCtrl,
                ageCtrl: _ageCtrl,
                catCtrl: _catCtrl,
                estValCtrl: _estValCtrl,
                descCtrl: _descCtrl,
                isEditing: _isEditing,
                ticketValidado: _ticketValidado,
                fetchingPricing: _fetchingPricing,
                categories: _categories,
                onFieldChanged: _onFieldChanged,
                onCategorySelected: (v) {
                  _catCtrl.text = v;
                  _updatePricingSuggestion();
                },
              ),
              const SizedBox(height: 24),

              ToolConditionDropdown(
                wearLevel: _wearLevel,
                isEditing: _isEditing,
                onChanged: (v) {
                  setState(() => _wearLevel = v);
                  _updatePricingSuggestion();
                },
              ),
              const SizedBox(height: 24),

              ToolPricingCard(
                suggestedPrice: _suggestedPrice,
                minPrice: _minPrice,
                finalPrice: _finalPrice,
                maxRateVal: maxRateVal,
                fetchingPricing: _fetchingPricing,
                pricingDesc: _pricingDesc,
                requiresManualReview: _requiresManualReview,
                onFinalPriceChanged: (v) => setState(() => _finalPrice = v),
              ),
              const SizedBox(height: 20),

              ToolAvailabilitySwitch(
                value: _isAvailable,
                onChanged: (v) => setState(() => _isAvailable = v),
              ),
              const SizedBox(height: 20),

              if (_isEditing) ...[
                ToolShareBackupCard(
                  toolId: widget.tool!.id,
                  estimatedValue: widget.tool!.estimatedValue,
                  isAvailable: widget.tool!.isAvailable,
                  insuranceActive: widget.tool!.wantsInsurance,
                ),
                const SizedBox(height: 20),
              ],

              ToolLocationField(
                latitude: _latitude,
                longitude: _longitude,
                onLocationPicked: (res) {
                  setState(() {
                    _latitude = res.latitude;
                    _longitude = res.longitude;
                  });
                },
              ),
              const SizedBox(height: 28),

              FilledButton.icon(
                onPressed: provider.loading ? null : _save,
                icon: provider.loading
                    ? SizedBox(
                        height: 18, width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimary))
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
