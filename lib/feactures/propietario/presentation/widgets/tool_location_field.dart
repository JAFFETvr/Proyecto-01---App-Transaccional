import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../../shared/components/location_picker_modal.dart';
import 'section_title.dart';

/// Selector de ubicación real de la herramienta en el mapa (obligatorio
/// para publicar).
class ToolLocationField extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  final bool editable;
  final ValueChanged<LatLng> onLocationPicked;

  const ToolLocationField({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.onLocationPicked,
    this.editable = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasLocation =
        latitude != null && longitude != null && latitude != 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Geolocalización (Mapa Cercano)'),
        const SizedBox(height: 12),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: const Icon(
              Icons.map_rounded,
              color: Color(0xFFEA580C),
              size: 32,
            ),
            title: Text(
              hasLocation
                  ? 'Ubicación seleccionada'
                  : 'Ubicación no establecida',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              hasLocation
                  ? 'Coordenadas: ${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)}'
                  : 'No seleccionada — obligatoria para publicar',
              style: TextStyle(
                fontSize: 12,
                color: hasLocation
                    ? const Color(0xFF16A34A)
                    : cs.onSurfaceVariant,
              ),
            ),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA580C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Abrir Mapa'),
              onPressed: !editable
                  ? null
                  : () async {
                      final LatLng? res = await showDialog<LatLng>(
                        context: context,
                        builder: (_) => LocationPickerModal(
                          initialLat: latitude,
                          initialLng: longitude,
                        ),
                      );
                      if (res != null) onLocationPicked(res);
                    },
            ),
          ),
        ),
      ],
    );
  }
}
