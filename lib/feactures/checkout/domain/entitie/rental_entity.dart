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
}
