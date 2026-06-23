class ToolEntity {
  final String id;
  final String ownerId;
  final String name;
  final String description;
  final String category;
  final String photoUrl;
  final double estimatedValue;
  final double dailyRate;
  final double suggestedMinDailyRate;
  final double latitude;
  final double longitude;
  final bool isAvailable;
  final String createdAt;
  final String updatedAt;

  const ToolEntity({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.category,
    this.photoUrl = '',
    this.estimatedValue = 0.0,
    this.dailyRate = 0.0,
    this.suggestedMinDailyRate = 0.0,
    this.latitude = 0.0,
    this.longitude = 0.0,
    required this.isAvailable,
    required this.createdAt,
    required this.updatedAt,
  });
}