class SupportThreadEntity {
  final String ownerId;
  final String ownerName;
  final String lastMessage;
  final String lastMessageAt;

  const SupportThreadEntity({
    required this.ownerId,
    required this.ownerName,
    required this.lastMessage,
    required this.lastMessageAt,
  });

  factory SupportThreadEntity.fromJson(Map<String, dynamic> json) {
    return SupportThreadEntity(
      ownerId: json['owner_id'] as String? ?? '',
      ownerName: json['owner_name'] as String? ?? '',
      lastMessage: json['last_message'] as String? ?? '',
      lastMessageAt: json['last_message_at'] as String? ?? '',
    );
  }
}
