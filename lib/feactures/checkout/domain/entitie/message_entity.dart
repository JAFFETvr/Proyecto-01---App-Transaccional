class MessageEntity {
  final String id;
  final String rentalId;
  final String senderId;
  final String message;
  final String createdAt;

  const MessageEntity({
    required this.id,
    required this.rentalId,
    required this.senderId,
    required this.message,
    required this.createdAt,
  });

  factory MessageEntity.fromJson(Map<String, dynamic> json) {
    return MessageEntity(
      id: json['id'] as String? ?? '',
      rentalId: json['rental_id'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? '',
      message: json['message'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}
