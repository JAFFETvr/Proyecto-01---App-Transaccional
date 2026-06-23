import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../providers/rental_provider.dart';
import '../../domain/entitie/rental_entity.dart';
import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/widgets/primary_gradient_button.dart';

class RentalTrackingOwnerScreen extends StatefulWidget {
  const RentalTrackingOwnerScreen({super.key});

  @override
  State<RentalTrackingOwnerScreen> createState() =>
      _RentalTrackingOwnerScreenState();
}

class _RentalTrackingOwnerScreenState
    extends State<RentalTrackingOwnerScreen> {
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
          content: Text('¡Devolución aceptada y fondos liberados! ✓'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final err = context.read<RentalProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'Error al aceptar la devolución'),
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
        title: Text('Reportar daño o disputa', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Describe el daño, retraso o inconveniente. Soporte evaluará el depósito en garantía.',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Ej. La herramienta volvió rota...',
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
          content: Text('Disputa registrada para revisión de soporte.'),
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

    // Determine current index for OwnerPhaseIndicator
    // 0: Confirmar Entrega (Status: pending)
    // 1: Herramienta Rentada (Status: active)
    // 2: Devolución Aceptada (Status: completed)
    // 3: Dispute (Status: disputed)
    int phaseIndex = 0;
    if (rental.isActive) phaseIndex = 1;
    if (rental.isCompleted) phaseIndex = 2;
    if (rental.isDisputed) phaseIndex = 3;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.slate900),
        title: Text(
          'Panel del Propietario',
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
            _OwnerPhaseIndicator(phase: phaseIndex),
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _buildBodyContent(rental, phaseIndex),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: phaseIndex == 1
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      rental.requesterConfirmedReturn
                          ? 'El solicitante solicita confirmación de devolución:'
                          : 'Esperando que el solicitante inicie el retorno físico...',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.slate600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    _loading
                        ? const Center(child: CircularProgressIndicator())
                        : Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.danger,
                                    side: const BorderSide(color: AppColors.danger),
                                    minimumSize: const Size(0, 48),
                                  ),
                                  onPressed: () => _reportDispute(rental.id),
                                  icon: const Icon(Icons.report_problem_outlined, size: 18),
                                  label: const Text('Disputa'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      shadowColor: Colors.transparent,
                                      minimumSize: const Size(0, 48),
                                    ),
                                    onPressed: () => _confirmReturn(rental.id),
                                    icon: const Icon(Icons.check_rounded, size: 18),
                                    label: const Text('Aceptar Retorno'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBodyContent(RentalEntity rental, int phaseIndex) {
    switch (phaseIndex) {
      case 0:
        return _OwnerPhase0(
          loading: _loading,
          rental: rental,
          onConfirm: () => _confirmDelivery(rental.id),
        );
      case 1:
        return _OwnerPhase1(rental: rental);
      case 2:
        return _OwnerPhase2Accepted();
      case 3:
      default:
        return _OwnerPhase2Rejected(rental: rental);
    }
  }
}

class _OwnerPhase0 extends StatelessWidget {
  final bool loading;
  final RentalEntity rental;
  final VoidCallback onConfirm;

  const _OwnerPhase0({
    required this.loading,
    required this.rental,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 90, height: 90,
          decoration: BoxDecoration(
            color: AppColors.orange500.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.construction_outlined,
              size: 44, color: AppColors.orange500),
        ),
        const SizedBox(height: 24),
        Text(
          'Entregar Herramienta',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.slate900,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Reúnete con el solicitante en el lugar acordado. Al entregar la herramienta física, presiona Confirmar Entrega.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.slate600,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.check_circle_outline, size: 16, color: AppColors.success),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  rental.ownerConfirmedDelivery
                      ? 'Confirmaste la entrega ✓'
                      : 'Falta tu confirmación de entrega',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate700, fontWeight: FontWeight.w600),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.check_circle_outline, size: 16, color: AppColors.success),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  rental.requesterConfirmedDelivery
                      ? 'El solicitante confirmó la entrega ✓'
                      : 'Falta confirmación de entrega del solicitante',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate700, fontWeight: FontWeight.w600),
                ),
              ),
            ]),
          ]),
        ),
        const Spacer(),
        loading
            ? const CircularProgressIndicator()
            : PrimaryGradientButton(
                label: rental.ownerConfirmedDelivery ? 'Esperando Solicitante...' : 'Confirmar Entrega',
                icon: Icons.check_outlined,
                height: 52,
                onPressed: rental.ownerConfirmedDelivery ? null : onConfirm,
              ),
      ],
    );
  }
}

class _OwnerPhase1 extends StatelessWidget {
  final RentalEntity rental;
  const _OwnerPhase1({required this.rental});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 90, height: 90,
          decoration: const BoxDecoration(
            color: Color(0xFFE0E7FF),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.timer_outlined, size: 44, color: Color(0xFF4F46E5)),
        ),
        const SizedBox(height: 24),
        Text(
          'Herramienta en Renta',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.slate900,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'El solicitante posee la herramienta física. Los fondos están garantizados e inmutables bajo contrato digital.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.slate600,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        if (rental.contractHash.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.successBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Column(children: [
              Text(
                'Contrato Digital Activo',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.success, fontSize: 13),
              ),
              const SizedBox(height: 4),
              SelectableText(
                rental.contractHash,
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate700, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ]),
          ),
        const Spacer(),
      ],
    );
  }
}

class _OwnerPhase2Accepted extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 90, height: 90,
          decoration: const BoxDecoration(
            color: AppColors.successBg,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_rounded,
              size: 46, color: AppColors.success),
        ),
        const SizedBox(height: 24),
        Text(
          'Devolución Completada',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Has confirmado la devolución física. Los fondos se han transferido a tu saldo y el depósito de garantía ha sido devuelto al solicitante.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.slate600,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        PrimaryGradientButton(
          label: 'Volver a mi Panel',
          onPressed: () => Navigator.of(context).pushReplacementNamed('/propietario'),
        ),
      ],
    );
  }
}

class _OwnerPhase2Rejected extends StatelessWidget {
  final RentalEntity rental;
  const _OwnerPhase2Rejected({required this.rental});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 90, height: 90,
          decoration: BoxDecoration(
            color: AppColors.dangerBg,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.gavel_rounded, size: 44, color: AppColors.danger),
        ),
        const SizedBox(height: 24),
        Text(
          'Renta Reportada en Disputa',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.danger,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Se ha abierto un reporte de disputa sobre este contrato. El soporte de ToolShare evaluará la situación y el depósito en garantía.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.slate600,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        if (rental.disputeReason.isNotEmpty)
          Card(
            color: AppColors.dangerBg.withOpacity(0.4),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Detalle del reporte:', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.danger)),
                  const SizedBox(height: 6),
                  Text(rental.disputeReason, style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate700)),
                ],
              ),
            ),
          ),
        const Spacer(),
        PrimaryGradientButton(
          label: 'Volver a mi Panel',
          onPressed: () => Navigator.of(context).pushReplacementNamed('/propietario'),
        ),
      ],
    );
  }
}

class _OwnerPhaseIndicator extends StatelessWidget {
  final int phase;
  const _OwnerPhaseIndicator({required this.phase});

  @override
  Widget build(BuildContext context) {
    const steps = ['Entrega', 'En Renta', 'Devolución'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            return Expanded(
              child: Container(
                height: 2,
                color: i ~/ 2 < (phase > 2 ? 2 : phase)
                    ? AppColors.orange500
                    : const Color(0xFFE2E8F0),
              ),
            );
          }
          final idx = i ~/ 2;
          final done = idx < (phase > 2 ? 2 : phase);
          final active = idx == (phase > 2 ? 2 : phase);
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
              steps[idx],
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
