import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

class FakeGpsBlockedScreen extends StatelessWidget {
  final VoidCallback onRetry;

  const FakeGpsBlockedScreen({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.slate900,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.gpp_bad_rounded, color: Colors.redAccent, size: 72),
                  const SizedBox(height: 20),
                  Text(
                    'Ubicación falsa detectada',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'ToolShare depende de tu ubicación real para operar de forma '
                    'segura (entregas, contrato GPS y valuación de herramientas).\n\n'
                    'Desactiva cualquier aplicación de Fake GPS y quita la app de '
                    'ubicación simulada en Opciones de desarrollador para continuar.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange500,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: onRetry,
                    child: Text('Reintentar', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => SystemNavigator.pop(),
                    child: Text('Salir de la app', style: GoogleFonts.inter(color: Colors.white54)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
