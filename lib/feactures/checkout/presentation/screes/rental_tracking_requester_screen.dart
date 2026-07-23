import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../providers/rental_provider.dart';
import '../../domain/entitie/rental_entity.dart';
import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/theme/theme_extensions.dart';
import '../../../../../shared/widgets/primary_gradient_button.dart';
import '../components/rental_chat_sheet.dart';
import '../../../../../shared/components/contract_verification_widget.dart';
import '../../../../../core/services/biometric_service.dart';
import '../../../review/presentation/providers/review_provider.dart';
import '../../../review/presentation/components/submit_review_sheet.dart';

class RentalTrackingRequesterScreen extends StatefulWidget {
  const RentalTrackingRequesterScreen({super.key});

  @override
  State<RentalTrackingRequesterScreen> createState() =>
      _RentalTrackingRequesterScreenState();
}

class _RentalTrackingRequesterScreenState
    extends State<RentalTrackingRequesterScreen> with WidgetsBindingObserver {
  int _localPhase = 0;
  bool _loading = false;
  Timer? _pollTimer;
  String? _rentalId;
  bool _notifiedActive = false;
  // Se guarda la referencia al provider porque en dispose() ya no es seguro
  // hacer context.read<T>(): si toda la pantalla se está desmontando junto
  // con sus ancestros (ej. al navegar con pushAndRemoveUntil), buscar un
  // ancestro InheritedWidget en ese momento truena con "Looking up a
  // deactivated widget's ancestor is unsafe".
  late final RentalProvider _rentalProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialRental =
          ModalRoute.of(context)?.settings.arguments as RentalEntity?;
      if (initialRental != null) {
        _rentalId = initialRental.id;
        final skipIntro = initialRental.requesterConfirmedDelivery ||
            initialRental.ownerConfirmedDelivery ||
            initialRental.isActive ||
            initialRental.isCompleted ||
            initialRental.isDisputed ||
            initialRental.isCancelled;
        if (skipIntro && mounted) {
          setState(() => _localPhase = 1);
        }
        context.read<RentalProvider>().listenToRental(initialRental.id);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rentalProvider = context.read<RentalProvider>();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _rentalProvider.stopListeningRental();
    } else if (state == AppLifecycleState.resumed) {
      if (_rentalId != null) {
        _rentalProvider.listenToRental(_rentalId!);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _rentalProvider.stopListeningRental();
    super.dispose();
  }

  Future<void> _confirmDelivery(String rentalId) async {
    if (_loading) return;

    final authenticated = await BiometricService.authenticateSignature();
    if (!authenticated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Firma cancelada o autenticación fallida. ✕'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

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
      setState(() => _localPhase = 1);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Entrega confirmada por ti! ✓'),
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
    if (_loading) return;

    final authenticated = await BiometricService.authenticateSignature();
    if (!authenticated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Firma cancelada o autenticación fallida. ✕'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

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
              style: GoogleFonts.inter(fontSize: 13, color: context.textSecondary),
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

  void _showBackConfirmation(BuildContext context, RentalEntity rental) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.orange500.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.info_outline_rounded,
              size: 30, color: AppColors.orange500),
        ),
        title: Text(
          'Renta en progreso',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 17),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'Tu renta continúa activa. Puedes regresar al catálogo y volver a esta pantalla '
          'desde el botón "Mi Renta" cuando quieras retomar el seguimiento.',
          style: GoogleFonts.inter(fontSize: 13, color: context.textSecondary, height: 1.5),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Seguir aquí'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.orange500,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pushReplacementNamed('/solicitante');
            },
            icon: const Icon(Icons.home_outlined, size: 16),
            label: const Text('Ir al Catálogo'),
          ),
        ],
      ),
    );
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

    int phaseIndicatorIndex = 0;
    if (rental.ownerConfirmedDelivery || rental.requesterConfirmedDelivery) {
      phaseIndicatorIndex = 1;
    }
    if (rental.isActive || rental.isCompleted || rental.isDisputed) {
      phaseIndicatorIndex = 2;
    }

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: context.textPrimary),
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (rental.isCompleted || rental.isCancelled || rental.isDisputed) {
              Navigator.of(context).pushReplacementNamed('/solicitante');
            } else {
              _showBackConfirmation(context, rental);
            }
          },
        ),
        title: Text(
          'Seguimiento de Renta',
          style: GoogleFonts.montserrat(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.orange500),
            tooltip: 'Chat con propietario',
            onPressed: () => RentalChatSheet.show(
              context,
              rentalId: rental.id,
              currentUserId: rental.requesterId,
              title: 'Chat de Renta',
            ),
          ),
          if (!rental.isCompleted && !rental.isCancelled && !rental.isDisputed)
            TextButton.icon(
              onPressed: () => _showBackConfirmation(context, rental),
              icon: const Icon(Icons.home_outlined, size: 18),
              label: const Text('Inicio'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.orange500,
                textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: context.borderColor),
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

    if (rental.isPending) {
      if (rental.requesterConfirmedDelivery) {
        return _WaitingOwnerConfirmWidget();
      }
      return _Phase2RequesterWidget(
        loading: _loading,
        rental: rental,
        onConfirm: () => _confirmDelivery(rental.id),
      );
    }

    if (!_notifiedActive && rental.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_notifiedActive) {
          setState(() => _notifiedActive = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      '¡El propietario confirmó la entrega! La renta está activa.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      });
    }

    return _Phase3RequesterWidget(
      loading: _loading,
      rental: rental,
      onConfirmReturn: () => _confirmReturn(rental.id),
      onReportDispute: () => _reportDispute(rental.id),
    );
  }

  Widget _buildDisputedWidget(RentalEntity rental) {
    return SingleChildScrollView(
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
              color: context.textSecondary,
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
                    Text(rental.disputeReason, style: GoogleFonts.inter(fontSize: 13, color: context.textPrimary)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pushReplacementNamed('/solicitante'),
            child: const Text('Volver al Catálogo'),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedWidget(RentalEntity rental) {
    final reviewProvider = context.watch<ReviewProvider>();
    final alreadyReviewed = reviewProvider.hasReviewed(rental.id, role: 'requester');

    return SingleChildScrollView(
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
            'El propietario ha confirmado el retorno de la herramienta en buen estado.\nLa renta ha finalizado correctamente.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: context.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (!alreadyReviewed) ...[
            OutlinedButton.icon(
              icon: const Icon(Icons.star_outline_rounded),
              label: const Text('Calificar la herramienta'),
              onPressed: () => SubmitReviewSheet.show(
                context,
                rentalId: rental.id,
                role: 'requester',
                title: 'Califica la herramienta',
                subtitle: '¿Qué te pareció la herramienta que rentaste?',
              ),
            ),
            const SizedBox(height: 12),
          ],
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
    return SingleChildScrollView(
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
            'Tu pago (incluida la comisión de servicio) se procesó de forma segura.\nAhora coordina el encuentro con el propietario.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: context.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.surface,
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
              Divider(color: context.borderColor),
              const SizedBox(height: 14),
              _InfoTile(
                icon: Icons.handshake_outlined,
                title: 'Inspecciona la herramienta',
                subtitle:
                    'Verifica que esté en el estado descrito antes de confirmar.',
              ),
            ]),
          ),
          const SizedBox(height: 32),
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
    return SingleChildScrollView(
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
              color: context.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Al presionar el botón, capturaremos tu ubicación GPS actual como prueba de la entrega física.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: context.textSecondary,
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
          const SizedBox(height: 32),
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
          if (rental.contractHash.isNotEmpty) ...[
            ContractVerificationWidget(
              rental: rental,
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
                color: context.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Cuando devuelvas la herramienta física al propietario, presiona el botón para solicitar la finalización y liberación de fondos.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: context.textSecondary,
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
              'Esperando confirmación del propietario para completar la entrega.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: context.textSecondary,
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
                    : context.borderColor,
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
                        : context.borderColor,
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
                              : context.textSecondary,
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
                    active ? AppColors.orange500 : context.textSecondary,
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
                color: context.textPrimary,
              )),
          Text(subtitle,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: context.textSecondary,
              )),
        ]),
      ),
    ]);
  }
}

class _WaitingOwnerConfirmWidget extends StatelessWidget {
  const _WaitingOwnerConfirmWidget();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.92, end: 1.08),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeInOut,
            builder: (ctx, scale, child) => Transform.scale(
              scale: scale,
              child: child,
            ),
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.25),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.hourglass_top_rounded,
                  size: 48, color: Color(0xFF4F46E5)),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Esperando al Propietario',
            style: GoogleFonts.montserrat(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: context.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Confirmaste la recepción física de la herramienta. ✓\n'
            'Ahora el propietario debe confirmar desde su app para activar formalmente la renta.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: context.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.25)),
            ),
            child: Column(
              children: [
                _StatusRow(
                  icon: Icons.check_circle_rounded,
                  label: 'Tu confirmación de entrega',
                  done: true,
                ),
                const SizedBox(height: 10),
                Divider(color: context.borderColor, height: 1),
                const SizedBox(height: 10),
                _StatusRow(
                  icon: Icons.radio_button_unchecked,
                  label: 'Confirmación del propietario',
                  done: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.orange500.withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.lock_clock_rounded,
                  size: 16, color: AppColors.orange500),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Esta pantalla se actualizará automáticamente cuando el propietario confirme.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF92400E),
                    height: 1.4,
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool done;

  const _StatusRow({
    required this.icon,
    required this.label,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(
        icon,
        size: 18,
        color: done ? AppColors.success : context.colors.outline,
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: done ? FontWeight.w700 : FontWeight.w500,
            color: done ? context.textPrimary : context.textSecondary,
          ),
        ),
      ),
      if (done)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.successBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Hecho ✓',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.success,
            ),
          ),
        )
      else
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Pendiente',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4F46E5),
            ),
          ),
        ),
    ]);
  }
}
