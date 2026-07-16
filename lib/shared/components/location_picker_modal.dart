import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../theme/app_colors.dart';
import '../theme/theme_extensions.dart';

class LocationPickerModal extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const LocationPickerModal({super.key, this.initialLat, this.initialLng});

  @override
  State<LocationPickerModal> createState() => _LocationPickerModalState();
}

class _LocationPickerModalState extends State<LocationPickerModal> {
  // Centro por defecto: Suchiapa, Chiapas
  static const _defaultSuchiapa = LatLng(16.6264, -93.0911);
  late LatLng _currentLocation;
  final MapController _mapController = MapController();
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    final hasInitial = widget.initialLat != null && widget.initialLng != null && widget.initialLat != 0.0;
    if (hasInitial) {
      _currentLocation = LatLng(widget.initialLat!, widget.initialLng!);
    } else {
      _currentLocation = _defaultSuchiapa;
      // Herramienta nueva sin ubicación previa: centramos en la posición real del usuario.
      WidgetsBinding.instance.addPostFrameCallback((_) => _goToMyLocation(silent: true));
    }
  }

  Future<void> _goToMyLocation({bool silent = false}) async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!silent) _showLocationError('Activa la ubicación del dispositivo para usar tu posición real.');
        return;
      }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
        if (!silent) _showLocationError('Permiso de ubicación denegado.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      final here = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() => _currentLocation = here);
      _mapController.move(here, 16);
    } catch (_) {
      if (!silent) _showLocationError('No se pudo obtener tu ubicación.');
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: context.surface,
      insetPadding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          width: double.infinity,
          height: 520,
          child: Column(
            children: [
              // Barra superior
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                color: AppColors.slate900,
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: AppColors.orange500),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ubicación de Herramienta', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                          Text('Toca en el mapa para marcar dónde se encuentra', style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
              ),

              // Mapa
              Expanded(
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _currentLocation,
                        initialZoom: 14.5,
                        minZoom: 3,
                        maxZoom: 19,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all,
                        ),
                        onTap: (tapPos, point) {
                          setState(() => _currentLocation = point);
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.toolshare.app',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _currentLocation,
                              width: 50,
                              height: 50,
                              child: const Icon(Icons.location_pin, color: AppColors.orange500, size: 48),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Column(
                        children: [
                          FloatingActionButton.small(
                            heroTag: 'zoom_in',
                            backgroundColor: AppColors.slate900,
                            foregroundColor: Colors.white,
                            child: const Icon(Icons.add_rounded),
                            onPressed: () => _zoomBy(1),
                          ),
                          const SizedBox(height: 8),
                          FloatingActionButton.small(
                            heroTag: 'zoom_out',
                            backgroundColor: AppColors.slate900,
                            foregroundColor: Colors.white,
                            child: const Icon(Icons.remove_rounded),
                            onPressed: () => _zoomBy(-1),
                          ),
                          const SizedBox(height: 8),
                          FloatingActionButton.small(
                            heroTag: 'my_location',
                            backgroundColor: AppColors.slate900,
                            foregroundColor: Colors.white,
                            child: _locating
                                ? const SizedBox(
                                    width: 16, height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.my_location_rounded),
                            onPressed: _locating ? null : () => _goToMyLocation(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Pie de Confirmación
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: context.surface, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))]),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Coordenadas seleccionadas:', style: GoogleFonts.inter(fontSize: 11, color: context.textSecondary)),
                          Text('${_currentLocation.latitude.toStringAsFixed(4)}, ${_currentLocation.longitude.toStringAsFixed(4)}', style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, color: context.textPrimary, fontSize: 13)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange500,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.pop(context, _currentLocation),
                      child: Text('Confirmar ✓', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
