class RentalEntity {
  final String id;
  final String toolId;
  final String requesterId;
  final String ownerId;
  final String startDate;
  final String endDate;
  final double dailyRate;
  final double totalAmount;
  final String status; // 'pending' | 'active' | 'completed' | 'cancelled' | 'disputed'

  // Payment
  final String mpPaymentId;
  final String paymentStatus;
  final double deductibleAmount;

  // Handshake: Delivery
  final bool ownerConfirmedDelivery;
  final bool requesterConfirmedDelivery;

  // Digital contract
  final String contractHash;
  final double deliveryLat;
  final double deliveryLng;
  final String deliveryAt;

  // Handshake: Return
  final bool requesterConfirmedReturn;
  final bool ownerConfirmedReturn;

  // Dispute
  final String disputeReason;

  final String createdAt;
  final String updatedAt;

  const RentalEntity({
    required this.id,
    required this.toolId,
    required this.requesterId,
    required this.ownerId,
    required this.startDate,
    required this.endDate,
    required this.dailyRate,
    required this.totalAmount,
    required this.status,
    this.mpPaymentId = '',
    this.paymentStatus = '',
    this.deductibleAmount = 0.0,
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
