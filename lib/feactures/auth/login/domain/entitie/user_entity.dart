// Entidad pura — no depende de JSON ni de Flutter.
class UserEntity {
  final String id;
  final String name;
  final String email;
  final String role; // 'owner' | 'requester'
  final String token;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.token,
  });

  bool get isOwner => role == 'owner';
}