// Misma entidad que en login — puedes importarla desde login
// o tenerla aquí si prefieres que cada feature sea 100% independiente.
class UserEntity {
  final String id;
  final String name;
  final String email;
  final String role;
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