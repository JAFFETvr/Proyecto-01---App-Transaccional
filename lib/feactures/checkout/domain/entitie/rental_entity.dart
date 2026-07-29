class RentalEntity {
  final String id;
  final String toolId;
  final String requesterId;
  final String ownerId;
  final String ownerName;
  final String requesterName;
  final String startDate;
  final String endDate;
  final double dailyRate;
  final double totalAmount;
  final String status;
  final String paymentMethod;

  final String mpPaymentId;
  final String paymentStatus;
  final double deductibleAmount;
  final double commissionAmount;

  final bool ownerConfirmedDelivery;
  final bool requesterConfirmedDelivery;

  final String contractHash;
  final double deliveryLat;
  final double deliveryLng;
  final String deliveryAt;

  final bool requesterConfirmedReturn;
  final bool ownerConfirmedReturn;

  final String disputeReason;

  final String createdAt;
  final String updatedAt;

  const RentalEntity({
    required this.id,
    required this.toolId,
    required this.requesterId,
    required this.ownerId,
    this.ownerName = '',
    this.requesterName = '',
    required this.startDate,
    required this.endDate,
    required this.dailyRate,
    required this.totalAmount,
    required this.status,
    this.paymentMethod = 'card',
    this.mpPaymentId = '',
    this.paymentStatus = '',
    this.deductibleAmount = 0.0,
    this.commissionAmount = 0.0,
    required this.ownerConfirmedDelivery,
    required this.requesterConfirmedDelivery,
    this.contractHash = '',
    this.deliveryLat = 0.0,
    this.deliveryLng = 0.0,
    this.deliveryAt = '',
    required this.requesterConfirmedReturn,
    required this.ownerConfirmedReturn,
    this.disputeReason = '',
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isDisputed => status == 'disputed';
  bool get isCancelled => status == 'cancelled';
  bool get isPending => status == 'pending';

  bool get isCash => paymentMethod == 'cash';
  bool get isCard => paymentMethod == 'card';

  // En tarjeta, fondos retenidos solo si MP ya confirmó el pago; en efectivo nunca.
  bool get isPaidCard {
    if (!isCard) return false;
    const paidStates = {
      'authorized',
      'approved',
      'accredited',
      'captured',
      'captured_admin',
    };
    return paidStates.contains(paymentStatus);
  }

  // Tarjeta creada pero aún sin pago confirmado por Mercado Pago.
  bool get isAwaitingCardPayment => isCard && !isPaidCard;

  DateTime? get endDateTime => DateTime.tryParse(endDate)?.toLocal();

  Duration? get timeUntilReturn {
    final end = endDateTime;
    if (end == null) return null;
    return end.difference(DateTime.now());
  }

  // Falta 12 h o menos para la fecha de devolución (y la renta sigue en curso).
  bool get returnDueSoon {
    if (!isActive) return false;
    final left = timeUntilReturn;
    if (left == null) return false;
    return left <= const Duration(hours: 12) && left > Duration.zero;
  }

  bool get returnOverdue {
    if (!isActive) return false;
    final left = timeUntilReturn;
    if (left == null) return false;
    return left <= Duration.zero;
  }

  // Texto tipo "8 h" / "40 min" con lo que falta para devolver.
  String get timeLeftLabel {
    final left = timeUntilReturn;
    if (left == null) return '';
    if (left <= Duration.zero) return 'vencida';
    if (left.inHours >= 1) return '${left.inHours} h';
    return '${left.inMinutes} min';
  }

  // La renta aún no arranca formalmente y puede cancelarse por cualquiera de
  // las dos partes: ninguno confirmó la entrega todavía.
  bool get canCancel =>
      isPending && !ownerConfirmedDelivery && !requesterConfirmedDelivery;

  // El admin ya dictaminó la disputa; su fallo queda anexado al motivo con el
  // prefijo "[Dictamen Admin - <acción>]".
  bool get disputeResolvedByAdmin => disputeReason.contains('[Dictamen Admin');

  // 'capture' = gana el propietario, 'refund' = gana el solicitante.
  String? get disputeAdminAction {
    if (!disputeResolvedByAdmin) return null;
    if (disputeReason.contains('- capture]')) return 'capture';
    if (disputeReason.contains('- refund]')) return 'refund';
    return null;
  }

  // Solo el dictamen/notas del admin, sin el motivo original ni el prefijo.
  String get disputeAdminNotes {
    if (!disputeResolvedByAdmin) return '';
    final start = disputeReason.indexOf(']:');
    if (start == -1) return '';
    var notes = disputeReason.substring(start + 2);
    final motivoIdx = notes.indexOf('(Motivo:');
    if (motivoIdx != -1) notes = notes.substring(0, motivoIdx);
    return notes.trim();
  }
}
