
class ToolEntity {
  final String id;
  final String ownerId;
  final String name;
  final String description;
  final String category;
  final bool isAvailable;
  final String createdAt;
  final String updatedAt;

  const ToolEntity({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.category,
    required this.isAvailable,
    required this.createdAt,
    required this.updatedAt,
  });
}