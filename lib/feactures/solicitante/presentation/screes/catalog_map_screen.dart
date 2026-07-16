import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/theme_extensions.dart';
import '../../domain/entitie/tool_entity.dart';
import '../providers/catalog_provider.dart';
import 'tool_detail_screen.dart';

class CatalogMapScreen extends StatefulWidget {
  const CatalogMapScreen({super.key});

  @override
  State<CatalogMapScreen> createState() => _CatalogMapScreenState();
}

class _CatalogMapScreenState extends State<CatalogMapScreen> {
  static const _defaultCenter = LatLng(16.6264, -93.0911); // Suchiapa, Chiapas
  final MapController _mapController = MapController();
  ToolEntity? _selectedTool;
  bool _locating = false;

  Future<void> _goToMyLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationError('Activa la ubicación del dispositivo para centrar en tu posición real.');
        return;
      }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
        _showLocationError('Permiso de ubicación denegado.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      _mapController.move(LatLng(pos.latitude, pos.longitude), 15.5);
    } catch (_) {
      _showLocationError('No se pudo obtener tu ubicación.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _showLocationError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _zoomBy(double delta) {
    final camera = _mapController.camera;
    _mapController.move(camera.center, (camera.zoom + delta).clamp(3.0, 19.0));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CatalogProvider>();
    final tools = provider.filtered.where((t) => t.isAvailable).toList();

    return Scaffold(
      body: Stack(
        children: [
          // Mapa principal
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: 14.5,
              minZoom: 3,
              maxZoom: 19,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              onTap: (_, __) => setState(() => _selectedTool = null),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.toolshare.app',
              ),
              MarkerLayer(
                markers: tools.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final t = entry.value;
                  // Si no tiene coordenadas reales, poner cerca del centro con pequeño desfase visual
                  double lat = t.latitude != 0.0 ? t.latitude : _defaultCenter.latitude + (idx % 5 - 2) * 0.0025;
                  double lng = t.longitude != 0.0 ? t.longitude : _defaultCenter.longitude + (idx ~/ 5 - 2) * 0.0025;
                  final isSelected = _selectedTool?.id == t.id;

                  return Marker(
                    point: LatLng(lat, lng),
                    width: isSelected ? 60 : 48,
                    height: isSelected ? 60 : 48,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedTool = t);
                        _mapController.move(LatLng(lat, lng), 15.5);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.slate900 : AppColors.orange500,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: isSelected ? 3 : 2),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 4))],
                        ),
                        child: Icon(
                          Icons.build_rounded,
                          color: Colors.white,
                          size: isSelected ? 30 : 22,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Píldora superior de Navegación / Título
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(color: AppColors.slate900, borderRadius: BorderRadius.circular(14), boxShadow: AppColors.cardShadow),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.slate900.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: AppColors.orange500, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Mapa: ${tools.length} herramientas cercanas',
                              style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Botones de zoom + centrar en mi ubicación real
          Positioned(
            right: 16,
            bottom: _selectedTool != null ? 220 : 24,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'map_zoom_in',
                  backgroundColor: AppColors.slate900,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.add_rounded),
                  onPressed: () => _zoomBy(1),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'map_zoom_out',
                  backgroundColor: AppColors.slate900,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.remove_rounded),
                  onPressed: () => _zoomBy(-1),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'map_my_location',
                  backgroundColor: AppColors.slate900,
                  foregroundColor: Colors.white,
                  child: _locating
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.my_location_rounded),
                  onPressed: _locating ? null : _goToMyLocation,
                ),
              ],
            ),
          ),

          // Tarjeta emergente inferior de Herramienta seleccionada
          if (_selectedTool != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 250),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (ctx, val, child) => Transform.translate(
                  offset: Offset(0, 50 * (1 - val)),
                  child: Opacity(opacity: val, child: child),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 70, height: 70,
                        decoration: BoxDecoration(color: context.colors.surfaceContainerHigh, borderRadius: BorderRadius.circular(16)),
                        child: _selectedTool!.photoUrl.isNotEmpty
                            ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(_selectedTool!.photoUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.handyman_rounded, color: context.textSecondary, size: 32)))
                            : Icon(Icons.handyman_rounded, color: context.textSecondary, size: 32),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.orange500.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                              child: Text(_selectedTool!.category.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.orange600)),
                            ),
                            const SizedBox(height: 4),
                            Text(_selectedTool!.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 16, color: context.textPrimary)),
                            Text('\$${_selectedTool!.dailyRate.toStringAsFixed(0)} MXN / día', style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.emerald600)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.orange500,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 3,
                        ),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => ToolDetailScreen(tool: _selectedTool!)));
                        },
                        child: Text('Rentar', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                      )
                    ],
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }
}
