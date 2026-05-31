class Tool {
  final String id;
  final String name;
  final String description;
  final String category;
  final bool isAvailable;

  Tool({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.isAvailable,
  });

  factory Tool.fromJson(Map<String, dynamic> json) {
    return Tool(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      isAvailable: json['is_available'] ?? true,
    );
  }
}