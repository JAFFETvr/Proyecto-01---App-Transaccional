class SupportMessageEntity {
  final String id;
  final String ownerId;
  final String senderId;
  final String message;
  final String createdAt;

  const SupportMessageEntity({
    required this.id,
    required this.ownerId,
    required this.senderId,
    required this.message,
    required this.createdAt,
  });

  factory SupportMessageEntity.fromJson(Map<String, dynamic> json) {
    return SupportMessageEntity(
      id: json['id'] as String? ?? '',
      ownerId: json['owner_id'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? '',
      message: json['message'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}
