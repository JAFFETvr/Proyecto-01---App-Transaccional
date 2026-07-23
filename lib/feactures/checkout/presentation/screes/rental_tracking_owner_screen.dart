import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../providers/rental_provider.dart';
import '../providers/chat_provider.dart';
import '../../domain/entitie/rental_entity.dart';
import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/theme/theme_extensions.dart';
import '../../../../../shared/widgets/primary_gradient_button.dart';
import '../components/rental_chat_sheet.dart';
import '../components/rental_widgets.dart';
import '../../../../../shared/components/contract_verification_widget.dart';
import '../../../../../core/services/biometric_service.dart';

class RentalTrackingOwnerScreen extends StatefulWidget {
  const RentalTrackingOwnerScreen({super.key});

  @override
  State<RentalTrackingOwnerScreen> createState() =>
      _RentalTrackingOwnerScreenState();
}

class _RentalTrackingOwnerScreenState
    extends State<RentalTrackingOwnerScreen> with WidgetsBindingObserver {
  bool _loading = false;
  String? _rentalId;
  String? _ownerId;
  bool _hasUnreadChat = false;
  Timer? _unreadTimer;

  // Para avisar (in-app) cuando la OTRA parte cambia de estado. Se comparan
  // las banderas contra el build anterior para disparar el aviso una sola vez
  // por transición.
  bool? _prevReqDelivery;
  bool? _prevReqReturn;
  String? _prevStatus;

  void _maybeNotifyOwnerTransitions(RentalEntity rental) {
    final prevDelivery = _prevReqDelivery;
    final prevReturn = _prevReqReturn;
    final prevStatus = _prevStatus;
    _prevReqDelivery = rental.requesterConfirmedDelivery;
    _prevReqReturn = rental.requesterConfirmedReturn;
    _prevStatus = rental.status;
    if (prevDelivery == null) return; // primer build: solo tomar foto

    if (!prevDelivery &&
        rental.requesterConfirmedDelivery &&
        !rental.isActive) {
      _showInfoSnack(
          'El solicitante confirmó la entrega. Confirma tú para activar la renta.');
    }
    if (prevReturn == false && rental.requesterConfirmedReturn) {
      _showInfoSnack(
          'El solicitante confirmó la devolución. Revisa y acepta el retorno.');
    }
    if (prevStatus != 'completed' && rental.isCompleted) {
      _showInfoSnack('La renta se completó. ¡Gracias!');
    }
    if (prevStatus != 'disputed' && rental.isDisputed) {
      _showInfoSnack('Esta renta pasó a disputa.');
    }
  }

  void _showInfoSnack(String msg) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFF4F46E5),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    });
  }

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
      final initialRental = ModalRoute.of(context)?.settings.arguments as RentalEntity?;
      if (initialRental != null) {
        _rentalId = initialRental.id;
        _ownerId = initialRental.ownerId;
        context.read<RentalProvider>().listenToRental(initialRental.id);
        _startUnreadWatch();
      }
    });
  }

  void _startUnreadWatch() {
    _unreadTimer?.cancel();
    _refreshUnread();
    _unreadTimer =
        Timer.periodic(const Duration(seconds: 6), (_) => _refreshUnread());
  }

  Future<void> _refreshUnread() async {
    final rentalId = _rentalId;
    final userId = _ownerId;
    if (rentalId == null || userId == null) return;
    final unread =
        await context.read<ChatProvider>().hasUnreadFor(rentalId, userId);
    if (mounted && unread != _hasUnreadChat) {
      setState(() => _hasUnreadChat = unread);
    }
  }

  Future<void> _openChat(RentalEntity rental) async {
    await RentalChatSheet.show(
      context,
      rentalId: rental.id,
      currentUserId: rental.ownerId,
      title: 'Chat de Renta',
    );
    if (!mounted) return;
    await context.read<ChatProvider>().markChatSeen(rental.id);
    if (mounted) setState(() => _hasUnreadChat = false);
  }

  Future<void> _cancelRental(String rentalId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cancelar renta',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
        content: Text(
          'Aún nadie ha confirmado la entrega, así que puedes cancelar. '
          'La herramienta vuelve a quedar disponible.',
          style: GoogleFonts.inter(fontSize: 13, color: context.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No, seguir'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _loading = true);
    final ok = await context.read<RentalProvider>().cancelRental(rentalId);
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Renta cancelada.'),
          backgroundColor: Color(0xFF64748B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pushReplacementNamed('/propietario');
    } else {
      final err = context.read<RentalProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'No se pudo cancelar la renta'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
      _unreadTimer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      if (_rentalId != null) {
        _rentalProvider.listenToRental(_rentalId!);
        _startUnreadWatch();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _unreadTimer?.cancel();
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
              'Describe el daño, retraso o inconveniente. Soporte evaluará el caso.',
              style: GoogleFonts.inter(fontSize: 13, color: context.textSecondary),
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

  void _showBackConfirmation(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF4F46E5).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.info_outline_rounded,
              size: 30, color: Color(0xFF4F46E5)),
        ),
        title: Text(
          'Renta en progreso',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 17),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'La renta continúa activa. Puedes volver a tu panel y retomar el seguimiento '
          'desde el banner "Herramienta en renta" en cualquier momento.',
          style: GoogleFonts.inter(fontSize: 13, color: context.textSecondary, height: 1.5),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Seguir aquí'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              Navigator.of(ctx).pushReplacementNamed('/propietario');
            },
            icon: const Icon(Icons.dashboard_outlined, size: 16),
            label: const Text('Ir a mi Panel'),
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

    _maybeNotifyOwnerTransitions(rental);

    int phaseIndex = 0;
    if (rental.isActive) phaseIndex = 1;
    if (rental.isCompleted) phaseIndex = 2;
    if (rental.isDisputed) phaseIndex = 3;
    if (rental.isCancelled) phaseIndex = 4;

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
              Navigator.of(context).pushReplacementNamed('/propietario');
            } else {
              _showBackConfirmation(context);
            }
          },
        ),
        title: Text(
          'Panel del Propietario',
          style: GoogleFonts.montserrat(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
        ),
        actions: [
          ChatIconWithBadge(
            hasUnread: _hasUnreadChat,
            color: AppColors.orange500,
            tooltip: 'Chat con solicitante',
            onPressed: () => _openChat(rental),
          ),
          if (!rental.isCompleted && !rental.isCancelled && !rental.isDisputed)
            TextButton.icon(
              onPressed: () => _showBackConfirmation(context),
              icon: const Icon(Icons.dashboard_outlined, size: 18),
              label: const Text('Mi Panel'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF4F46E5),
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
                      rental.ownerConfirmedReturn
                          ? 'Ya confirmaste la devolución. Esperando al solicitante...'
                          : (rental.requesterConfirmedReturn
                              ? 'El solicitante solicita confirmación de devolución:'
                              : 'Esperando que el solicitante inicie el retorno físico...'),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: context.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    if (rental.ownerConfirmedReturn)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    else
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
                                    label: const Text(
                                      'Disputa',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
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
                                      label: const Text(
                                        'Aceptar Retorno',
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
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
          onCancel:
              rental.canCancel ? () => _cancelRental(rental.id) : null,
        );
      case 1:
        return _OwnerPhase1(rental: rental);
      case 2:
        return _OwnerPhase2Accepted(rental: rental);
      case 4:
        return _OwnerCancelled(rental: rental);
      case 3:
      default:
        return _OwnerPhase2Rejected(rental: rental);
    }
  }
}

class _OwnerCancelled extends StatelessWidget {
  final RentalEntity rental;
  const _OwnerCancelled({required this.rental});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (rental.disputeResolvedByAdmin)
            DisputeResultCard(rental: rental, isOwner: true),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF94A3B8).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cancel_outlined,
                size: 50, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 24),
          Text(
            rental.disputeResolvedByAdmin
                ? 'Disputa resuelta'
                : 'Renta cancelada',
            style: GoogleFonts.montserrat(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: context.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            rental.disputeResolvedByAdmin
                ? 'El administrador ya emitió su dictamen sobre esta renta.'
                : 'Esta renta fue cancelada. La herramienta volvió a quedar disponible.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: context.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          PrimaryGradientButton(
            label: 'Volver al Panel',
            onPressed: () =>
                Navigator.of(context).pushReplacementNamed('/propietario'),
          ),
        ],
      ),
    );
  }
}

class _OwnerPhase0 extends StatelessWidget {
  final bool loading;
  final RentalEntity rental;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const _OwnerPhase0({
    required this.loading,
    required this.rental,
    required this.onConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
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
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Reúnete con el solicitante en el lugar acordado. Al entregar la herramienta física, presiona Confirmar Entrega.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: context.textSecondary,
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
              border: Border.all(color: context.borderColor),
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
                    style: GoogleFonts.inter(fontSize: 12, color: context.textPrimary, fontWeight: FontWeight.w600),
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
                    style: GoogleFonts.inter(fontSize: 12, color: context.textPrimary, fontWeight: FontWeight.w600),
                  ),
                ),
              ]),
            ]),
          ),
          const SizedBox(height: 24),
          loading
              ? const CircularProgressIndicator()
              : PrimaryGradientButton(
                  label: rental.ownerConfirmedDelivery ? 'Esperando Solicitante...' : 'Confirmar Entrega',
                  icon: Icons.check_outlined,
                  height: 52,
                  onPressed: rental.ownerConfirmedDelivery ? null : onConfirm,
                ),
          if (onCancel != null && rental.canCancel && !loading) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.close_rounded,
                  size: 18, color: AppColors.danger),
              label: Text(
                'Cancelar renta',
                style: GoogleFonts.inter(
                    color: AppColors.danger, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OwnerPhase1 extends StatelessWidget {
  final RentalEntity rental;
  const _OwnerPhase1({required this.rental});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ReturnDueBanner(rental: rental),
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
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'El solicitante posee la herramienta física. Los fondos están garantizados e inmutables bajo contrato digital.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: context.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (rental.contractHash.isNotEmpty)
            ContractVerificationWidget(
              rental: rental,
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _OwnerPhase2Accepted extends StatelessWidget {
  final RentalEntity rental;
  const _OwnerPhase2Accepted({required this.rental});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (rental.disputeResolvedByAdmin)
            DisputeResultCard(rental: rental, isOwner: true),
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
            'Has confirmado la devolución física. Los fondos de la renta se han transferido a tu saldo.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: context.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          PrimaryGradientButton(
            label: 'Volver a mi Panel',
            onPressed: () => Navigator.of(context).pushReplacementNamed('/propietario'),
          ),
        ],
      ),
    );
  }
}

class _OwnerPhase2Rejected extends StatelessWidget {
  final RentalEntity rental;
  const _OwnerPhase2Rejected({required this.rental});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
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
            'Se ha abierto un reporte de disputa sobre este contrato. El soporte de ToolShare evaluará la situación.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: context.textSecondary,
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
                    Text(rental.disputeReason, style: GoogleFonts.inter(fontSize: 13, color: context.textPrimary)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          PrimaryGradientButton(
            label: 'Volver a mi Panel',
            onPressed: () => Navigator.of(context).pushReplacementNamed('/propietario'),
          ),
        ],
      ),
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
                    : context.borderColor,
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
              steps[idx],
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
