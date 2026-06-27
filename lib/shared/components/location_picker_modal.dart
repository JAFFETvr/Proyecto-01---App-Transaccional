import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../theme/app_colors.dart';

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

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null && widget.initialLat != 0.0) {
      _currentLocation = LatLng(widget.initialLat!, widget.initialLng!);
    } else {
      _currentLocation = _defaultSuchiapa;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.surface,
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
                      child: FloatingActionButton.small(
                        backgroundColor: AppColors.slate900,
                        foregroundColor: Colors.white,
                        child: const Icon(Icons.my_location_rounded),
                        onPressed: () {
                          setState(() => _currentLocation = _defaultSuchiapa);
                          _mapController.move(_defaultSuchiapa, 15);
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Pie de Confirmación
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.surface, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))]),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Coordenadas seleccionadas:', style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate500)),
                          Text('${_currentLocation.latitude.toStringAsFixed(4)}, ${_currentLocation.longitude.toStringAsFixed(4)}', style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, color: AppColors.slate900, fontSize: 13)),
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
