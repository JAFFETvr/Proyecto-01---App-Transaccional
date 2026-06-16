import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/widgets/primary_gradient_button.dart';

class RentalTrackingRequesterScreen extends StatefulWidget {
  const RentalTrackingRequesterScreen({super.key});

  @override
  State<RentalTrackingRequesterScreen> createState() =>
      _RentalTrackingRequesterScreenState();
}

class _RentalTrackingRequesterScreenState
    extends State<RentalTrackingRequesterScreen> {
  int _phase = 0;
  bool _loading = false;
  double? _lat;
  double? _lng;
  String? _contractHash;

  Future<void> _confirmDelivery() async {
    setState(() => _loading = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm != LocationPermission.deniedForever) {
        final pos = await Geolocator.getCurrentPosition(
            locationSettings:
                const LocationSettings(accuracy: LocationAccuracy.high));
        _lat = pos.latitude;
        _lng = pos.longitude;
      }
    } catch (_) {}

    await Future.delayed(const Duration(seconds: 1));
    final hash =
        DateTime.now().millisecondsSinceEpoch.toRadixString(16).toUpperCase();
    setState(() {
      _contractHash = 'SHA-$hash';
      _phase = 2;
      _loading = false;
    });
  }

  Future<void> _confirmReturn() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() { _phase = 3; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.slate900),
        automaticallyImplyLeading: _phase == 3,
        title: Text(
          'Seguimiento de Renta',
          style: GoogleFonts.montserrat(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.slate900,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE2E8F0)),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _PhaseIndicator(currentPhase: _phase > 2 ? 2 : _phase),
            const SizedBox(height: 8),
            Expanded(
              child: IndexedStack(
                index: _phase > 2 ? 2 : _phase,
                children: [
                  _Phase1Widget(
                      onNext: () => setState(() => _phase = 1)),
                  _Phase2RequesterWidget(
                    loading: _loading,
                    onConfirm: _confirmDelivery,
                  ),
                  _Phase3RequesterWidget(
                    loading: _loading,
                    contractHash: _contractHash,
                    lat: _lat, lng: _lng,
                    onConfirmReturn: _confirmReturn,
                    confirmed: _phase == 3,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Fase 1: Fondos retenidos ─────────────────────────────────────────────────

class _Phase1Widget extends StatelessWidget {
  final VoidCallback onNext;
  const _Phase1Widget({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100, height: 100,
            decoration: const BoxDecoration(
              color: AppColors.successBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_rounded,
                size: 50, color: AppColors.success),
          ),
          const SizedBox(height: 28),
          Text(
            'Fondos retenidos con éxito',
            style: GoogleFonts.montserrat(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.success,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Tu depósito de garantía está retenido de forma segura.\nAhora coordina el encuentro con el propietario.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.slate600,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(children: [
              _InfoTile(
                icon: Icons.phone_outlined,
                title: 'Contacta al propietario',
                subtitle:
                    'Una vez coordinados, confirmen la entrega en sus apps.',
              ),
              const SizedBox(height: 14),
              const Divider(color: Color(0xFFE2E8F0)),
              const SizedBox(height: 14),
              _InfoTile(
                icon: Icons.handshake_outlined,
                title: 'Inspecciona la herramienta',
                subtitle:
                    'Verifica que esté en el estado descrito antes de confirmar.',
              ),
            ]),
          ),
          const Spacer(),
          PrimaryGradientButton(
            label: 'Listo para confirmar entrega',
            icon: Icons.navigate_next,
            height: 55,
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

// ── Fase 2: Confirmar entrega ────────────────────────────────────────────────

class _Phase2RequesterWidget extends StatelessWidget {
  final bool loading;
  final VoidCallback onConfirm;

  const _Phase2RequesterWidget(
      {required this.loading, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.orange500.withOpacity(0.12),
                  AppColors.orange600.withOpacity(0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.handshake_outlined,
                size: 50, color: AppColors.orange500),
          ),
          const SizedBox(height: 28),
          Text(
            'Confirmar Entrega',
            style: GoogleFonts.montserrat(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.slate900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Al presionar el botón, capturaremos tu ubicación GPS actual como prueba de la entrega.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.slate600,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF6366F1).withOpacity(0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline,
                  size: 16, color: Color(0xFF6366F1)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'El propietario también debe presionar su botón de "Confirmar Entrega" para completar el proceso.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF3730A3),
                    height: 1.4,
                  ),
                ),
              ),
            ]),
          ),
          const Spacer(),
          loading
              ? const CircularProgressIndicator()
              : PrimaryGradientButton(
                  label: 'Confirmar Entrega',
                  icon: Icons.check_circle_outlined,
                  height: 58,
                  fontSize: 16,
                  onPressed: onConfirm,
                ),
        ],
      ),
    );
  }
}

// ── Fase 3: Devolución ───────────────────────────────────────────────────────

class _Phase3RequesterWidget extends StatelessWidget {
  final bool loading;
  final String? contractHash;
  final double? lat;
  final double? lng;
  final VoidCallback onConfirmReturn;
  final bool confirmed;

  const _Phase3RequesterWidget({
    required this.loading,
    this.contractHash,
    this.lat,
    this.lng,
    required this.onConfirmReturn,
    required this.confirmed,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Contrato digital
          if (contractHash != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.success.withOpacity(0.3)),
              ),
              child: Column(children: [
                const Icon(Icons.verified_outlined,
                    color: AppColors.success, size: 28),
                const SizedBox(height: 6),
                Text(
                  'Contrato digital generado',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  contractHash!,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.slate600,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (lat != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'GPS: ${lat!.toStringAsFixed(5)}, ${lng!.toStringAsFixed(5)}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.slate600,
                    ),
                  ),
                ],
              ]),
            ),
            const SizedBox(height: 20),
          ],

          if (!confirmed) ...[
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                color: AppColors.orange500.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.assignment_return_outlined,
                  size: 46, color: AppColors.orange500),
            ),
            const SizedBox(height: 20),
            Text(
              'Devolver herramienta',
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.slate900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Cuando devuelvas la herramienta, presiona el botón para notificar al propietario.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.slate600,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            loading
                ? const CircularProgressIndicator()
                : PrimaryGradientButton(
                    label: 'Confirmar Devolución',
                    icon: Icons.check_outlined,
                    height: 55,
                    onPressed: onConfirmReturn,
                  ),
          ] else ...[
            const SizedBox(height: 20),
            Container(
              width: 90, height: 90,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  size: 50, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              'Devolución confirmada',
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.success,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Esperando confirmación del propietario. El depósito será devuelto una vez que acepte la devolución.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.slate600,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Indicador de fases ───────────────────────────────────────────────────────

class _PhaseIndicator extends StatelessWidget {
  final int currentPhase;
  const _PhaseIndicator({required this.currentPhase});

  @override
  Widget build(BuildContext context) {
    const phases = ['Retención', 'Entrega', 'Devolución'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: List.generate(phases.length * 2 - 1, (i) {
          if (i.isOdd) {
            return Expanded(
              child: Container(
                height: 2,
                color: i ~/ 2 < currentPhase
                    ? AppColors.orange500
                    : const Color(0xFFE2E8F0),
              ),
            );
          }
          final idx = i ~/ 2;
          final done = idx < currentPhase;
          final active = idx == currentPhase;
          return Column(mainAxisSize: MainAxisSize.min, children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 32, height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: done ? AppColors.primaryGradient : null,
                color: done
                    ? null
                    : active
                        ? AppColors.orange500.withOpacity(0.1)
                        : const Color(0xFFE2E8F0),
                border: Border.all(
                  color:
                      active ? AppColors.orange500 : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Center(
                child: done
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text(
                        '${idx + 1}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: active
                              ? AppColors.orange500
                              : AppColors.slate600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              phases[idx],
              style: GoogleFonts.inter(
                fontSize: 11,
                color:
                    active ? AppColors.orange500 : AppColors.slate600,
                fontWeight:
                    active ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ]);
        }),
      ),
    );
  }
}

// ── _InfoTile ────────────────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _InfoTile(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: AppColors.orange500.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: AppColors.orange500),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.slate900,
              )),
          Text(subtitle,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.slate600,
              )),
        ]),
      ),
    ]);
  }
}
