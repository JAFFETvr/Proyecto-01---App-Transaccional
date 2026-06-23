import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../providers/rental_provider.dart';
import '../../domain/entitie/rental_entity.dart';
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
  int _localPhase = 0; // 0: Funds secured (Introduction), 1: Main tracking
  bool _loading = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialRental = ModalRoute.of(context)?.settings.arguments as RentalEntity?;
      if (initialRental != null) {
        context.read<RentalProvider>().fetchRental(initialRental.id);
        _startPolling(initialRental.id);
      }
    });
  }

  void _startPolling(String rentalId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      final provider = context.read<RentalProvider>();
      provider.fetchRental(rentalId);
      final rental = provider.currentRental;
      if (rental != null && (rental.isCompleted || rental.isCancelled || rental.isDisputed)) {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _confirmDelivery(String rentalId) async {
    setState(() => _loading = true);
    double? latitude;
    double? longitude;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm == LocationPermission.always || perm == LocationPermission.whileInUse) {
          final pos = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
          latitude = pos.latitude;
          longitude = pos.longitude;
        }
      }
    } catch (_) {}

    final ok = await context.read<RentalProvider>().confirmDelivery(
          rentalId,
          latitude: latitude,
          longitude: longitude,
        );

    setState(() => _loading = false);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Entrega física confirmada por ti! ✓'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final err = context.read<RentalProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'Error al confirmar la entrega'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmReturn(String rentalId) async {
    setState(() => _loading = true);
    final ok = await context.read<RentalProvider>().confirmReturn(rentalId);
    setState(() => _loading = false);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Devolución confirmada por ti! ✓'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final err = context.read<RentalProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'Error al confirmar la devolución'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _reportDispute(String rentalId) async {
    final reasonCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reportar disputa', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Describe el problema con la herramienta para que soporte intervenga y retenga los fondos.',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Ej. La herramienta no enciende...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Abrir Disputa'),
          ),
        ],
      ),
    );

    if (confirm != true || reasonCtrl.text.trim().length < 10) {
      if (confirm == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La justificación debe tener al menos 10 caracteres')),
        );
      }
      return;
    }

    setState(() => _loading = true);
    final ok = await context.read<RentalProvider>().disputeRental(rentalId, reasonCtrl.text.trim());
    setState(() => _loading = false);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Disputa reportada. Soporte intervendrá.'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RentalProvider>();
    final rental = provider.currentRental;

    if (rental == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Determine current index for PhaseIndicator
    // 0: Retención (Status: pending, both unconfirmed)
    // 1: Entrega (Status: pending, requester or owner confirmed, but not both)
    // 2: Devolución (Status: active or completed)
    int phaseIndicatorIndex = 0;
    if (rental.ownerConfirmedDelivery || rental.requesterConfirmedDelivery) {
      phaseIndicatorIndex = 1;
    }
    if (rental.isActive || rental.isCompleted || rental.isDisputed) {
      phaseIndicatorIndex = 2;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.slate900),
        automaticallyImplyLeading: rental.isCompleted || rental.isCancelled || rental.isDisputed,
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
            _PhaseIndicator(currentPhase: phaseIndicatorIndex),
            const SizedBox(height: 8),
            Expanded(
              child: _localPhase == 0 && phaseIndicatorIndex == 0
                  ? _Phase1Widget(onNext: () => setState(() => _localPhase = 1))
                  : _buildMainContent(rental),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(RentalEntity rental) {
    if (rental.isDisputed) {
      return _buildDisputedWidget(rental);
    }
    if (rental.isCompleted) {
      return _buildCompletedWidget(rental);
    }

    // Pending stage (Delivery)
    if (rental.isPending) {
      return _Phase2RequesterWidget(
        loading: _loading,
        rental: rental,
        onConfirm: () => _confirmDelivery(rental.id),
      );
    }

    // Active stage (Return)
    return _Phase3RequesterWidget(
      loading: _loading,
      rental: rental,
      onConfirmReturn: () => _confirmReturn(rental.id),
      onReportDispute: () => _reportDispute(rental.id),
    );
  }

  Widget _buildDisputedWidget(RentalEntity rental) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              color: AppColors.dangerBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.gavel_rounded, size: 50, color: AppColors.danger),
          ),
          const SizedBox(height: 28),
          Text(
            'Renta en Disputa',
            style: GoogleFonts.montserrat(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.danger,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Se ha abierto un folio de mediación debido a un reporte en la entrega/devolución.\nLos fondos permanecerán congelados temporalmente.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.slate600,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (rental.disputeReason.isNotEmpty)
            Card(
              color: AppColors.dangerBg.withOpacity(0.4),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Motivo de disputa:', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.danger)),
                    const SizedBox(height: 6),
                    Text(rental.disputeReason, style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate700)),
                  ],
                ),
              ),
            ),
          const Spacer(),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pushReplacementNamed('/solicitante'),
            child: const Text('Volver al Catálogo'),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedWidget(RentalEntity rental) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100, height: 100,
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 28),
          Text(
            '¡Renta Finalizada!',
            style: GoogleFonts.montserrat(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF10B981),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'El propietario ha confirmado el retorno de la herramienta en buen estado.\nTu depósito en garantía ha sido liberado.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.slate600,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          PrimaryGradientButton(
            label: 'Volver al Catálogo',
            onPressed: () => Navigator.of(context).pushReplacementNamed('/solicitante'),
          ),
        ],
      ),
    );
  }
}

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

class _Phase2RequesterWidget extends StatelessWidget {
  final bool loading;
  final RentalEntity rental;
  final VoidCallback onConfirm;

  const _Phase2RequesterWidget({
    required this.loading,
    required this.rental,
    required this.onConfirm,
  });

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
              color: AppColors.orange500.withOpacity(0.12),
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
            'Al presionar el botón, capturaremos tu ubicación GPS actual como prueba de la entrega física.',
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
                  rental.requesterConfirmedDelivery
                      ? 'Confirmaste la entrega. Esperando que el propietario confirme...'
                      : 'El propietario también debe confirmar la entrega para iniciar formalmente la renta.',
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
                  label: rental.requesterConfirmedDelivery ? 'Esperando Propietario...' : 'Confirmar Entrega',
                  icon: Icons.check_circle_outlined,
                  height: 58,
                  fontSize: 16,
                  onPressed: rental.requesterConfirmedDelivery ? null : onConfirm,
                ),
        ],
      ),
    );
  }
}

class _Phase3RequesterWidget extends StatelessWidget {
  final bool loading;
  final RentalEntity rental;
  final VoidCallback onConfirmReturn;
  final VoidCallback onReportDispute;

  const _Phase3RequesterWidget({
    required this.loading,
    required this.rental,
    required this.onConfirmReturn,
    required this.onReportDispute,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Contrato digital
          if (rental.contractHash.isNotEmpty) ...[
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
                  'Contrato digital inmutable generado',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  rental.contractHash,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.slate700,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (rental.deliveryLat != 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Coordenadas de encuentro: ${rental.deliveryLat.toStringAsFixed(5)}, ${rental.deliveryLng.toStringAsFixed(5)}',
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

          if (!rental.requesterConfirmedReturn) ...[
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
              'Cuando devuelvas la herramienta física al propietario, presiona el botón para solicitar la finalización y liberación de fondos.',
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
                : Column(
                    children: [
                      PrimaryGradientButton(
                        label: 'Confirmar Devolución',
                        icon: Icons.check_outlined,
                        height: 55,
                        onPressed: onConfirmReturn,
                      ),
                      const SizedBox(height: 14),
                      TextButton.icon(
                        onPressed: onReportDispute,
                        icon: const Icon(Icons.report_problem_outlined, color: AppColors.danger),
                        label: Text(
                          'Reportar problema / disputa',
                          style: GoogleFonts.inter(color: AppColors.danger, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
          ] else ...[
            const SizedBox(height: 20),
            Container(
              width: 90, height: 90,
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  size: 50, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              'Devolución confirmada por ti',
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF10B981),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Esperando confirmación del propietario. El depósito en garantía será devuelto a tu tarjeta en cuanto el propietario apruebe el estado físico.',
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
