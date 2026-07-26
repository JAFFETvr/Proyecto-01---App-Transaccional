import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/theme_extensions.dart';
import '../../../auth/login/presentation/providers/login_provider.dart';
import '../../../propietario/presentation/providers/tool_provider.dart';
import '../../../solicitante/presentation/providers/catalog_provider.dart';
import '../../domain/entitie/rental_entity.dart';
import '../providers/rental_provider.dart';
import 'rental_tracking_owner_screen.dart';
import 'rental_tracking_requester_screen.dart';

class MyRentalsScreen extends StatefulWidget {
  const MyRentalsScreen({super.key});

  @override
  State<MyRentalsScreen> createState() => _MyRentalsScreenState();
}

class _MyRentalsScreenState extends State<MyRentalsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RentalProvider>().fetchRentals();
    });
  }

  @override
  Widget build(BuildContext context) {
    final rentalProvider = context.watch<RentalProvider>();
    final rentals = rentalProvider.rentals;

    final sortedRentals = List<RentalEntity>.from(rentals)
      ..sort((a, b) {
        final aOngoing = !a.isCompleted && !a.isCancelled;
        final bOngoing = !b.isCompleted && !b.isCancelled;
        if (aOngoing && !bOngoing) return -1;
        if (!aOngoing && bOngoing) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: context.textPrimary),
        title: Text(
          'Mis Rentas',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: context.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: context.borderColor),
        ),
      ),
      body: rentalProvider.loading && rentals.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : rentals.isEmpty
              ? _buildEmptyState(context)
              : RefreshIndicator(
                  onRefresh: () => rentalProvider.fetchRentals(),
                  color: AppColors.orange500,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: sortedRentals.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (ctx, i) => _RentalCard(
                      rental: sortedRentals[i],
                      onTap: () => _onTapRental(ctx, sortedRentals[i]),
                    ),
                  ),
                ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.orange500.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.handyman_outlined,
                  size: 40, color: AppColors.orange500),
            ),
            const SizedBox(height: 20),
            Text(
              'No tienes rentas registradas',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cuando rentes o te renten una herramienta, aparecerá aquí su seguimiento.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: context.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _onTapRental(BuildContext context, RentalEntity rental) {
    final rentalProvider = context.read<RentalProvider>();
    rentalProvider.setCurrentRental(rental);

    final user = context.read<LoginProvider>().user;
    final isOwner = user?.isOwner ?? false;

    if (isOwner) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const RentalTrackingOwnerScreen(),
          settings: RouteSettings(arguments: rental),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const RentalTrackingRequesterScreen(),
          settings: RouteSettings(arguments: rental),
        ),
      );
    }
  }
}

class _RentalCard extends StatelessWidget {
  final RentalEntity rental;
  final VoidCallback onTap;

  const _RentalCard({required this.rental, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final catalogTools = context.watch<CatalogProvider>().allTools;
    final ownerTools = context.watch<ToolProvider>().tools;

    String toolName = 'Herramienta #${rental.id.substring(0, 4)}';
    String photoUrl = '';

    for (final t in catalogTools) {
      if (t.id == rental.toolId) {
        toolName = t.name;
        photoUrl = t.photoUrl;
        break;
      }
    }
    if (photoUrl.isEmpty && toolName.startsWith('Herramienta #')) {
      for (final t in ownerTools) {
        if (t.id == rental.toolId) {
          toolName = t.name;
          photoUrl = t.photoUrl;
          break;
        }
      }
    }

    final statusText = _getStatusText(rental);
    final statusColor = _getStatusColor(rental);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: context.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: context.colors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: photoUrl.isNotEmpty
                      ? Image.network(photoUrl, fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Icon(
                              Icons.construction,
                              color: context.textSecondary))
                      : Icon(Icons.construction,
                          color: context.textSecondary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        toolName,
                        style: GoogleFonts.montserrat(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${rental.startDate} → ${rental.endDate}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 16, color: context.colors.outline),
              ],
            ),
            const SizedBox(height: 14),
            if (rental.returnDueSoon || rental.returnOverdue) ...[
              _ReturnReminderBanner(rental: rental),
              const SizedBox(height: 12),
            ],
            Divider(height: 1, color: context.borderColor),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusText,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '\$${rental.totalAmount.toStringAsFixed(2)} MXN',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(RentalEntity rental) {
    if (rental.isCancelled) return '❌ Cancelada';
    if (rental.isCompleted) {
      return rental.disputeResolvedByAdmin
          ? '⚖️ Disputa resuelta'
          : '✅ Completada';
    }
    if (rental.isDisputed) return '⚠️ En disputa';

    if (rental.isPending) {
      // Tarjeta sin pago confirmado: la renta existe pero nadie ha pagado,
      // así que NO se debe ver como "Fondos retenidos".
      if (rental.isAwaitingCardPayment) return '💳 Pago pendiente';
      // Efectivo: no hay fondos retenidos en la plataforma.
      if (rental.isCash &&
          !rental.requesterConfirmedDelivery &&
          !rental.ownerConfirmedDelivery) {
        return '🔖 Reservada (efectivo)';
      }
      if (!rental.requesterConfirmedDelivery && !rental.ownerConfirmedDelivery) {
        return '🔒 Fondos retenidos';
      }
      if (rental.requesterConfirmedDelivery && !rental.ownerConfirmedDelivery) {
        return '⏳ Esperando al propietario';
      }
      if (!rental.requesterConfirmedDelivery && rental.ownerConfirmedDelivery) {
        return '📦 Propietario entregó — Confirma';
      }
      return '⏳ Pendiente de entrega';
    }
    if (rental.isActive) {
      if (rental.returnOverdue) return '⏰ Devolución vencida';
      if (rental.returnDueSoon) return '⏰ Devuelve pronto (${rental.timeLeftLabel})';
      return '🟢 Renta en curso';
    }
    return rental.status;
  }

  Color _getStatusColor(RentalEntity rental) {
    if (rental.isCancelled) return const Color(0xFF94A3B8);
    if (rental.isCompleted) return const Color(0xFF64748B);
    if (rental.isDisputed) return const Color(0xFFEF4444);
    if (rental.isPending) {
      if (rental.isAwaitingCardPayment) return const Color(0xFF64748B);
      if (rental.isCash &&
          !rental.requesterConfirmedDelivery &&
          !rental.ownerConfirmedDelivery) {
        return const Color(0xFF2563EB);
      }
      return const Color(0xFFD97706);
    }
    if (rental.isActive) {
      if (rental.returnOverdue) return const Color(0xFFEF4444);
      if (rental.returnDueSoon) return const Color(0xFFF59E0B);
      return const Color(0xFF10B981);
    }
    return const Color(0xFF64748B);
  }
}

/// Aviso visible cuando faltan 12 h o menos para la fecha de devolución (o ya
/// se venció). Como no hay push, esta es la forma de "avisar" que hay que
/// devolver la herramienta: se hace visible en la sección de rentas.
class _ReturnReminderBanner extends StatelessWidget {
  final RentalEntity rental;
  const _ReturnReminderBanner({required this.rental});

  @override
  Widget build(BuildContext context) {
    final overdue = rental.returnOverdue;
    final color = overdue ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);
    final text = overdue
        ? 'La fecha de devolución ya venció. Coordina la entrega cuanto antes.'
        : 'Quedan ${rental.timeLeftLabel} para devolver la herramienta.';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(overdue ? Icons.warning_amber_rounded : Icons.alarm_rounded,
              size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: color,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
